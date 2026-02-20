#!/bin/bash
printf '\033c'

echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;31m  🗑️  GitHub Sync Uninstaller\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Remove symlink
if [ -L "$HOME/.local/bin/github-sync" ]; then
    rm -f "$HOME/.local/bin/github-sync"
    echo -e "   \033[1;32m✓\033[0m Removed CLI command (\033[4m~/.local/bin/github-sync\033[0m)"
fi

# Remove Configuration
if [ -d "$HOME/.config/github-sync" ]; then
    rm -rf "$HOME/.config/github-sync"
    echo -e "   \033[1;32m✓\033[0m Removed configurations (\033[4m~/.config/github-sync\033[0m)"
fi

# Remove Linux desktop entry
if [ -f "$HOME/.local/share/applications/github-sync.desktop" ]; then
    rm -f "$HOME/.local/share/applications/github-sync.desktop"
    echo -e "   \033[1;32m✓\033[0m Removed Linux App entry (\033[4mgithub-sync.desktop\033[0m)"
fi

# Remove Mac App if exists in repo dir
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -d "$DIR/GitHub Sync.app" ]; then
    rm -rf "$DIR/GitHub Sync.app"
    echo -e "   \033[1;32m✓\033[0m Removed macOS App (\033[4mGitHub Sync.app\033[0m)"
fi

# Remove Mac App if user dragged it to system /Applications
if [ -d "/Applications/GitHub Sync.app" ]; then
    rm -rf "/Applications/GitHub Sync.app"
    echo -e "   \033[1;32m✓\033[0m Removed macOS App from system (\033[4m/Applications\033[0m)"
fi

# Remove Mac App if user dragged it to user ~/Applications
if [ -d "$HOME/Applications/GitHub Sync.app" ]; then
    rm -rf "$HOME/Applications/GitHub Sync.app"
    echo -e "   \033[1;32m✓\033[0m Removed macOS App from user (\033[4m~/Applications\033[0m)"
fi

echo ""
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;32m  ✅ Uninstallation Complete.\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
