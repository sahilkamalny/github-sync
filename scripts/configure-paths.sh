#!/bin/bash
# Git Multi-Sync — path configuration only. Used by git-msync --configure and by the installer.

CONFIG_DIR="${HOME}/.config/git-msync"
CONFIG_FILE="${CONFIG_DIR}/config"
mkdir -p "$CONFIG_DIR"

OS="$(uname -s)"
CYAN="\033[1;36m"
RESET="\033[0m"

USER_PATHS=""
if [ -f "$CONFIG_FILE" ]; then
    USER_PATHS=$(paste -sd ',' "$CONFIG_FILE" 2>/dev/null || echo "")
fi

FORCE_CLI=0
QUIET=0
for arg in "$@"; do
    if [[ "$arg" == "--cli" || "$arg" == "--headless" ]]; then
        FORCE_CLI=1
    elif [[ "$arg" == "--quiet" ]]; then
        QUIET=1
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

if [ "$QUIET" -eq 0 ]; then
    printf '\033[2J\033[3J\033[H'
    echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;36m  ➢  Git Multi-Sync — Configure paths\033[0m"
    echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo ""
fi

if [ "$HAS_GUI" -eq 1 ]; then
    if [[ "$OS" == "Darwin" ]]; then
        echo -ne "    \033[3mPlease interact with the pop-up...\033[0m"
        APPLESCRIPT_OPTS=("-e" "set userPaths to {}")
        if [ -n "$USER_PATHS" ]; then
            IFS=',' read -ra PATH_ARRAY <<< "$USER_PATHS"
            for p in "${PATH_ARRAY[@]}"; do
                APPLESCRIPT_OPTS+=("-e" "set end of userPaths to POSIX path of \"$p\"")
            done
        fi

        USER_PATHS=$(osascript "${APPLESCRIPT_OPTS[@]}" -e '
        repeat
            set pathString to ""
            repeat with p in userPaths
                set pathString to pathString & "∘ " & p & return
            end repeat
            if pathString is "" then set pathString to "(None selected. Default configuration will be applied.)"

            try
                set theResult to display dialog "Current Repositories:" & return & return & pathString buttons {"Done", "Remove Folder...", "Add Folder..."} default button "Add Folder..." with title "Git Multi-Sync Configuration"

                if button returned of theResult is "Add Folder..." then
                    set newFolders to choose folder with prompt "Select a repository folder (Hold Command to select multiple):" default location (path to home folder) multiple selections allowed true
                    repeat with nf in newFolders
                        set end of userPaths to POSIX path of nf
                    end repeat
                else if button returned of theResult is "Remove Folder..." then
                    if (count of userPaths) > 0 then
                        set toRemove to choose from list userPaths with prompt "Select folder(s) to remove (Hold Command for multiple):" with multiple selections allowed
                        if toRemove is not false then
                            set newUserPaths to {}
                            repeat with p in userPaths
                                if p is not in toRemove then
                                    set end of newUserPaths to p
                                end if
                            end repeat
                            set userPaths to newUserPaths
                        end if
                    else
                        display dialog "There are no folders to remove yet." buttons {"OK"} default button "OK" with title "Git Multi-Sync Configuration"
                    end if
                else if button returned of theResult is "Done" then
                    exit repeat
                end if
            on error
                exit repeat
            end try
        end repeat

        set outString to ""
        repeat with p in userPaths
            set outString to outString & p & ","
        end repeat
        if (length of outString) > 0 then
            return text 1 thru -2 of outString
        else
            return ""
        end if
    ' 2>/dev/null || echo "")
        echo -ne "\r\033[K"
    elif [[ "$OS" == "Linux" ]]; then
        user_paths_array=()
        if [ -n "$USER_PATHS" ]; then
            IFS=',' read -ra PATH_ARRAY <<< "$USER_PATHS"
            for p in "${PATH_ARRAY[@]}"; do
                user_paths_array+=("$p")
            done
        fi

        if command -v zenity >/dev/null; then
            echo -ne "    \033[3mPlease interact with the pop-up...\033[0m"
            while true; do
                path_string=""
                for p in "${user_paths_array[@]}"; do
                    path_string+="∘ $p\n"
                done
                if [ -z "$path_string" ]; then
                    path_string="(None selected. Default configuration will be applied.)"
                fi

                action=$(zenity --question --title="Git Multi-Sync Configuration" --text="<b>Current Repositories:</b>\n\n$path_string" --ok-label="Done" --cancel-label="Add Folder..." --extra-button="Remove Folder..." 2>/dev/null)
                ret=$?

                if [ "$action" = "Remove Folder..." ]; then
                    if [ ${#user_paths_array[@]} -gt 0 ]; then
                        list_args=()
                        for p in "${user_paths_array[@]}"; do
                            list_args+=(FALSE "$p")
                        done
                        to_remove=$(zenity --list --checklist --title="Remove Folders" --text="Select folders to remove:" --column="Delete" --column="Repository Path" "${list_args[@]}" --separator="|" 2>/dev/null)
                        if [ -n "$to_remove" ]; then
                            IFS='|' read -ra TR_ARR <<< "$to_remove"
                            new_array=()
                            for p in "${user_paths_array[@]}"; do
                                keep=true
                                for r in "${TR_ARR[@]}"; do
                                    if [ "$p" = "$r" ]; then keep=false; break; fi
                                done
                                $keep && new_array+=("$p")
                            done
                            user_paths_array=("${new_array[@]}")
                        fi
                    else
                        zenity --info --title="Git Multi-Sync Configuration" --text="No folders to remove yet." 2>/dev/null
                    fi
                elif [ $ret -eq 0 ]; then
                    break
                elif [ $ret -eq 1 ]; then
                    selected=$(zenity --file-selection --directory --multiple --separator="|" --title="Select a repo folder" 2>/dev/null)
                    if [ -n "$selected" ]; then
                        IFS='|' read -ra SEL_ARR <<< "$selected"
                        for s in "${SEL_ARR[@]}"; do user_paths_array+=("$s"); done
                    fi
                else
                    break
                fi
            done
            echo -ne "\r\033[K"
        elif command -v kdialog >/dev/null; then
            echo -ne "    \033[3mPlease interact with the pop-up...\033[0m"
            while true; do
                path_string=""
                for p in "${user_paths_array[@]}"; do path_string+="∘ $p\n"; done
                [ -z "$path_string" ] && path_string="(None selected. Default configuration will be applied.)"

                kdialog --yesnocancel "Current Repositories:\n\n$path_string" --yes-label "Done" --no-label "Add Folder..." --cancel-label "Remove Folder..." --title "Git Multi-Sync Configuration" 2>/dev/null
                ret=$?

                if [ $ret -eq 0 ]; then break
                elif [ $ret -eq 1 ]; then
                    selected=$(kdialog --getexistingdirectory "$HOME" --title "Select a repo folder" 2>/dev/null)
                    [ -n "$selected" ] && user_paths_array+=("$selected")
                elif [ $ret -eq 2 ]; then
                    if [ ${#user_paths_array[@]} -gt 0 ]; then
                        list_args=()
                        for p in "${user_paths_array[@]}"; do list_args+=("$p" "$p" "off"); done
                        to_remove=$(kdialog --checklist "Select folders to remove:" "${list_args[@]}" 2>/dev/null)
                        if [ -n "$to_remove" ]; then
                            new_array=()
                            for p in "${user_paths_array[@]}"; do
                                echo "$to_remove" | grep -Fq "\"$p\"" || new_array+=("$p")
                            done
                            user_paths_array=("${new_array[@]}")
                        fi
                    else
                        kdialog --msgbox "No folders to remove yet." --title "Git Multi-Sync Configuration" 2>/dev/null
                    fi
                else
                    break
                fi
            done
            echo -ne "\r\033[K"
        else
            HAS_GUI=0
        fi

        if [ ${#user_paths_array[@]} -gt 0 ]; then
            USER_PATHS=$(IFS=,; echo "${user_paths_array[*]}")
        fi
    fi
fi

if [ "$HAS_GUI" -eq 0 ]; then
    if [ -n "$USER_PATHS" ]; then
        printf "    ${CYAN}Enter comma-separated repository root paths: ${RESET}"
        read -r input_paths
        [ -n "$input_paths" ] && USER_PATHS="$input_paths"
    else
        printf "    ${CYAN}Enter comma-separated repository root paths (e.g. ~/GitHub ~/Projects): ${RESET}"
        read -r USER_PATHS
    fi
    echo ""
fi

# Write config
if [ -n "$USER_PATHS" ]; then
    > "$CONFIG_FILE"
    IFS=',' read -ra PATH_ARRAY <<< "$USER_PATHS"
    for p in "${PATH_ARRAY[@]}"; do
        p=$(echo "$p" | xargs)
        [ -n "$p" ] && echo "$p" >> "$CONFIG_FILE"
    done
else
    > "$CONFIG_FILE"
    echo "$HOME/GitHub" >> "$CONFIG_FILE"
fi

if [ "$QUIET" -eq 0 ]; then
    echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;36m  ❏  Saved paths\033[0m"
    echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo ""
    if [ -n "$USER_PATHS" ]; then
        IFS=',' read -ra PATH_ARRAY <<< "$USER_PATHS"
        for p in "${PATH_ARRAY[@]}"; do
            p=$(echo "$p" | xargs)
            [ -n "$p" ] && echo -e "    \033[1;34m∘\033[0m $p"
        done
    else
        echo -e "    \033[1;34m∘\033[0m $HOME/GitHub (default)"
    fi
    echo ""
    echo -e "    \033[1;32mConfiguration saved to \033[4m$CONFIG_FILE\033[0m"
    echo -e "    Run \033[1mgit msync\033[0m to sync these repositories."
    echo ""
fi
