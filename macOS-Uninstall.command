#!/bin/bash
clear
echo ""
echo -e "\033[1;31mUninstalling sync-github...\033[0m"
echo ""

# Remove symlink
if [ -L "$HOME/.local/bin/sync-github" ]; then
    rm -f "$HOME/.local/bin/sync-github"
    echo "* Removed CLI 'sync-github' from ~/.local/bin"
fi

# Remove Linux desktop entry
if [ -f "$HOME/.local/share/applications/sync-github.desktop" ]; then
    rm -f "$HOME/.local/share/applications/sync-github.desktop"
    echo "* Removed Linux .desktop application entry"
fi

# Remove Mac App if exists in repo dir
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$DIR/Sync GitHub.app" ]; then
    rm -rf "$DIR/Sync GitHub.app"
    echo "* Removed macOS 'Sync GitHub.app' from repository directory"
fi

# Remove Mac App if user dragged it to system /Applications
if [ -d "/Applications/Sync GitHub.app" ]; then
    rm -rf "/Applications/Sync GitHub.app"
    echo "* Removed macOS 'Sync GitHub.app' from /Applications"
fi

# Remove Mac App if user dragged it to user ~/Applications
if [ -d "$HOME/Applications/Sync GitHub.app" ]; then
    rm -rf "$HOME/Applications/Sync GitHub.app"
    echo "* Removed macOS 'Sync GitHub.app' from ~/Applications"
fi

echo ""
echo -e "\033[1;32m✅ Uninstallation Complete.\033[0m"
echo ""
