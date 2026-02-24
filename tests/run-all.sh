#!/bin/bash
# Run the local quality checks and non-destructive test suite.

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$TESTS_DIR/.." && pwd)"

REQUIRE_SHELLCHECK=0
PROFILE="full"

while [ $# -gt 0 ]; do
    case "$1" in
        --require-shellcheck)
            REQUIRE_SHELLCHECK=1
            ;;
        --profile)
            shift
            [ $# -gt 0 ] || {
                echo "Missing value for --profile" >&2
                echo "Usage: tests/run-all.sh [--profile full|ci-posix|windows-git-bash|linux-compat] [--require-shellcheck]" >&2
                exit 2
            }
            PROFILE="$1"
            ;;
        --list-profiles)
            printf '%s\n' "full" "ci-posix" "windows-git-bash" "linux-compat"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: tests/run-all.sh [--profile full|ci-posix|windows-git-bash|linux-compat] [--require-shellcheck]" >&2
            exit 2
            ;;
    esac
    shift
done

export GH_MSYNC_TEST_REQUIRE_SHELLCHECK="$REQUIRE_SHELLCHECK"
export GH_MSYNC_TEST_PROFILE="$PROFILE"

case "$PROFILE" in
    full|ci-posix)
        TEST_SCRIPTS=(
            "$TESTS_DIR/quality-checks.sh"
            "$TESTS_DIR/smoke-integrations.sh"
            "$TESTS_DIR/core-behavior.sh"
            "$TESTS_DIR/real-git-sync.sh"
            "$TESTS_DIR/configure-install-uninstall.sh"
        )
        ;;
    windows-git-bash)
        TEST_SCRIPTS=(
            "$TESTS_DIR/quality-checks.sh"
            "$TESTS_DIR/smoke-integrations.sh"
            "$TESTS_DIR/core-behavior.sh"
            "$TESTS_DIR/real-git-sync.sh"
        )
        ;;
    linux-compat)
        TEST_SCRIPTS=(
            "$TESTS_DIR/smoke-integrations.sh"
            "$TESTS_DIR/core-behavior.sh"
            "$TESTS_DIR/real-git-sync.sh"
            "$TESTS_DIR/configure-install-uninstall.sh"
        )
        ;;
    *)
        echo "Unknown profile: $PROFILE" >&2
        echo "Run 'tests/run-all.sh --list-profiles' to see valid profiles." >&2
        exit 2
        ;;
esac

printf 'Running gh-msync test suite from %s (profile: %s)\n\n' "$REPO_DIR" "$PROFILE"

for test_script in "${TEST_SCRIPTS[@]}"; do
    printf '==> %s\n' "$(basename "$test_script")"
    "$test_script"
    printf '\n'
done

printf 'ALL TESTS PASSED\n'
