#!/bin/bash
# Real git integration test for scripts/gh-msync using local bare remotes only.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/lib/testlib.sh
source "$SCRIPT_DIR/lib/testlib.sh"

TMP_ROOT="$(make_temp_root)"
cleanup() {
    cleanup_temp_root "$TMP_ROOT"
}
trap cleanup EXIT

BASE_PATH="$PATH"

make_remote_with_seed_and_clone() {
    local name="$1"
    local remotes_dir="$2"
    local work_dir="$3"
    local clone_dir="$4"
    local remote_path seed_path

    remote_path="$remotes_dir/$name.git"
    seed_path="$work_dir/$name-seed"

    git init --bare "$remote_path" >/dev/null 2>&1
    git init "$seed_path" >/dev/null 2>&1
    git_init_identity "$seed_path"
    git -C "$seed_path" branch -m main >/dev/null
    git -C "$seed_path" remote add origin "$remote_path"
    git_commit_file "$seed_path" README.md "# $name" "init"
    git -C "$seed_path" push -u origin main >/dev/null 2>&1
    git -C "$remote_path" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1 || true

    git clone --branch main "$remote_path" "$clone_dir/$name" >/dev/null 2>&1
    git_init_identity "$clone_dir/$name"
}

remotes_dir="$TMP_ROOT/remotes"
work_dir="$TMP_ROOT/work"
base_dir="$TMP_ROOT/repos"
stub_dir="$TMP_ROOT/stubs"
out="$TMP_ROOT/output.txt"

mkdir -p "$remotes_dir" "$work_dir" "$base_dir" "$stub_dir"

make_remote_with_seed_and_clone "alpha-up-to-date" "$remotes_dir" "$work_dir" "$base_dir"
make_remote_with_seed_and_clone "beta-behind" "$remotes_dir" "$work_dir" "$base_dir"
make_remote_with_seed_and_clone "gamma-modified" "$remotes_dir" "$work_dir" "$base_dir"

# Make beta-behind one commit behind remote.
git_commit_file "$work_dir/beta-behind-seed" updates.txt "new change" "remote update"
git -C "$work_dir/beta-behind-seed" push >/dev/null 2>&1

# Create local uncommitted changes for gamma-modified.
printf 'local edits\n' >> "$base_dir/gamma-modified/README.md"

# Prevent missing-repository interactive prompts by simulating unauthenticated gh.
cat > "$stub_dir/gh" <<'EOF_GH'
#!/bin/bash
set -euo pipefail
if [ "${1:-}" = "auth" ] && [ "${2:-}" = "status" ]; then
    exit 1
fi
exit 1
EOF_GH
chmod +x "$stub_dir/gh"

set +e
HOME="$TMP_ROOT/home" \
PATH="$stub_dir:$BASE_PATH" \
GH_MSYNC_DISABLE_INTEGRATIONS_AUTOSETUP=1 \
scripts/gh-msync --headless "$base_dir" >"$out" 2>&1
status=$?
set -e

assert_status "$status" 0
assert_file_contains "$out" "alpha-up-to-date"
assert_file_contains "$out" "up to date"
assert_file_contains "$out" "beta-behind"
assert_file_contains "$out" "pulled 1 commit affecting 1 file"
assert_file_contains "$out" "gamma-modified"
assert_file_contains "$out" "modified files, sync skipped"
assert_file_contains "$out" "Repository sync complete"
pass "real git integration covers up-to-date, pull, and modified-skip paths"

# Verify beta clone actually received the remote commit.
beta_head="$(git -C "$base_dir/beta-behind" rev-parse HEAD)"
beta_remote_head="$(git -C "$work_dir/beta-behind-seed" rev-parse HEAD)"
assert_eq "$beta_head" "$beta_remote_head" "beta-behind should match remote after sync"
pass "real git sync leaves pulled repo at expected HEAD"

printf 'REAL GIT TESTS COMPLETE (%s)\n' "$TMP_ROOT"
