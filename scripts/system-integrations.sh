#!/bin/bash
# Cross-install-method launcher integration manager for gh-msync.
# Creates/removes the macOS app and Linux desktop entry using a stable launcher
# script in ~/.config/gh-msync/integrations so all install methods behave alike.

set -e

ACTION=""
QUIET=0
PREFERRED_SCRIPT=""
LEGACY_REPO_DIR=""
CONFIG_DIR="$HOME/.config/gh-msync"

usage() {
    cat <<'EOUSAGE'
Usage: system-integrations.sh <install|uninstall> [options]

Options:
  --quiet                 Suppress normal status output
  --preferred-script PATH Preferred standalone gh-msync script path for launchers
  --legacy-repo-dir PATH  Legacy repo dir to clean old app artifacts from
  --config-dir PATH       Override config dir (default: ~/.config/gh-msync)
EOUSAGE
}

log() {
    if [ "$QUIET" -eq 0 ]; then
        echo -e "$1"
    fi
}

warn() {
    echo -e "$1" >&2
}

escape_applescript_string() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "$value"
}

resolve_path() {
    local source="$1"
    local dir target
    while [ -L "$source" ]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        target="$(readlink "$source")"
        if [[ "$target" == /* ]]; then
            source="$target"
        else
            source="$dir/$target"
        fi
    done
    printf '%s' "$source"
}

write_launcher_script() {
    local integrations_dir="$CONFIG_DIR/integrations"
    local launcher_script="$integrations_dir/launch.sh"
    local preferred="$PREFERRED_SCRIPT"
    local preferred_escaped

    mkdir -p "$integrations_dir"

    if [ -n "$preferred" ]; then
        preferred="$(resolve_path "$preferred" 2>/dev/null || printf '%s' "$preferred")"
    fi
    preferred_escaped="$(printf '%s' "$preferred" | sed 's/\\/\\\\/g; s/"/\\"/g')"

    cat >"$launcher_script" <<EOF_LAUNCHER
#!/bin/bash
set -e

PREFERRED_STANDALONE="$preferred_escaped"

resolve_path() {
    local source="\$1"
    local dir target
    while [ -L "\$source" ]; do
        dir="\$(cd -P "\$(dirname "\$source")" && pwd)"
        target="\$(readlink "\$source")"
        if [[ "\$target" == /* ]]; then
            source="\$target"
        else
            source="\$dir/\$target"
        fi
    done
    printf '%s' "\$source"
}

run_target() {
    local target="\$1"
    shift
    [ -n "\$target" ] || return 127
    [ -x "\$target" ] || return 127
    "\$target" "\$@"
}

attempt_target() {
    local target="\$1"
    shift
    local status

    run_target "\$target" "\$@"
    status=\$?
    if [ \$status -eq 0 ]; then
        exit 0
    fi

    # Fall through only for invocation-style failures (missing command/interpreter, not executable).
    if [ \$status -ne 126 ] && [ \$status -ne 127 ]; then
        exit \$status
    fi

    return \$status
}

SELF_PATH="\${BASH_SOURCE[0]}"
SELF_RESOLVED="\$(resolve_path "\$SELF_PATH" 2>/dev/null || printf '%s' "\$SELF_PATH")"

if [ -n "\$PREFERRED_STANDALONE" ] && [ "\$PREFERRED_STANDALONE" != "\$SELF_PATH" ] && [ "\$PREFERRED_STANDALONE" != "\$SELF_RESOLVED" ]; then
    attempt_target "\$PREFERRED_STANDALONE" "\$@" || true
fi

if command -v gh-msync >/dev/null 2>&1; then
    GH_MSYNC_BIN="\$(command -v gh-msync)"
    GH_MSYNC_BIN_RESOLVED="\$(resolve_path "\$GH_MSYNC_BIN" 2>/dev/null || printf '%s' "\$GH_MSYNC_BIN")"
    if [ "\$GH_MSYNC_BIN" != "\$SELF_PATH" ] && [ "\$GH_MSYNC_BIN" != "\$SELF_RESOLVED" ] && [ "\$GH_MSYNC_BIN_RESOLVED" != "\$SELF_RESOLVED" ]; then
        attempt_target "\$GH_MSYNC_BIN" "\$@" || true
    fi
fi

if command -v gh >/dev/null 2>&1; then
    exec gh msync "\$@"
fi

echo "GitHub Multi-Sync launcher error: neither 'gh-msync' nor 'gh msync' is available." >&2
echo "Reinstall gh-msync (Homebrew/from source) or the GitHub CLI extension, then rerun." >&2
exit 1
EOF_LAUNCHER

    chmod +x "$launcher_script"
    printf '%s' "$launcher_script"
}

install_macos_app() {
    local launcher_script="$1"
    local app_parent="$HOME/Applications"
    local app_name="GitHub Multi-Sync.app"
    local app_dir="$app_parent/$app_name"
    local app_dir_as launcher_as

    if ! command -v osacompile >/dev/null 2>&1; then
        log "    \033[1;33m△\033[0m macOS app not created (missing \033[4mosacompile\033[0m)"
        return 0
    fi

    mkdir -p "$app_parent"
    app_dir_as="$(escape_applescript_string "$app_dir")"
    launcher_as="$(escape_applescript_string "$launcher_script")"

    rm -rf "$app_dir"
    if ! osacompile -o "$app_dir" \
        -e 'tell application "Terminal"' \
        -e 'activate' \
        -e "do script \"bash \\\"$app_dir_as/Contents/Resources/run.sh\\\"\"" \
        -e 'end tell' >/dev/null 2>&1; then
        log "    \033[1;33m△\033[0m macOS app not created (AppleScript compile failed)"
        return 0
    fi

    cat >"$app_dir/Contents/Resources/run.sh" <<EOF_MACRUN
#!/bin/bash
export APP_GUI=1
export SHELL_SESSIONS_DISABLE=1
"$launcher_as"

read -r -p "Press [Enter] to exit..."
WIN_ID="\$(osascript -e 'tell application "Terminal" to get id of front window' 2>/dev/null || true)"

if [ -n "\$WIN_ID" ]; then
    osascript -e "tell application \\\"Terminal\\\" to set normal text color of (every window whose id is \$WIN_ID) to background color of (every window whose id is \$WIN_ID)" >/dev/null 2>&1 || true
    (
        sleep 0.1
        osascript -e "tell application \\\"Terminal\\\" to close (every window whose id is \$WIN_ID) saving no" >/dev/null 2>&1 || true
    ) >/dev/null 2>&1 &
    exec /bin/kill -9 \$PPID
fi
exec /bin/kill -9 \$PPID
EOF_MACRUN
    chmod +x "$app_dir/Contents/Resources/run.sh"

    if [ -f "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" ]; then
        cp "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" "$app_dir/Contents/Resources/applet.icns" >/dev/null 2>&1 || true
        touch "$app_dir" >/dev/null 2>&1 || true
    fi

    log "    \033[1;32m∘\033[0m Installed macOS App (\033[4m~/Applications/GitHub Multi-Sync.app\033[0m)"
}

install_linux_desktop_entry() {
    local launcher_script="$1"
    local desktop_entry_dir="$HOME/.local/share/applications"
    local desktop_file="$desktop_entry_dir/gh-msync.desktop"

    mkdir -p "$desktop_entry_dir"

    cat >"$desktop_file" <<EOF_DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=GitHub Multi-Sync
Comment=Synchronize all local GitHub repositories
Exec="$launcher_script"
TryExec=$launcher_script
Icon=utilities-terminal
Terminal=true
Categories=Utility;Development;
Keywords=git;github;sync;repository;
EOF_DESKTOP

    chmod +x "$desktop_file"
    log "    \033[1;32m∘\033[0m Installed Linux Application (\033[4m~/.local/share/applications/gh-msync.desktop\033[0m)"
}

install_integrations() {
    local launcher_script os
    launcher_script="$(write_launcher_script)"
    log "    \033[1;32m∘\033[0m Installed shared app/launcher helper (\033[4m~/.config/gh-msync/integrations/launch.sh\033[0m)"

    os="$(uname -s)"
    if [[ "$os" == "Darwin" ]]; then
        install_macos_app "$launcher_script"
    elif [[ "$os" == "Linux" ]]; then
        install_linux_desktop_entry "$launcher_script"
    else
        log "    \033[1;33m△\033[0m No desktop integration for this OS (\033[4m$os\033[0m)"
    fi
}

remove_if_exists() {
    local path="$1"
    local label="$2"
    local type="${3:-file}"

    if [ "$type" = "dir" ]; then
        [ -d "$path" ] || return 0
        if rm -rf "$path" >/dev/null 2>&1; then
            log "    \033[1;31m∘\033[0m Removed $label"
        else
            log "    \033[1;33m△\033[0m Could not remove $label"
        fi
        return 0
    fi

    [ -e "$path" ] || return 0
    if rm -f "$path" >/dev/null 2>&1; then
        log "    \033[1;31m∘\033[0m Removed $label"
    else
        log "    \033[1;33m△\033[0m Could not remove $label"
    fi
}

uninstall_integrations() {
    local integrations_dir="$CONFIG_DIR/integrations"
    local launcher_script="$integrations_dir/launch.sh"

    remove_if_exists "$HOME/.local/share/applications/gh-msync.desktop" "Linux App entry (\033[4m~/.local/share/applications/gh-msync.desktop\033[0m)"
    remove_if_exists "$HOME/Desktop/gh-msync.desktop" "Linux App entry from (\033[4m~/Desktop\033[0m)"

    remove_if_exists "$HOME/Applications/GitHub Multi-Sync.app" "macOS App from (\033[4m~/Applications\033[0m)" "dir"
    remove_if_exists "$HOME/Desktop/GitHub Multi-Sync.app" "macOS App from (\033[4m~/Desktop\033[0m)" "dir"

    if [ -d "/Applications/GitHub Multi-Sync.app" ]; then
        if rm -rf "/Applications/GitHub Multi-Sync.app" >/dev/null 2>&1; then
            log "    \033[1;31m∘\033[0m Removed macOS App from system (\033[4m/Applications\033[0m)"
        else
            log "    \033[1;33m△\033[0m Could not remove app from (\033[4m/Applications\033[0m) without elevated permissions"
        fi
    fi

    if [ -n "$LEGACY_REPO_DIR" ]; then
        remove_if_exists "$LEGACY_REPO_DIR/GitHub Multi-Sync.app" "legacy macOS App in repo (\033[4mGitHub Multi-Sync.app\033[0m)" "dir"
    fi

    remove_if_exists "$launcher_script" "shared app/launcher helper (\033[4m~/.config/gh-msync/integrations/launch.sh\033[0m)"
    if [ -d "$integrations_dir" ] && [ -z "$(ls -A "$integrations_dir" 2>/dev/null)" ]; then
        rmdir "$integrations_dir" >/dev/null 2>&1 || true
    fi
}

if [ $# -lt 1 ]; then
    usage >&2
    exit 2
fi

ACTION="$1"
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --quiet)
            QUIET=1
            ;;
        --preferred-script)
            shift
            [ $# -gt 0 ] || {
                usage >&2
                exit 2
            }
            PREFERRED_SCRIPT="$1"
            ;;
        --legacy-repo-dir)
            shift
            [ $# -gt 0 ] || {
                usage >&2
                exit 2
            }
            LEGACY_REPO_DIR="$1"
            ;;
        --config-dir)
            shift
            [ $# -gt 0 ] || {
                usage >&2
                exit 2
            }
            CONFIG_DIR="$1"
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            warn "Unknown option: $1"
            usage >&2
            exit 2
            ;;
    esac
    shift
done

case "$ACTION" in
    install)
        install_integrations
        ;;
    uninstall)
        uninstall_integrations
        ;;
    *)
        warn "Unknown action: $ACTION"
        usage >&2
        exit 2
        ;;
esac
