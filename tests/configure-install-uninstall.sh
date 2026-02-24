#!/bin/bash
# Non-destructive tests for configure-paths, from-source install/uninstall, and
# Linux wrapper dispatch behavior (fallback path).

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

if is_windows_like; then
    skip "configure/install/uninstall lifecycle tests are POSIX-only in CI (Windows Git Bash profile skips this script)"
    exit 0
fi

scenario_configure_paths_cli() {
    local home1 home2 home3 cfg

    home1="$TMP_ROOT/config-home-1"
    mkdir -p "$home1"
    printf '  ~/GitHub , /tmp/projects ,,  /var/tmp/repos  \n' | HOME="$home1" scripts/configure-paths.sh --cli --quiet >/dev/null
    cfg="$home1/.config/gh-msync/config"
    assert_exists "$cfg"
    expected=$'~/GitHub\n/tmp/projects\n/var/tmp/repos\n'
    actual="$(cat "$cfg")"$'\n'
    assert_eq "$actual" "$expected" "configure-paths should trim and write one path per line"
    pass "configure-paths CLI writes trimmed comma-separated paths"

    home2="$TMP_ROOT/config-home-2"
    mkdir -p "$home2"
    printf '\n' | HOME="$home2" scripts/configure-paths.sh --cli --quiet >/dev/null
    cfg="$home2/.config/gh-msync/config"
    assert_exists "$cfg"
    assert_file_contains "$cfg" "$home2/GitHub"
    pass "configure-paths CLI defaults to \$HOME/GitHub on empty input"

    home3="$TMP_ROOT/config-home-3"
    mkdir -p "$home3/.config/gh-msync"
    printf '/tmp/one\n/tmp/two\n' > "$home3/.config/gh-msync/config"
    printf '\n' | HOME="$home3" scripts/configure-paths.sh --cli --quiet >/dev/null
    cfg="$home3/.config/gh-msync/config"
    actual="$(cat "$cfg")"$'\n'
    expected=$'/tmp/one\n/tmp/two\n'
    assert_eq "$actual" "$expected" "blank input should preserve existing config"
    pass "configure-paths preserves existing paths when CLI input is blank"
}

scenario_install_uninstall_lifecycle() {
    local repo_copy home_dir stub_bin out install_log integrations_log path_line
    local link_target expected_target

    repo_copy="$TMP_ROOT/install-repo-copy"
    home_dir="$TMP_ROOT/install-home"
    stub_bin="$TMP_ROOT/install-stubs"
    out="$TMP_ROOT/install-uninstall-output.txt"
    install_log="$TMP_ROOT/configure-install.log"
    integrations_log="$TMP_ROOT/integrations.log"
    path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""

    mkdir -p "$repo_copy/scripts" "$home_dir" "$stub_bin"

    cp "$REPO_DIR/scripts/install.sh" "$repo_copy/scripts/install.sh"
    cp "$REPO_DIR/scripts/uninstall.sh" "$repo_copy/scripts/uninstall.sh"

    cat > "$repo_copy/scripts/gh-msync" <<'EOF_CORE'
#!/bin/bash
exit 0
EOF_CORE
    chmod +x "$repo_copy/scripts/gh-msync"

    cat > "$repo_copy/scripts/configure-paths.sh" <<EOF_CFG
#!/bin/bash
set -euo pipefail
mkdir -p "\$HOME/.config/gh-msync"
printf '%s\n' "\$*" >> "$install_log"
printf '%s\n' "\$HOME/Repos" > "\$HOME/.config/gh-msync/config"
exit 0
EOF_CFG
    chmod +x "$repo_copy/scripts/configure-paths.sh"

    cat > "$repo_copy/scripts/system-integrations.sh" <<EOF_INT
#!/bin/bash
set -euo pipefail
printf '%s\n' "\$*" >> "$integrations_log"
if [ "\${1:-}" = "install" ]; then
    mkdir -p "\$HOME/.config/gh-msync/integrations"
    : > "\$HOME/.config/gh-msync/integrations/launch.sh"
    chmod +x "\$HOME/.config/gh-msync/integrations/launch.sh"
    mkdir -p "\$HOME/Applications/GitHub Multi-Sync.app"
elif [ "\${1:-}" = "uninstall" ]; then
    rm -rf "\$HOME/Applications/GitHub Multi-Sync.app"
    rm -f "\$HOME/.config/gh-msync/integrations/launch.sh"
fi
EOF_INT
    chmod +x "$repo_copy/scripts/system-integrations.sh"

    # Prevent real notifications/popups during lifecycle tests.
    cat > "$stub_bin/osascript" <<'EOF_OSA'
#!/bin/bash
exit 0
EOF_OSA
    cat > "$stub_bin/notify-send" <<'EOF_NOTIFY'
#!/bin/bash
exit 0
EOF_NOTIFY
    chmod +x "$stub_bin/osascript" "$stub_bin/notify-send"

    set +e
    HOME="$home_dir" SHELL="/bin/zsh" PATH="$stub_bin:$BASE_PATH" \
        bash "$repo_copy/scripts/install.sh" --cli >"$out" 2>&1
    local status=$?
    set -e
    assert_status "$status" 0
    assert_exists "$home_dir/.local/bin/gh-msync"
    [ -L "$home_dir/.local/bin/gh-msync" ] || fail "installed gh-msync should be a symlink"
    link_target="$(readlink "$home_dir/.local/bin/gh-msync")"
    link_target="$(cd "$(dirname "$link_target")" && pwd)/$(basename "$link_target")"
    expected_target="$(cd "$(dirname "$repo_copy/scripts/gh-msync")" && pwd)/$(basename "$repo_copy/scripts/gh-msync")"
    assert_eq "$link_target" "$expected_target" "installed symlink target mismatch"
    assert_exists "$home_dir/.zshrc"
    assert_file_contains "$home_dir/.zshrc" "$path_line"
    [ "$(grep -cF "$path_line" "$home_dir/.zshrc")" -eq 1 ] || fail "PATH injection should be written once"
    assert_file_contains "$install_log" "--quiet --cli"
    assert_file_contains "$integrations_log" "install --preferred-script"
    assert_file_contains "$integrations_log" "install-repo-copy/scripts/gh-msync"
    pass "from-source installer creates symlink, config, PATH injection, and shared integrations"

    # Re-run install to verify PATH injection remains idempotent.
    set +e
    HOME="$home_dir" SHELL="/bin/zsh" PATH="$stub_bin:$BASE_PATH" \
        bash "$repo_copy/scripts/install.sh" --cli >"$out" 2>&1
    status=$?
    set -e
    assert_status "$status" 0
    [ "$(grep -cF "$path_line" "$home_dir/.zshrc")" -eq 1 ] || fail "PATH injection duplicated on reinstall"
    pass "from-source installer is idempotent for PATH injection"

    set +e
    printf 'y\n' | HOME="$home_dir" SHELL="/bin/zsh" PATH="$stub_bin:$BASE_PATH" \
        bash "$repo_copy/scripts/uninstall.sh" --cli >"$out" 2>&1
    status=$?
    set -e
    assert_status "$status" 0
    assert_not_exists "$home_dir/.local/bin/gh-msync"
    assert_not_exists "$home_dir/.config/gh-msync"
    if [ -f "$home_dir/.zshrc" ]; then
        assert_file_not_contains "$home_dir/.zshrc" "$path_line"
    fi
    assert_file_contains "$integrations_log" "uninstall --legacy-repo-dir"
    assert_file_contains "$integrations_log" "install-repo-copy"
    pass "from-source uninstaller removes symlink/config/PATH injection and invokes shared cleanup helper"
}

scenario_linux_wrapper_fallback_dispatch() {
    local app_dir stub_dir install_log uninstall_log

    app_dir="$TMP_ROOT/linux-wrapper-app"
    stub_dir="$TMP_ROOT/linux-wrapper-stubs"
    install_log="$TMP_ROOT/linux-wrapper-install.log"
    uninstall_log="$TMP_ROOT/linux-wrapper-uninstall.log"
    mkdir -p "$app_dir/scripts" "$stub_dir"

    cp "$REPO_DIR/Linux-Install.sh" "$app_dir/Linux-Install.sh"
    cp "$REPO_DIR/Linux-Uninstall.sh" "$app_dir/Linux-Uninstall.sh"

    cat > "$app_dir/scripts/install.sh" <<EOF_INST
#!/bin/bash
printf '%s\n' "\$*" >> "$install_log"
exit 0
EOF_INST
    cat > "$app_dir/scripts/uninstall.sh" <<EOF_UNINST
#!/bin/bash
printf '%s\n' "\$*" >> "$uninstall_log"
exit 0
EOF_UNINST
    chmod +x "$app_dir/scripts/install.sh" "$app_dir/scripts/uninstall.sh"

    # Ensure no terminal launcher is detected so wrapper uses direct fallback.
    set +e
    PATH="$stub_dir:$BASE_PATH" bash "$app_dir/Linux-Install.sh" --cli --headless > /dev/null 2>&1
    local status=$?
    set -e
    assert_status "$status" 0
    assert_file_contains "$install_log" "--cli --headless"
    pass "Linux-Install.sh falls back to direct scripts/install.sh when no terminal app is available"

    set +e
    PATH="$stub_dir:$BASE_PATH" bash "$app_dir/Linux-Uninstall.sh" --cli > /dev/null 2>&1
    status=$?
    set -e
    assert_status "$status" 0
    assert_file_contains "$uninstall_log" "--cli"
    pass "Linux-Uninstall.sh falls back to direct scripts/uninstall.sh when no terminal app is available"
}

scenario_configure_paths_cli
scenario_install_uninstall_lifecycle
scenario_linux_wrapper_fallback_dispatch

printf 'CONFIGURE/INSTALL/UNINSTALL TESTS COMPLETE (%s)\n' "$TMP_ROOT"
