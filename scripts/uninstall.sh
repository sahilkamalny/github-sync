#!/bin/bash
# GitHub Multi-Sync uninstaller — for installations done via scripts/install.sh or
# macOS-Install.command / Linux-Install.sh. If you installed via Homebrew, use:
#   brew uninstall gh-msync
# and remove ~/.config/gh-msync manually if desired.

printf '\033[2J\033[3J\033[H'

# Detect OS
OS="$(uname -s)"
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INTEGRATIONS_HELPER="$SCRIPT_ROOT/scripts/system-integrations.sh"

string_display_width() {
    local text="$1"
    local width

    width="$(printf '%s' "$text" | wc -m | tr -d ' ')"
    if [[ ! "$width" =~ ^[0-9]+$ ]]; then
        width="${#text}"
    fi
    printf '%s' "$width"
}

print_box() {
    local title="$1"
    local border_color="${2:-\033[1;34m}"
    local title_color="${3:-\033[1;31m}"
    local title_width
    local inner_width
    local horizontal

    title_width="$(string_display_width "$title")"
    inner_width=$((title_width + 3))
    horizontal="$(printf '%*s' "$inner_width" '' | tr ' ' '━')"
    echo -e "${border_color}┏${horizontal}┓\033[0m"
    echo -e "${border_color}┃\033[0m ${title_color}${title}\033[0m  ${border_color}┃\033[0m"
    echo -e "${border_color}┗${horizontal}┛\033[0m"
}

print_box "➢  GitHub Multi-Sync (Uninstaller)" "\033[1;34m" "\033[1;31m"
echo ""

HAS_INSTALL_ARTIFACT=0
if [ -L "$HOME/.local/bin/gh-msync" ] || [ -f "$HOME/.local/bin/gh-msync" ] || [ -d "$HOME/.config/gh-msync" ] || [ -f "$HOME/.local/share/applications/gh-msync.desktop" ] || [ -f "$HOME/Desktop/gh-msync.desktop" ] || [ -d "$SCRIPT_ROOT/GitHub Multi-Sync.app" ] || [ -d "/Applications/GitHub Multi-Sync.app" ] || [ -d "$HOME/Applications/GitHub Multi-Sync.app" ] || [ -d "$HOME/Desktop/GitHub Multi-Sync.app" ] || [ -d "$SCRIPT_ROOT/GitHub Multi-Sync" ]; then
    HAS_INSTALL_ARTIFACT=1
fi

if [ "$HAS_INSTALL_ARTIFACT" -eq 0 ]; then
    echo -e "    \033[1;33mGitHub Multi-Sync is not currently installed on this system.\033[0m"
    echo -e "\n\n    ©  2026 Sahil Kamal"
    echo ""
    exit 0
fi

# Define Colors
CYAN="\033[1;36m"
RESET="\033[0m"
PATH_EXPORT_LINE="export PATH=\"\$HOME/.local/bin:\$PATH\""
PATH_EXPORT_SED_EXPR="/export PATH=\"\\\$HOME\\/.local\\/bin:\\\$PATH\"/d"

FORCE_CLI=0
for arg in "$@"; do
    if [[ "$arg" == "--cli" || "$arg" == "--headless" ]]; then
        FORCE_CLI=1
    fi
done

HAS_GUI=0
if [ "$FORCE_CLI" -eq 0 ]; then
    if [[ "$OS" == "Darwin" ]] && [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ]; then
        HAS_GUI=1
    elif [[ "$OS" == "Linux" ]] && { [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; }; then
        HAS_GUI=1
    fi
fi

# Give Terminal a brief moment to render the banner before the GUI prompt steals focus.
if [ "$HAS_GUI" -eq 1 ]; then
    sleep 0.05
fi

# Native Uninstallation Confirmation
if [ "$HAS_GUI" -eq 1 ]; then
    if [[ "$OS" == "Darwin" ]]; then
        echo -ne "    \033[3mPlease interact with the pop-up...\033[0m"
        response=$(osascript -e '
        try
            set theResult to display dialog "Are you sure you want to completely uninstall GitHub Multi-Sync?\n\nThis will remove the gh-msync command, configuration, and the desktop application." buttons {"Cancel", "Uninstall"} default button "Cancel" with title "GitHub Multi-Sync Uninstaller" with icon caution
            return button returned of theResult
        on error
            return "Cancel"
        end try
    ' 2>/dev/null)

        if [ "$response" != "Uninstall" ]; then
            echo -e "\r\033[K    \033[1;33mUninstallation cancelled.\033[0m"
            echo -e "\n\n    ©  2026 Sahil Kamal\n"
            exit 0
        fi
        echo -ne "\r\033[K"
    elif [[ "$OS" == "Linux" ]]; then
        if command -v zenity >/dev/null; then
            echo -ne "    \033[3mPlease interact with the pop-up...\033[0m"
            if ! zenity --question --title="GitHub Multi-Sync Uninstaller" --text="Are you sure you want to completely uninstall GitHub Multi-Sync?\n\nThis will remove the gh-msync command, configuration, and the desktop application." --ok-label="Uninstall" --cancel-label="Cancel" --icon-name=dialog-warning 2>/dev/null; then
                echo -e "\r\033[K    \033[1;33mUninstallation cancelled.\033[0m"
                echo -e "\n\n    ©  2026 Sahil Kamal\n"
                exit 0
            fi
            echo -ne "\r\033[K"
        elif command -v kdialog >/dev/null; then
            echo -ne "    \033[3mPlease interact with the pop-up...\033[0m"
            if ! kdialog --warningcontinuecancel "Are you sure you want to completely uninstall GitHub Multi-Sync?\n\nThis will remove the gh-msync command, configuration, and the desktop application." --title "GitHub Multi-Sync Uninstaller" --continue-label "Uninstall" 2>/dev/null; then
                echo -e "\r\033[K    \033[1;33mUninstallation cancelled.\033[0m"
                echo -e "\n\n    ©  2026 Sahil Kamal\n"
                exit 0
            fi
            echo -ne "\r\033[K"
        else
            HAS_GUI=0
        fi
    fi
fi

if [ "$HAS_GUI" -eq 0 ]; then
    printf '    %bAre you sure you want to uninstall GitHub Multi-Sync? (y/n): %b' "$CYAN" "$RESET"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n    \033[1;33mUninstallation cancelled.\033[0m"
        echo ""
        exit 0
    fi
    echo ""
fi

# Remove command
if [ -L "$HOME/.local/bin/gh-msync" ] || [ -f "$HOME/.local/bin/gh-msync" ]; then
    if rm -f "$HOME/.local/bin/gh-msync"; then
        echo -e "    \033[1;31m∘\033[0m Removed command (\033[4m~/.local/bin/gh-msync\033[0m)"
    else
        echo -e "    \033[1;33m△\033[0m Could not remove (\033[4m~/.local/bin/gh-msync\033[0m)"
    fi
fi

remove_path_injection_from_rc() {
    local rc_path="$1"
    local rc_label="$2"

    if ! grep -qF "$PATH_EXPORT_LINE" "$rc_path" 2>/dev/null; then
        return 0
    fi

    if sed -i '' "$PATH_EXPORT_SED_EXPR" "$rc_path" 2>/dev/null || sed -i "$PATH_EXPORT_SED_EXPR" "$rc_path" 2>/dev/null; then
        echo -e "    \033[1;31m∘\033[0m Removed PATH injection (\033[4m$rc_label\033[0m)"
    else
        echo -e "    \033[1;33m△\033[0m Could not update (\033[4m$rc_label\033[0m)"
    fi
}

remove_path_injection_from_rc "$HOME/.zshrc" "$HOME/.zshrc"
remove_path_injection_from_rc "$HOME/.bash_profile" "$HOME/.bash_profile"
remove_path_injection_from_rc "$HOME/.bashrc" "$HOME/.bashrc"
remove_path_injection_from_rc "$HOME/.profile" "$HOME/.profile"

# Remove desktop integrations (shared helper)
if [ -x "$INTEGRATIONS_HELPER" ]; then
    "$INTEGRATIONS_HELPER" uninstall --legacy-repo-dir "$SCRIPT_ROOT"
fi

# Remove Configuration
if [ -d "$HOME/.config/gh-msync" ]; then
    if rm -rf "$HOME/.config/gh-msync"; then
        echo -e "    \033[1;31m∘\033[0m Removed configurations (\033[4m~/.config/gh-msync\033[0m)"
    else
        echo -e "    \033[1;33m△\033[0m Could not remove (\033[4m~/.config/gh-msync\033[0m)"
    fi
fi

# Remove legacy data dir if exists in repo dir
if [ -d "$SCRIPT_ROOT/GitHub Multi-Sync" ]; then
    if rm -rf "$SCRIPT_ROOT/GitHub Multi-Sync"; then
        echo -e "    \033[1;31m∘\033[0m Removed legacy directory (\033[4mGitHub Multi-Sync\033[0m)"
    else
        echo -e "    \033[1;33m△\033[0m Could not remove legacy directory (\033[4mGitHub Multi-Sync\033[0m)"
    fi
fi

echo ""
print_box "✓  Uninstallation Complete." "\033[1;34m" "\033[1;32m"
echo ""
echo -e "    \033[1;34mGitHub Multi-Sync has been successfully uninstalled.\033[0m"
echo ""

if [[ "$OS" == "Darwin" ]]; then
    osascript -e 'display notification "Uninstallation complete. All configurations and files have been removed." with title "GitHub Multi-Sync"' >/dev/null 2>&1 || true
elif [[ "$OS" == "Linux" ]]; then
    if command -v notify-send >/dev/null; then
        notify-send "GitHub Multi-Sync" "Uninstallation complete. All configurations and files have been removed."
    fi
fi

echo -e "\n    ©  2026 Sahil Kamal"
echo ""
