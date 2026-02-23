#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_in_terminal() {
    local arg
    local quoted_args=()
    for arg in "$@"; do
        quoted_args+=("$(printf '%q' "$arg")")
    done

    local script_cmd
    script_cmd="$(printf '%q' "$DIR/scripts/uninstall.sh")"
    if [ ${#quoted_args[@]} -gt 0 ]; then
        script_cmd+=" ${quoted_args[*]}"
    fi
    local launch_cmd="$script_cmd; read -r -p 'Press [Enter] to close...'"

    if command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal -- bash -lc "$launch_cmd"
    elif command -v konsole >/dev/null 2>&1; then
        konsole -e bash -lc "$launch_cmd"
    elif command -v guake >/dev/null 2>&1; then
        guake -e "bash -lc \"$launch_cmd\""
    elif command -v terminator >/dev/null 2>&1; then
        terminator -e "bash -lc \"$launch_cmd\""
    elif command -v xterm >/dev/null 2>&1; then
        xterm -hold -e bash -lc "$script_cmd"
    else
        "$DIR/scripts/uninstall.sh" "$@"
    fi
}

run_in_terminal "$@"
