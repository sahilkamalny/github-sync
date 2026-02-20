#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Some Linux file managers (e.g. Nautilus) launch .sh files without a visible terminal.
# To ensure the user sees the installation progress, we try to detect and spawn a terminal wrapper.
# If none are found, we just run the script directly.

run_in_terminal() {
    if command -v gnome-terminal >/dev/null; then
        gnome-terminal -- bash -c "$DIR/scripts/install.sh; echo ''; read -p 'Press [Enter] to close...' "
    elif command -v konsole >/dev/null; then
        konsole -e bash -c "$DIR/scripts/install.sh; echo ''; read -p 'Press [Enter] to close...' "
    elif command -v guake >/dev/null; then
        guake -e "bash -c \"$DIR/scripts/install.sh; echo ''; read -p 'Press [Enter] to close...' \""
    elif command -v terminator >/dev/null; then
        terminator -e "bash -c \"$DIR/scripts/install.sh; echo ''; read -p 'Press [Enter] to close... ' \""
    elif command -v xterm >/dev/null; then
        xterm -e "bash -c \"$DIR/scripts/install.sh; echo ''; read -p 'Press [Enter] to close...' \""
    else
        "$DIR/scripts/install.sh"
    fi
}

run_in_terminal
