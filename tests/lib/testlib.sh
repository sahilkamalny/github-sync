#!/bin/bash

set -euo pipefail

TEST_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(cd "$TEST_LIB_DIR/.." && pwd)"
# shellcheck disable=SC2034 # Used by test scripts that source this helper.
REPO_DIR="$(cd "$TESTS_DIR/.." && pwd)"

PASS_COUNT=0

note() {
    printf '%s\n' "$*"
}

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'PASS %s\n' "$*"
}

fail() {
    printf 'FAIL %s\n' "$*" >&2
    exit 1
}

assert_exists() {
    local path="$1"
    [ -e "$path" ] || fail "missing: $path"
}

assert_not_exists() {
    local path="$1"
    [ ! -e "$path" ] || fail "unexpected path exists: $path"
}

assert_file_contains() {
    local file="$1"
    local text="$2"
    grep -Fq -- "$text" "$file" || fail "expected '$text' in $file"
}

assert_file_not_contains() {
    local file="$1"
    local text="$2"
    if grep -Fq -- "$text" "$file"; then
        fail "did not expect '$text' in $file"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    case "$haystack" in
        *"$needle"*) ;;
        *) fail "expected output to contain: $needle" ;;
    esac
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    case "$haystack" in
        *"$needle"*) fail "did not expect output to contain: $needle" ;;
        *) ;;
    esac
}

assert_eq() {
    local actual="$1"
    local expected="$2"
    local label="${3:-values differ}"
    [ "$actual" = "$expected" ] || fail "$label (expected '$expected', got '$actual')"
}

assert_status() {
    local actual="$1"
    local expected="$2"
    [ "$actual" -eq "$expected" ] || fail "expected exit $expected, got $actual"
}

make_temp_root() {
    mktemp -d "${TMPDIR:-/tmp}/gh-msync-test.XXXXXX"
}

cleanup_temp_root() {
    local root="$1"
    [ -n "$root" ] || return 0
    [ -d "$root" ] || return 0
    if [ "${GH_MSYNC_TEST_KEEP_TEMP:-0}" = "1" ]; then
        printf 'KEEPING TEMP ROOT: %s\n' "$root"
        return 0
    fi
    /bin/rm -rf "$root"
}

strip_ansi() {
    # Use a literal ESC byte in the regex for BSD/GNU sed portability.
    sed -E $'s/\033\\[[0-9;]*[A-Za-z]//g'
}

make_osacompile_stub() {
    local dir="$1"
    cat > "$dir/osacompile" <<'EOS'
#!/bin/bash
out=""
while [ $# -gt 0 ]; do
    if [ "$1" = "-o" ] && [ $# -ge 2 ]; then
        out="$2"
        shift 2
        continue
    fi
    shift
done
[ -n "$out" ] || exit 2
mkdir -p "$out/Contents/Resources"
exit 0
EOS
    chmod +x "$dir/osacompile"
}

run_and_capture() {
    local output_file="$1"
    shift
    set +e
    "$@" >"$output_file" 2>&1
    local status=$?
    set -e
    return "$status"
}

run_with_tty_and_input() {
    local output_file="$1"
    local input_text="$2"
    shift 2

    if command -v python3 >/dev/null 2>&1; then
        set +e
        python3 - "$output_file" "$input_text" "$@" <<'PY'
import os
import pty
import select
import sys
import time

out_path = sys.argv[1]
input_text = sys.argv[2].encode()
cmd = sys.argv[3:]

pid, fd = pty.fork()
if pid == 0:
    os.execvp(cmd[0], cmd)

buf = bytearray()
sent = False
start = time.time()

while True:
    if not sent and (time.time() - start) >= 0.2:
        try:
            os.write(fd, input_text)
        except OSError:
            pass
        sent = True

    rlist, _, _ = select.select([fd], [], [], 0.05)
    if rlist:
        try:
            chunk = os.read(fd, 4096)
        except OSError:
            break
        if not chunk:
            break
        buf.extend(chunk)
    else:
        done_pid, status = os.waitpid(pid, os.WNOHANG)
        if done_pid == pid:
            with open(out_path, "wb") as fh:
                fh.write(buf)
            if os.WIFEXITED(status):
                sys.exit(os.WEXITSTATUS(status))
            if os.WIFSIGNALED(status):
                sys.exit(128 + os.WTERMSIG(status))
            sys.exit(1)

_, status = os.waitpid(pid, 0)
with open(out_path, "wb") as fh:
    fh.write(buf)
if os.WIFEXITED(status):
    sys.exit(os.WEXITSTATUS(status))
if os.WIFSIGNALED(status):
    sys.exit(128 + os.WTERMSIG(status))
sys.exit(1)
PY
        local status=$?
        set -e
        return "$status"
    fi

    if ! command -v script >/dev/null 2>&1; then
        fail "script command is required for TTY tests"
    fi

    set +e
    if printf '%s' "$input_text" | script -q /dev/null "$@" >"$output_file" 2>&1; then
        local status=0
    else
        local status=$?
        # GNU util-linux script often requires -c instead of BSD-style invocation.
        if [ "$status" -ne 0 ]; then
            printf '%s' "$input_text" | script -q -c "$(printf '%q ' "$@")" /dev/null >"$output_file" 2>&1
            status=$?
        fi
    fi
    set -e
    return "$status"
}

git_init_identity() {
    local repo="$1"
    git -C "$repo" config user.name "gh-msync tests"
    git -C "$repo" config user.email "tests@example.com"
}

git_commit_file() {
    local repo="$1"
    local path="$2"
    local contents="$3"
    local message="$4"
    mkdir -p "$(dirname -- "$repo/$path")"
    printf '%s\n' "$contents" > "$repo/$path"
    git -C "$repo" add "$path"
    git -C "$repo" commit -m "$message" >/dev/null
}
