#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_in_terminal() {
    if command -v gnome-terminal >/dev/null; then
        gnome-terminal -- bash -c "\"$DIR/scripts/uninstall.sh\"; echo ''; read -p 'Press [Enter] to close...' "
    elif command -v konsole >/dev/null; then
        konsole -e bash -c "\"$DIR/scripts/uninstall.sh\"; echo ''; read -p 'Press [Enter] to close...' "
    elif command -v guake >/dev/null; then
        guake -e "bash -c \"\\\"$DIR/scripts/uninstall.sh\\\"; echo ''; read -p 'Press [Enter] to close...' \""
    elif command -v terminator >/dev/null; then
        terminator -e "bash -c \"\\\"$DIR/scripts/uninstall.sh\\\"; echo ''; read -p 'Press [Enter] to close... ' \""
    elif command -v xterm >/dev/null; then
        xterm -e "bash -c \"\\\"$DIR/scripts/uninstall.sh\\\"; echo ''; read -p 'Press [Enter] to close...' \""
    else
        "$DIR/scripts/uninstall.sh"
    fi
}

run_in_terminal
