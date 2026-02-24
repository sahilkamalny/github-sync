#!/bin/bash
# Non-destructive smoke tests for launcher integration creation/removal and fallback order.
# Uses a temporary HOME plus stubbed tools so it does not touch real user state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_PATH="$PATH"
KEEP_TEMP="${GH_MSYNC_SMOKE_KEEP_TEMP:-0}"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gh-msync-smoke.XXXXXX")"
OS="$(uname -s)"

cleanup() {
    if [ "$KEEP_TEMP" = "1" ]; then
        printf 'Keeping temp root: %s\n' "$TMP_ROOT"
        return 0
    fi
    /bin/rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

pass() {
    printf 'PASS %s\n' "$1"
}

skip() {
    printf 'SKIP %s\n' "$1"
}

fail() {
    printf 'FAIL %s\n' "$1" >&2
    exit 1
}

assert_exists() {
    local path="$1"
    [ -e "$path" ] || fail "missing: $path"
}

assert_contains() {
    local file="$1"
    local text="$2"
    grep -Fq "$text" "$file" || fail "expected '$text' in $file"
}

assert_not_contains() {
    local file="$1"
    local text="$2"
    if grep -Fq "$text" "$file"; then
        fail "did not expect '$text' in $file"
    fi
}

assert_line_order() {
    local file="$1"
    local first="$2"
    local second="$3"
    local first_line second_line

    first_line="$(grep -nF "$first" "$file" | head -n1 | cut -d: -f1 || true)"
    second_line="$(grep -nF "$second" "$file" | head -n1 | cut -d: -f1 || true)"

    [ -n "$first_line" ] || fail "missing '$first' in $file"
    [ -n "$second_line" ] || fail "missing '$second' in $file"
    [ "$first_line" -lt "$second_line" ] || fail "expected '$first' before '$second' in $file"
}

make_osacompile_stub() {
    local dir="$1"
    cat >"$dir/osacompile" <<'EOS'
#!/bin/bash
out=""
if [ -n "${GH_MSYNC_OSACOMPILE_STUB_LOG:-}" ]; then
    for arg in "$@"; do
        printf '%s\n' "$arg" >> "$GH_MSYNC_OSACOMPILE_STUB_LOG"
    done
fi
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

# Scenario 1: core command installs integrations into temp HOME.
HOME1="$TMP_ROOT/home1"
STUB1="$TMP_ROOT/stub1"
OSACOMPILE_LOG1="$TMP_ROOT/osacompile-args.log"
mkdir -p "$HOME1" "$STUB1"
: >"$OSACOMPILE_LOG1"
make_osacompile_stub "$STUB1"
HOME="$HOME1" PATH="$STUB1:$BASE_PATH" GH_MSYNC_OSACOMPILE_STUB_LOG="$OSACOMPILE_LOG1" "$REPO_DIR/scripts/gh-msync" --install-integrations >/dev/null 2>&1 || fail "core --install-integrations failed"
assert_exists "$HOME1/.config/gh-msync/integrations/launch.sh"
assert_contains "$HOME1/.config/gh-msync/integrations/launch.sh" "$REPO_DIR/scripts/gh-msync"
if [ "$OS" = "Darwin" ]; then
    assert_exists "$HOME1/Applications/GitHub Multi-Sync.app/Contents/Resources/run.sh"
    assert_contains "$OSACOMPILE_LOG1" 'do script "bash \"'
    assert_not_contains "$OSACOMPILE_LOG1" 'do script "exec bash'
    # shellcheck disable=SC2016 # Intentional literal pattern match against generated wrapper content.
    assert_contains \
        "$HOME1/Applications/GitHub Multi-Sync.app/Contents/Resources/run.sh" \
        'osascript -e "tell application \\"Terminal\\" to close (every window whose id is $WIN_ID) saving no"'
    assert_contains \
        "$HOME1/Applications/GitHub Multi-Sync.app/Contents/Resources/run.sh" \
        'sleep 0.1'
    assert_not_contains \
        "$HOME1/Applications/GitHub Multi-Sync.app/Contents/Resources/run.sh" \
        'nohup bash -c "sleep 0.1; osascript -e'
    # shellcheck disable=SC2016 # Intentional literal pattern match against generated wrapper content.
    assert_line_order \
        "$HOME1/Applications/GitHub Multi-Sync.app/Contents/Resources/run.sh" \
        'read -r -p "Press [Enter] to exit..."' \
        'WIN_ID="$(osascript -e '\''tell application "Terminal" to get id of front window'\'' 2>/dev/null || true)"'
elif [ "$OS" = "Linux" ]; then
    assert_exists "$HOME1/.local/share/applications/gh-msync.desktop"
else
    skip "OS-specific desktop artifact assertion skipped on $OS"
fi
pass "core --install-integrations creates shared launcher artifacts in temp HOME"

# Scenario 2: launcher fallback order (preferred -> gh-msync -> gh msync).
HOME2="$TMP_ROOT/home2"
STUB2="$TMP_ROOT/stub2"
LOG2="$TMP_ROOT/order.log"
mkdir -p "$HOME2" "$STUB2"
: >"$LOG2"
make_osacompile_stub "$STUB2"
cat >"$STUB2/preferred" <<EOS
#!/bin/bash
echo preferred:\"\$*\" >> "$LOG2"
exit 127
EOS
cat >"$STUB2/gh-msync" <<EOS
#!/bin/bash
echo gh-msync:\"\$*\" >> "$LOG2"
exit 127
EOS
cat >"$STUB2/gh" <<EOS
#!/bin/bash
echo gh:\"\$*\" >> "$LOG2"
[ "\${1:-}" = "msync" ] && exit 0
exit 2
EOS
chmod +x "$STUB2/preferred" "$STUB2/gh-msync" "$STUB2/gh"
HOME="$HOME2" PATH="$STUB2:$BASE_PATH" "$REPO_DIR/scripts/system-integrations.sh" install --quiet --preferred-script "$STUB2/preferred" >/dev/null 2>&1 || fail "helper install for fallback-order test failed"
HOME="$HOME2" PATH="$STUB2:$BASE_PATH" "$HOME2/.config/gh-msync/integrations/launch.sh" --help >/dev/null 2>&1 || fail "generated launcher fallback-order test failed"
expected_order=$'preferred:"--help"\ngh-msync:"--help"\ngh:"msync --help"'
actual_order="$(cat "$LOG2")"
[ "$actual_order" = "$expected_order" ] || {
    printf 'Expected order:\n%s\nActual order:\n%s\n' "$expected_order" "$actual_order" >&2
    fail "launcher fallback order mismatch"
}
pass "launcher fallback order is preferred -> gh-msync -> gh msync"

# Scenario 3: launcher stops when preferred target succeeds.
HOME3="$TMP_ROOT/home3"
STUB3="$TMP_ROOT/stub3"
LOG3="$TMP_ROOT/preferred-success.log"
mkdir -p "$HOME3" "$STUB3"
: >"$LOG3"
make_osacompile_stub "$STUB3"
cat >"$STUB3/preferred" <<EOS
#!/bin/bash
echo preferred-ok:\"\$*\" >> "$LOG3"
exit 0
EOS
cat >"$STUB3/gh-msync" <<EOS
#!/bin/bash
echo gh-msync-should-not-run >> "$LOG3"
exit 0
EOS
cat >"$STUB3/gh" <<EOS
#!/bin/bash
echo gh-should-not-run >> "$LOG3"
exit 0
EOS
chmod +x "$STUB3/preferred" "$STUB3/gh-msync" "$STUB3/gh"
HOME="$HOME3" PATH="$STUB3:$BASE_PATH" "$REPO_DIR/scripts/system-integrations.sh" install --quiet --preferred-script "$STUB3/preferred" >/dev/null 2>&1 || fail "helper install for preferred-success test failed"
HOME="$HOME3" PATH="$STUB3:$BASE_PATH" "$HOME3/.config/gh-msync/integrations/launch.sh" foo >/dev/null 2>&1 || fail "generated launcher preferred-success test failed"
actual3="$(cat "$LOG3")"
[ "$actual3" = 'preferred-ok:"foo"' ] || {
    printf 'Unexpected preferred-success log:\n%s\n' "$actual3" >&2
    fail "launcher did not short-circuit on preferred success"
}
pass "launcher short-circuits when preferred target succeeds"

# Scenario 4: launcher preserves real gh-msync runtime errors (does not mask by falling back).
HOME4="$TMP_ROOT/home4"
STUB4="$TMP_ROOT/stub4"
LOG4="$TMP_ROOT/runtime-error.log"
mkdir -p "$HOME4" "$STUB4"
: >"$LOG4"
make_osacompile_stub "$STUB4"
cat >"$STUB4/gh-msync" <<EOS
#!/bin/bash
echo gh-msync-runtime:\"\$*\" >> "$LOG4"
exit 42
EOS
cat >"$STUB4/gh" <<EOS
#!/bin/bash
echo gh-should-not-run >> "$LOG4"
exit 0
EOS
chmod +x "$STUB4/gh-msync" "$STUB4/gh"
HOME="$HOME4" PATH="$STUB4:$BASE_PATH" "$REPO_DIR/scripts/system-integrations.sh" install --quiet >/dev/null 2>&1 || fail "helper install for runtime-error test failed"
set +e
HOME="$HOME4" PATH="$STUB4:$BASE_PATH" "$HOME4/.config/gh-msync/integrations/launch.sh" bar >/dev/null 2>&1
status4=$?
set -e
[ "$status4" -eq 42 ] || fail "launcher masked runtime error (expected 42, got $status4)"
actual4="$(cat "$LOG4")"
[ "$actual4" = 'gh-msync-runtime:"bar"' ] || {
    printf 'Unexpected runtime-error log:\n%s\n' "$actual4" >&2
    fail "launcher fallback ran when it should have preserved gh-msync runtime failure"
}
pass "launcher preserves real gh-msync runtime errors"

# Scenario 5: dry-run-style uninstall command (rm stub logs targets; no real deletes).
HOME5="$TMP_ROOT/home5"
STUB5="$TMP_ROOT/stub5"
RMLOG5="$TMP_ROOT/rm.log"
mkdir -p "$HOME5" "$STUB5"
: >"$RMLOG5"
make_osacompile_stub "$STUB5"
cat >"$STUB5/rm" <<EOS
#!/bin/bash
echo rm:\"\$*\" >> "$RMLOG5"
exit 0
EOS
chmod +x "$STUB5/rm"
HOME="$HOME5" PATH="$STUB5:$BASE_PATH" "$REPO_DIR/scripts/gh-msync" --install-integrations >/dev/null 2>&1 || fail "setup install for uninstall dry-run test failed"
HOME="$HOME5" PATH="$STUB5:$BASE_PATH" "$REPO_DIR/scripts/gh-msync" --uninstall-integrations >/dev/null 2>&1 || fail "core --uninstall-integrations failed"
assert_contains "$RMLOG5" "$HOME5/.config/gh-msync/integrations/launch.sh"
if [ "$OS" = "Darwin" ]; then
    assert_contains "$RMLOG5" "$HOME5/Applications/GitHub Multi-Sync.app"
elif [ "$OS" = "Linux" ]; then
    assert_contains "$RMLOG5" "$HOME5/.local/share/applications/gh-msync.desktop"
else
    skip "OS-specific desktop cleanup assertion skipped on $OS"
fi
pass "core --uninstall-integrations invokes expected cleanup targets (dry-run rm stub)"

printf 'SMOKE TESTS COMPLETE (temp root: %s)\n' "$TMP_ROOT"
