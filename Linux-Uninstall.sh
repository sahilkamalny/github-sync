#!/bin/bash
clear

do_uninstall() {
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

    echo ""
    echo -e "\033[1;32m✅ Uninstallation Complete.\033[0m"
    echo ""
}

# Source functions or run them
if command -v gnome-terminal >/dev/null; then
    gnome-terminal -- bash -c "$(declare -f do_uninstall); do_uninstall; echo ''; read -p 'Press [Enter] to close...' "
elif command -v konsole >/dev/null; then
    konsole -e bash -c "$(declare -f do_uninstall); do_uninstall; echo ''; read -p 'Press [Enter] to close...' "
elif command -v xterm >/dev/null; then
    xterm -e "bash -c \"$(declare -f do_uninstall); do_uninstall; echo ''; read -p 'Press [Enter] to close...' \""
else
    do_uninstall
fi
