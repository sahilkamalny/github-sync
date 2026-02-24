#!/bin/bash
# Non-destructive behavior tests for scripts/gh-msync (argument parsing, config,
# sync flow with stubbed git, and missing-repo clone selection behavior).

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

scenario_arg_parsing() {
    local out status

    out="$TMP_ROOT/help.txt"
    scripts/gh-msync --help >"$out"
    assert_file_contains "$out" "Usage: gh-msync"
    assert_file_contains "$out" "--ssh-upgrade"
    pass "help output renders expected core flags"

    out="$TMP_ROOT/unknown.txt"
    set +e
    scripts/gh-msync --definitely-not-a-real-flag >"$out" 2>&1
    status=$?
    set -e
    assert_status "$status" 2
    assert_file_contains "$out" "unknown option"
    pass "unknown option exits 2 with guidance"

    out="$TMP_ROOT/mutually-exclusive.txt"
    set +e
    scripts/gh-msync --install-integrations --uninstall-integrations >"$out" 2>&1
    status=$?
    set -e
    assert_status "$status" 2
    assert_file_contains "$out" "choose only one"
    pass "mutually exclusive integration flags are rejected"
}

scenario_config_and_no_repo_handling() {
    local home_dir base_dir out status

    home_dir="$TMP_ROOT/home-config"
    base_dir="$home_dir/Repos"
    mkdir -p "$home_dir/.config/gh-msync" "$base_dir"
    cat > "$home_dir/.config/gh-msync/config" <<'EOF_CFG'
  # comment

   ~/Repos

EOF_CFG

    out="$TMP_ROOT/no-repos-config.txt"
    set +e
    HOME="$home_dir" GH_MSYNC_DISABLE_INTEGRATIONS_AUTOSETUP=1 scripts/gh-msync --headless >"$out" 2>&1
    status=$?
    set -e
    assert_status "$status" 0
    assert_file_contains "$out" "No Git repositories found"
    pass "config parsing ignores comments/blank lines and handles tilde expansion"

    local dash_dir
    dash_dir="$TMP_ROOT/--repos"
    mkdir -p "$dash_dir"
    out="$TMP_ROOT/dash-path.txt"
    set +e
    GH_MSYNC_DISABLE_INTEGRATIONS_AUTOSETUP=1 scripts/gh-msync --headless -- "$dash_dir" >"$out" 2>&1
    status=$?
    set -e
    assert_status "$status" 0
    assert_file_contains "$out" "No Git repositories found"
    pass "end-of-options marker allows repo roots beginning with '-'"
}

scenario_configure_dispatch() {
    local app_dir home_dir out status

    app_dir="$TMP_ROOT/configure-dispatch"
    home_dir="$TMP_ROOT/home-configure-dispatch"
    mkdir -p "$app_dir/scripts"
    cp "$REPO_DIR/scripts/gh-msync" "$app_dir/scripts/gh-msync"

    cat > "$app_dir/scripts/configure-paths.sh" <<'EOF_CFGSTUB'
#!/bin/bash
set -euo pipefail
printf '%s\n' "$*" > "${HOME}/configure-args.log"
exit 0
EOF_CFGSTUB
    chmod +x "$app_dir/scripts/configure-paths.sh"

    # Provide helper so --configure can find it if stdout is a TTY in future changes.
    cat > "$app_dir/scripts/system-integrations.sh" <<'EOF_INTSTUB'
#!/bin/bash
exit 0
EOF_INTSTUB
    chmod +x "$app_dir/scripts/system-integrations.sh"

    out="$TMP_ROOT/configure-dispatch.txt"
    mkdir -p "$home_dir"
    set +e
    HOME="$home_dir" "$app_dir/scripts/gh-msync" --configure --cli >"$out" 2>&1
    status=$?
    set -e
    assert_status "$status" 0
    assert_file_contains "$home_dir/configure-args.log" "--cli"
    pass "gh-msync --configure dispatches to configure helper and forwards CLI flag"
}

scenario_stubbed_sync_logic() {
    local home_dir base_dir stub_dir state_dir log_file out status

    home_dir="$TMP_ROOT/home-stubbed-sync"
    base_dir="$TMP_ROOT/stubbed-sync-base"
    stub_dir="$TMP_ROOT/stubbed-sync-stubs"
    state_dir="$TMP_ROOT/stubbed-sync-state"
    log_file="$TMP_ROOT/stubbed-sync-git.log"
    mkdir -p "$home_dir" "$base_dir" "$stub_dir" "$state_dir"
    : > "$log_file"

    mkdir -p "$base_dir/repo-update/.git" "$base_dir/repo-modified/.git" "$base_dir/repo-fail/.git"

    cat > "$stub_dir/git" <<'EOF_GITSTUB'
#!/bin/bash
set -euo pipefail

repo="$(basename "$PWD")"
log_file="${GIT_STUB_LOG:?}"
state_dir="${GIT_STUB_STATE_DIR:?}"

printf 'git:%s:%s\n' "$repo" "$*" >> "$log_file"

cmd1="${1:-}"
cmd2="${2:-}"
cmd3="${3:-}"

case "$cmd1" in
    status)
        if [ "$cmd2" = "--porcelain" ]; then
            case "$repo" in
                repo-modified)
                    printf ' M file.txt\n'
                    ;;
                *)
                    ;;
            esac
            exit 0
        fi
        ;;
    remote)
        if [ "$cmd2" = "get-url" ] && [ "$cmd3" = "origin" ]; then
            case "$repo" in
                repo-update|repo-fail)
                    printf 'https://github.com/Acme/%s.git\n' "$repo"
                    ;;
                repo-modified)
                    printf 'git@github.com:Acme/%s.git\n' "$repo"
                    ;;
                *)
                    printf 'git@github.com:Acme/%s.git\n' "$repo"
                    ;;
            esac
            exit 0
        fi
        if [ "$cmd2" = "set-url" ] && [ "$cmd3" = "origin" ]; then
            printf 'set-url:%s:%s\n' "$repo" "${4:-}" >> "$log_file"
            printf '%s\n' "${4:-}" > "$state_dir/remote-$repo.txt"
            exit 0
        fi
        ;;
    rev-parse)
        if [ "$cmd2" = "HEAD" ]; then
            case "$repo" in
                repo-update)
                    if [ -f "$state_dir/repo-update-updated" ]; then
                        printf 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\n'
                    else
                        printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n'
                    fi
                    ;;
                repo-fail)
                    printf 'cccccccccccccccccccccccccccccccccccccccc\n'
                    ;;
                *)
                    printf 'dddddddddddddddddddddddddddddddddddddddd\n'
                    ;;
            esac
            exit 0
        fi
        ;;
    pull)
        if [ "$cmd2" = "--rebase" ]; then
            case "$repo" in
                repo-update)
                    : > "$state_dir/repo-update-updated"
                    exit 0
                    ;;
                repo-fail)
                    exit 1
                    ;;
                *)
                    exit 0
                    ;;
            esac
        fi
        ;;
    rebase)
        if [ "$cmd2" = "--abort" ]; then
            printf 'rebase-abort:%s\n' "$repo" >> "$log_file"
            exit 0
        fi
        ;;
    rev-list)
        if [ "$cmd2" = "--count" ]; then
            printf '2\n'
            exit 0
        fi
        ;;
    diff)
        if [ "$cmd2" = "--name-only" ]; then
            printf 'file1\nfile2\n'
            exit 0
        fi
        ;;
esac

printf 'Unexpected git stub invocation: %s\n' "$*" >&2
exit 99
EOF_GITSTUB
    chmod +x "$stub_dir/git"

    cat > "$stub_dir/gh" <<'EOF_GHSTUB'
#!/bin/bash
set -euo pipefail
if [ "${1:-}" = "auth" ] && [ "${2:-}" = "status" ]; then
    exit 1
fi
exit 1
EOF_GHSTUB
    chmod +x "$stub_dir/gh"

    out="$TMP_ROOT/stubbed-sync-output.txt"
    set +e
    HOME="$home_dir" \
    PATH="$stub_dir:$BASE_PATH" \
    GH_MSYNC_DISABLE_INTEGRATIONS_AUTOSETUP=1 \
    GIT_STUB_LOG="$log_file" \
    GIT_STUB_STATE_DIR="$state_dir" \
    scripts/gh-msync --headless "$base_dir" >"$out" 2>&1
    status=$?
    set -e

    assert_status "$status" 0
    assert_file_contains "$out" "Syncing 3 repositories"
    assert_file_contains "$out" "repo-update"
    assert_file_contains "$out" "pulled 2 commits affecting 2 files"
    assert_file_contains "$out" "repo-modified"
    assert_file_contains "$out" "modified files, sync skipped"
    assert_file_contains "$out" "repo-fail"
    assert_file_contains "$out" "pull failed (rebase aborted to protect repo)"
    assert_file_contains "$out" "origin switched to SSH"

    assert_file_contains "$log_file" "set-url:repo-update:git@github.com:Acme/repo-update.git"
    assert_file_contains "$log_file" "set-url:repo-fail:git@github.com:Acme/repo-fail.git"
    assert_file_contains "$log_file" "rebase-abort:repo-fail"
    pass "stubbed sync flow covers SSH upgrade, modified skip, and rebase-abort on pull failure"

    out="$TMP_ROOT/stubbed-sync-no-ssh.txt"
    : > "$log_file"
    rm -f "$state_dir/repo-update-updated"
    set +e
    HOME="$home_dir" \
    PATH="$stub_dir:$BASE_PATH" \
    GH_MSYNC_DISABLE_INTEGRATIONS_AUTOSETUP=1 \
    GIT_STUB_LOG="$log_file" \
    GIT_STUB_STATE_DIR="$state_dir" \
    scripts/gh-msync --headless --no-ssh-upgrade "$base_dir" >"$out" 2>&1
    status=$?
    set -e
    assert_status "$status" 0
    assert_file_not_contains "$log_file" "set-url:repo-update"
    assert_file_not_contains "$out" "origin switched to SSH"
    pass "no-SSH mode disables HTTPS-to-SSH remote conversion"

    out="$TMP_ROOT/stubbed-sync-env-override.txt"
    : > "$log_file"
    rm -f "$state_dir/repo-update-updated"
    set +e
    HOME="$home_dir" \
    PATH="$stub_dir:$BASE_PATH" \
    GH_MSYNC_DISABLE_INTEGRATIONS_AUTOSETUP=1 \
    GH_MSYNC_NO_SSH_UPGRADE=1 \
    GIT_STUB_LOG="$log_file" \
    GIT_STUB_STATE_DIR="$state_dir" \
    scripts/gh-msync --headless --ssh-upgrade "$base_dir" >"$out" 2>&1
    status=$?
    set -e
    assert_status "$status" 0
    assert_file_contains "$log_file" "set-url:repo-update:git@github.com:Acme/repo-update.git"
    pass "--ssh-upgrade overrides GH_MSYNC_NO_SSH_UPGRADE=1 for a single run"
}

scenario_missing_repo_clone_url_selection() {
    local home_dir base_dir stub_dir state_dir out log_file status

    if ! supports_tty_automation; then
        skip "missing-repo clone URL selection scenario requires PTY automation support"
        return 0
    fi

    home_dir="$TMP_ROOT/home-clone-selection"
    base_dir="$TMP_ROOT/clone-selection-base"
    stub_dir="$TMP_ROOT/clone-selection-stubs"
    state_dir="$TMP_ROOT/clone-selection-state"
    log_file="$TMP_ROOT/clone-selection-git.log"
    mkdir -p "$home_dir" "$base_dir/local-existing/.git" "$stub_dir" "$state_dir"
    : > "$log_file"

    cat > "$stub_dir/git" <<'EOF_GITCLONESTUB'
#!/bin/bash
set -euo pipefail
repo="$(basename "$PWD")"
log_file="${GIT_STUB_LOG:?}"
printf 'git:%s:%s\n' "$repo" "$*" >> "$log_file"

case "${1:-}" in
    status)
        [ "${2:-}" = "--porcelain" ] && exit 0
        ;;
    remote)
        if [ "${2:-}" = "get-url" ] && [ "${3:-}" = "origin" ]; then
            printf 'git@github.com:Owner/Existing.git\n'
            exit 0
        fi
        if [ "${2:-}" = "set-url" ]; then
            exit 0
        fi
        ;;
    rev-parse)
        [ "${2:-}" = "HEAD" ] && { printf 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee\n'; exit 0; }
        ;;
    pull)
        [ "${2:-}" = "--rebase" ] && exit 0
        ;;
    clone)
        # Expected form: git clone -q URL
        printf 'clone-url:%s\n' "${3:-}" >> "$log_file"
        exit 0
        ;;
    rev-list)
        [ "${2:-}" = "--count" ] && { printf '0\n'; exit 0; }
        ;;
    diff)
        [ "${2:-}" = "--name-only" ] && exit 0
        ;;
    rebase)
        [ "${2:-}" = "--abort" ] && exit 0
        ;;
esac

printf 'Unexpected git invocation in clone test: %s\n' "$*" >&2
exit 99
EOF_GITCLONESTUB
    chmod +x "$stub_dir/git"

    cat > "$stub_dir/gh" <<'EOF_GHCLONESTUB'
#!/bin/bash
set -euo pipefail
case "${1:-}" in
    auth)
        [ "${2:-}" = "status" ] && exit 0
        ;;
    repo)
        if [ "${2:-}" = "list" ]; then
            cat <<'EOF_REPOS'
OWNER/EXISTING|git@github.com:OWNER/EXISTING.git|https://github.com/OWNER/EXISTING.git
Owner/missing-repo|git@github.com:Owner/missing-repo.git|https://github.com/Owner/missing-repo.git
EOF_REPOS
            exit 0
        fi
        ;;
esac
exit 2
EOF_GHCLONESTUB
    chmod +x "$stub_dir/gh"

    out="$TMP_ROOT/clone-selection-default.txt"
    set +e
    run_with_tty_and_input "$out" $'y\n1\n' \
        env HOME="$home_dir" PATH="$stub_dir:$BASE_PATH" GH_MSYNC_DISABLE_INTEGRATIONS_AUTOSETUP=1 \
        GIT_STUB_LOG="$log_file" GIT_STUB_STATE_DIR="$state_dir" \
        "$REPO_DIR/scripts/gh-msync" --headless "$base_dir"
    status=$?
    set -e
    assert_status "$status" 0
    assert_file_contains "$log_file" "clone-url:git@github.com:Owner/missing-repo.git"
    pass "missing-repo clone defaults to SSH URL selection"

    : > "$log_file"
    out="$TMP_ROOT/clone-selection-https.txt"
    set +e
    run_with_tty_and_input "$out" $'y\n1\n' \
        env HOME="$home_dir" PATH="$stub_dir:$BASE_PATH" GH_MSYNC_DISABLE_INTEGRATIONS_AUTOSETUP=1 \
        GIT_STUB_LOG="$log_file" GIT_STUB_STATE_DIR="$state_dir" \
        "$REPO_DIR/scripts/gh-msync" --headless --no-ssh-upgrade "$base_dir"
    status=$?
    set -e
    assert_status "$status" 0
    assert_file_contains "$log_file" "clone-url:https://github.com/Owner/missing-repo.git"
    pass "no-SSH mode uses HTTPS clone URL for missing repositories"
}

scenario_arg_parsing
scenario_config_and_no_repo_handling
scenario_configure_dispatch
scenario_stubbed_sync_logic
scenario_missing_repo_clone_url_selection

printf 'CORE BEHAVIOR TESTS COMPLETE (%s)\n' "$TMP_ROOT"
