#!/bin/bash
# Repository quality checks: syntax, linting, wrapper smoke, and basic hygiene.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/lib/testlib.sh
source "$SCRIPT_DIR/lib/testlib.sh"

TMP_ROOT="$(make_temp_root)"
cleanup() {
    cleanup_temp_root "$TMP_ROOT"
}
trap cleanup EXIT

cd "$REPO_DIR"

shell_files=()
while IFS= read -r file; do
    case "$file" in
        *.sh|*.command|gh-msync|scripts/gh-msync)
            shell_files+=("$file")
            ;;
    esac
done < <(git ls-files)

[ "${#shell_files[@]}" -gt 0 ] || fail "no shell files discovered via git ls-files"

bash -n "${shell_files[@]}"
pass "bash -n passes for tracked shell scripts"

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${shell_files[@]}"
    pass "shellcheck passes for tracked shell scripts"
elif [ "${GH_MSYNC_TEST_REQUIRE_SHELLCHECK:-0}" = "1" ]; then
    fail "shellcheck is required but not installed"
else
    note "SKIP shellcheck (not installed)"
fi

if command -v ruby >/dev/null 2>&1; then
    ruby -c packaging/homebrew/gh-msync.rb >/dev/null
    pass "Homebrew formula Ruby syntax is valid"
else
    note "SKIP Homebrew formula Ruby syntax check (ruby not installed)"
fi

./gh-msync --help > "$TMP_ROOT/gh-extension-help.txt"
assert_file_contains "$TMP_ROOT/gh-extension-help.txt" "Usage: gh-msync"
pass "GitHub CLI extension entrypoint forwards to core script"

scripts/gh-msync --help > "$TMP_ROOT/gh-msync-help.txt"
assert_file_contains "$TMP_ROOT/gh-msync-help.txt" "--install-integrations"
assert_file_contains "$TMP_ROOT/gh-msync-help.txt" "--uninstall-integrations"
pass "core help includes launcher integration flags"

if command -v rg >/dev/null 2>&1; then
    if rg -n "github-sync" -S . -g '!tests/**' > "$TMP_ROOT/stale-paths.txt"; then
        cat "$TMP_ROOT/stale-paths.txt" >&2
        fail "stale github-sync references remain"
    fi
else
    if grep -RIn --exclude-dir=.git --exclude-dir=tests -- "github-sync" . > "$TMP_ROOT/stale-paths.txt"; then
        cat "$TMP_ROOT/stale-paths.txt" >&2
        fail "stale github-sync references remain"
    fi
fi
pass "no stale github-sync repo-name references remain"

if command -v actionlint >/dev/null 2>&1; then
    actionlint
    pass "actionlint passes for GitHub Actions workflows"
else
    note "SKIP actionlint (not installed)"
fi

if is_windows_like; then
    note "SKIP executable-bit checks on Windows Git Bash"
else
    for path in \
        gh-msync \
        macOS-Install.command \
        macOS-Uninstall.command \
        Linux-Install.sh \
        Linux-Uninstall.sh \
        scripts/gh-msync \
        scripts/configure-paths.sh \
        scripts/install.sh \
        scripts/uninstall.sh \
        scripts/system-integrations.sh \
        tests/smoke-integrations.sh \
        tests/run-all.sh \
        tests/quality-checks.sh \
        tests/core-behavior.sh \
        tests/real-git-sync.sh \
        tests/configure-install-uninstall.sh \
        tests/lib/testlib.sh
    do
        [ -x "$path" ] || fail "expected executable bit on $path"
    done
    pass "entrypoints and test scripts are executable"
fi

git diff --check -- . >/dev/null
pass "git diff --check reports no whitespace errors"
