#!/bin/bash
printf '\033[2J\033[3J\033[H'

# Detect OS
OS="$(uname -s)"

echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;31m  ☯︎  GitHub Sync Uninstaller\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

if [ ! -f "$HOME/.local/bin/github-sync" ] && [ ! -f "$HOME/.local/bin/ghsync" ] && [ ! -d "$HOME/.config/github-sync" ]; then
    echo -e "    \033[1;33m△  GitHub Sync is not currently installed on this system.\033[0m"
    echo -e "\n\n    ©  2026 Sahil Kamal"
    echo ""
    exit 0
fi

# Define Colors
CYAN="\033[1;36m"
RESET="\033[0m"

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

# Native Uninstallation Confirmation
if [ "$HAS_GUI" -eq 1 ]; then
    if [[ "$OS" == "Darwin" ]]; then
    echo -ne "    \033[3mPlease interact with the pop-up...\033[0m"
    response=$(osascript -e '
        try
            set theResult to display dialog "Are you sure you want to completely uninstall GitHub Sync?\n\nThis will remove the CLI command, background configurations, and the desktop application." buttons {"Cancel", "Uninstall"} default button "Cancel" with title "GitHub Sync Uninstaller" with icon caution
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
elif [[ "$OS" == "Linux" ]]; then
    if command -v zenity >/dev/null; then
        echo -ne "    \033[3mPlease interact with the pop-up...\033[0m"
        zenity --question --title="GitHub Sync Uninstaller" --text="Are you sure you want to completely uninstall GitHub Sync?\n\nThis will remove the CLI command, background configurations, and the desktop application." --ok-label="Uninstall" --cancel-label="Cancel" --icon-name=dialog-warning 2>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "\r\033[K    \033[1;33mUninstallation cancelled.\033[0m"
            echo -e "\n\n    ©  2026 Sahil Kamal\n"
            exit 0
        fi
    elif command -v kdialog >/dev/null; then
        echo -ne "    \033[3mPlease interact with the pop-up...\033[0m"
        kdialog --warningcontinuecancel "Are you sure you want to completely uninstall GitHub Sync?\n\nThis will remove the CLI command, background configurations, and the desktop application." --title "GitHub Sync Uninstaller" --continue-label "Uninstall" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "\r\033[K    \033[1;33mUninstallation cancelled.\033[0m"
            echo -e "\n\n    ©  2026 Sahil Kamal\n"
            exit 0
        fi
        else
            HAS_GUI=0
        fi
    fi
fi

if [ "$HAS_GUI" -eq 0 ]; then
    read -p "$(echo -e "    ${CYAN}Are you sure you want to uninstall GitHub Sync? (y/n) ${RESET}")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n    \033[1;33mUninstallation cancelled.\033[0m"
        echo ""
        exit 0
    fi
fi

printf '\033[2J\033[3J\033[H'
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;31m  ☯︎  GitHub Sync Uninstaller\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Remove symlink
if [ -L "$HOME/.local/bin/github-sync" ] || [ -L "$HOME/.local/bin/ghsync" ]; then
    rm -f "$HOME/.local/bin/github-sync"
    rm -f "$HOME/.local/bin/ghsync"
    echo -e "    \033[1;31m∘\033[0m Removed CLI commands (\033[4m~/.local/bin/github-sync\033[0m, \033[4m~/.local/bin/ghsync\033[0m)"
fi

if grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
    sed -i '' '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$HOME/.zshrc" 2>/dev/null || sed -i '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$HOME/.zshrc" 2>/dev/null
    echo -e "    \033[1;31m∘\033[0m Removed PATH injection (\033[4m~/.zshrc\033[0m)"
fi
if grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bash_profile" 2>/dev/null; then
    sed -i '' '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$HOME/.bash_profile" 2>/dev/null || sed -i '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$HOME/.bash_profile" 2>/dev/null
    echo -e "    \033[1;31m∘\033[0m Removed PATH injection (\033[4m~/.bash_profile\033[0m)"
fi
if grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    sed -i '' '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$HOME/.bashrc" 2>/dev/null || sed -i '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$HOME/.bashrc" 2>/dev/null
    echo -e "    \033[1;31m∘\033[0m Removed PATH injection (\033[4m~/.bashrc\033[0m)"
fi
if grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile" 2>/dev/null; then
    sed -i '' '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$HOME/.profile" 2>/dev/null || sed -i '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$HOME/.profile" 2>/dev/null
    echo -e "    \033[1;31m∘\033[0m Removed PATH injection (\033[4m~/.profile\033[0m)"
fi

# Remove Configuration
if [ -d "$HOME/.config/github-sync" ]; then
    rm -rf "$HOME/.config/github-sync"
    echo -e "    \033[1;31m∘\033[0m Removed configurations (\033[4m~/.config/github-sync\033[0m)"
fi

# Remove Linux desktop entry
if [ -f "$HOME/.local/share/applications/github-sync.desktop" ]; then
    rm -f "$HOME/.local/share/applications/github-sync.desktop"
    echo -e "    \033[1;31m∘\033[0m Removed Linux App entry (\033[4mgithub-sync.desktop\033[0m)"
fi

# Remove Mac App if exists in repo dir
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -d "$DIR/GitHub Sync.app" ]; then
    rm -rf "$DIR/GitHub Sync.app"
    echo -e "    \033[1;31m∘\033[0m Removed macOS App (\033[4mGitHub Sync.app\033[0m)"
fi

# Remove Mac App if user dragged it to system /Applications
if [ -d "/Applications/GitHub Sync.app" ]; then
    rm -rf "/Applications/GitHub Sync.app"
    echo -e "    \033[1;31m∘\033[0m Removed macOS App from system (\033[4m/Applications\033[0m)"
fi

# Remove Mac App if user dragged it to user ~/Applications
if [ -d "$HOME/Applications/GitHub Sync.app" ]; then
    rm -rf "$HOME/Applications/GitHub Sync.app"
    echo -e "    \033[1;31m∘\033[0m Removed macOS App from user (\033[4m~/Applications\033[0m)"
fi

# Remove Mac App if user dragged it to their Desktop
if [ -d "$HOME/Desktop/GitHub Sync.app" ]; then
    rm -rf "$HOME/Desktop/GitHub Sync.app"
    echo -e "    \033[1;31m∘\033[0m Removed macOS App from (\033[4m~/Desktop\033[0m)"
fi

# Remove Linux desktop entry if user dragged it to their Desktop
if [ -f "$HOME/Desktop/github-sync.desktop" ]; then
    rm -f "$HOME/Desktop/github-sync.desktop"
    echo -e "    \033[1;31m∘\033[0m Removed Linux App entry from (\033[4m~/Desktop\033[0m)"
fi

# Remove Linux Data Dir if exists in repo dir
if [ -d "$DIR/GitHub Sync" ]; then
    rm -rf "$DIR/GitHub Sync"
    echo -e "    \033[1;31m∘\033[0m Removed Linux App Directory (\033[4mGitHub Sync\033[0m)"
fi

echo ""
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;32m  ✓  Uninstallation Complete.\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
echo -e "    \033[1;36mGitHub Sync\033[0m has been successfully removed from your system."
echo ""

if [[ "$OS" == "Darwin" ]]; then
    osascript -e 'display notification "Uninstallation complete. All configurations and files have been removed." with title "GitHub Sync"'
elif [[ "$OS" == "Linux" ]]; then
    if command -v notify-send >/dev/null; then
        notify-send "GitHub Sync" "Uninstallation complete. All configurations and files have been removed."
    fi
fi

echo -e "\n    ©  2026 Sahil Kamal"
echo ""
