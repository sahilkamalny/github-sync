#!/bin/bash

# ==========================================
# GitHub Sync - Installer
# ==========================================

printf '\033[2J\033[3J\033[H'
set -e

# Detect OS
OS="$(uname -s)"

# Define Paths
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_DIR/scripts/github-sync.sh"

CONFIG_DIR="$HOME/.config/github-sync"
CONFIG_FILE="$CONFIG_DIR/config"
mkdir -p "$CONFIG_DIR"

echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;36m  🚀 GitHub Sync Installer\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

USER_PATHS=""
if [ -f "$CONFIG_FILE" ]; then
    USER_PATHS=$(paste -sd ',' "$CONFIG_FILE" 2>/dev/null || echo "")
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

if [ "$HAS_GUI" -eq 1 ]; then
    if [[ "$OS" == "Darwin" ]]; then
        echo -e "    \033[3mPlease interact with the configuration pop-up...\033[0m"
        echo ""
        # macOS native AppleScript stateful menu loop
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
                set pathString to pathString & "• " & p & return
            end repeat
            if pathString is "" then set pathString to "(None selected. Default configuration will be applied.)"
            
            try
                set theResult to display dialog "Current Repositories:" & return & return & pathString buttons {"Done", "Remove Folder...", "Add Folder..."} default button "Add Folder..." with title "GitHub Sync Configuration"
                
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
                        display dialog "There are no folders to remove yet." buttons {"OK"} default button "OK" with title "GitHub Sync Configuration"
                    end if
                else if button returned of theResult is "Done" then
                    exit repeat
                end if
            on error
                -- User clicked Cancel or pressed Escape
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
    elif [[ "$OS" == "Linux" ]]; then
        # Linux GUI native stateful menu loop
        user_paths_array=()
        if [ -n "$USER_PATHS" ]; then
            IFS=',' read -ra PATH_ARRAY <<< "$USER_PATHS"
            for p in "${PATH_ARRAY[@]}"; do
                user_paths_array+=("$p")
            done
        fi
        
    if command -v zenity >/dev/null; then
        echo -e "    \033[3mPlease interact with the configuration pop-up...\033[0m"
        echo ""
        while true; do
            path_string=""
            for p in "${user_paths_array[@]}"; do
                path_string+="• $p\n"
            done
            if [ -z "$path_string" ]; then
                path_string="(None selected. Default configuration will be applied.)"
            fi
            
            action=$(zenity --question --title="GitHub Sync Configuration" --text="<b>Current Repositories:</b>\n\n$path_string" --ok-label="Done" --cancel-label="Add Folder..." --extra-button="Remove Folder..." 2>/dev/null)
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
                                if [ "$p" = "$r" ]; then
                                    keep=false
                                    break
                                fi
                            done
                            if $keep; then
                                new_array+=("$p")
                            fi
                        done
                        user_paths_array=("${new_array[@]}")
                    fi
                else
                    zenity --info --title="GitHub Sync Configuration" --text="No folders to remove yet." 2>/dev/null
                fi
            elif [ $ret -eq 0 ]; then
                break # Done
            elif [ $ret -eq 1 ]; then
                selected=$(zenity --file-selection --directory --multiple --separator="|" --title="Select a repo folder" 2>/dev/null)
                if [ -n "$selected" ]; then
                    IFS='|' read -ra SEL_ARR <<< "$selected"
                    for s in "${SEL_ARR[@]}"; do
                        user_paths_array+=("$s")
                    done
                fi
            else
                break # Window closed
            fi
        done
    elif command -v kdialog >/dev/null; then
        echo -e "    \033[3mPlease interact with the configuration pop-up...\033[0m"
        echo ""
        while true; do
            path_string=""
            for p in "${user_paths_array[@]}"; do
                path_string+="• $p\n"
            done
            if [ -z "$path_string" ]; then
                path_string="(None selected. Default configuration will be applied.)"
            fi
            
            kdialog --yesnocancel "Current Repositories:\n\n$path_string" --yes-label "Done" --no-label "Add Folder..." --cancel-label "Remove Folder..." --title "GitHub Sync Configuration" 2>/dev/null
            ret=$?
            
            if [ $ret -eq 0 ]; then
                break
            elif [ $ret -eq 1 ]; then
                selected=$(kdialog --getexistingdirectory "$HOME" --title "Select a repo folder" 2>/dev/null)
                if [ -n "$selected" ]; then
                    user_paths_array+=("$selected")
                fi
            elif [ $ret -eq 2 ]; then
                if [ ${#user_paths_array[@]} -gt 0 ]; then
                    list_args=()
                    for p in "${user_paths_array[@]}"; do
                        list_args+=("$p" "$p" "off")
                    done
                    to_remove=$(kdialog --checklist "Select folders to remove:" "${list_args[@]}" 2>/dev/null)
                    if [ -n "$to_remove" ]; then
                        new_array=()
                        for p in "${user_paths_array[@]}"; do
                            if ! echo "$to_remove" | grep -Fq "\"$p\""; then
                                new_array+=("$p")
                            fi
                        done
                        user_paths_array=("${new_array[@]}")
                    fi
                else
                    kdialog --msgbox "No folders to remove yet." --title "GitHub Sync Configuration" 2>/dev/null
                fi
            else
                break
            fi
        done
    else
        HAS_GUI=0
    fi
    
    # Rebuild USER_PATHS from array for Linux
    if [ ${#user_paths_array[@]} -gt 0 ]; then
        USER_PATHS=$(IFS=,; echo "${user_paths_array[*]}")
    fi
fi
fi

if [ "$HAS_GUI" -eq 0 ]; then
    if [ -n "$USER_PATHS" ]; then
        read -p "$(echo -e "    ${CYAN}Enter custom repository paths (comma separated) or press Enter to keep current: ${RESET}")" input_paths
        if [ -n "$input_paths" ]; then
            USER_PATHS="$input_paths"
        fi
    else
        read -p "$(echo -e "    ${CYAN}Enter custom repository paths (comma separated) or press Enter for defaults: ${RESET}")" USER_PATHS
    fi
fi

if [ -n "$USER_PATHS" ]; then
    # Clear the holding screen for the final result output
    printf '\033[2J\033[3J\033[H'
else
    # Delay clear just for logic flow
    printf '\033[2J\033[3J\033[H'
fi

echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;36m  🚀 GitHub Sync Installer\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

if [ -f "$HOME/.local/bin/github-sync" ]; then
    echo -e "    \033[1;33mGitHub Sync is already installed. Updating existing installation...\033[0m"
    ACTION_STR="Updated"
else
    echo -e "    \033[3mConfiguration saved. Preparing your synchronization environment...\033[0m"
    ACTION_STR="Generated"
fi
echo ""
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;36m  📦 Target Repositories\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

if [ -n "$USER_PATHS" ]; then
    > "$CONFIG_FILE"
    IFS=',' read -ra PATH_ARRAY <<< "$USER_PATHS"
    for p in "${PATH_ARRAY[@]}"; do
        # Trim whitespace
        p=$(echo "$p" | xargs)
        if [ -n "$p" ]; then
            echo -e "    \033[1;32m✓\033[0m $p"
            echo "$p" >> "$CONFIG_FILE"
        fi
    done
else
    echo -e "    \033[1;32m✓\033[0m ~/GitHub"
    echo ""
    echo -e "    \033[1;30m(Using Default Configuration)\033[0m"
    > "$CONFIG_FILE"
    echo "$HOME/GitHub" >> "$CONFIG_FILE"
fi

echo ""
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;36m  ⚙️  System Integrations\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# 1. Make scripts executable
chmod +x "$SCRIPT_PATH"
chmod +x "$REPO_DIR/scripts/install.sh"
chmod +x "$REPO_DIR/scripts/uninstall.sh"
echo -e "    \033[1;32m✓\033[0m Core scripts made executable"

echo -e "    \033[1;32m✓\033[0m Saved configuration to \033[4m~/.config/github-sync/config\033[0m"

# 2. Setup CLI symlink
LOCAL_BIN="$HOME/.local/bin"
if [ ! -d "$LOCAL_BIN" ]; then
    mkdir -p "$LOCAL_BIN"
    echo -e "    \033[1;32m✓\033[0m Created local bin directory (\033[4m~/.local/bin\033[0m)"
fi

ln -sf "$SCRIPT_PATH" "$LOCAL_BIN/github-sync"
ln -sf "$SCRIPT_PATH" "$LOCAL_BIN/ghsync"
echo -e "    \033[1;32m✓\033[0m Linked global CLI commands (\033[1mgithub-sync\033[0m, \033[1mghsync\033[0m)"

# 3. Handle OS-specific App Wrappers
if [[ "$OS" == "Darwin" ]]; then
    APP_NAME="GitHub Sync.app"
    APP_DIR="$REPO_DIR/$APP_NAME"
    
    rm -rf "$APP_DIR"
    osacompile -o "$APP_DIR" -e "tell application \"Terminal\"" -e "activate" -e "do script \"exec bash \\\"$APP_DIR/Contents/Resources/run.sh\\\"\"" -e "end tell" >/dev/null 2>&1
    
    cat << EOF > "$APP_DIR/Contents/Resources/run.sh"
#!/bin/bash
export APP_GUI=1
"$REPO_DIR/scripts/github-sync.sh"

echo ""
read -p "Press [Enter] to exit..."

WIN_ID=\$(osascript -e 'tell application "Terminal" to get id of front window' 2>/dev/null)
if [ -n "\$WIN_ID" ]; then
    osascript -e "tell application \\"Terminal\\" to set normal text color of (every window whose id is \$WIN_ID) to background color of (every window whose id is \$WIN_ID)" >/dev/null 2>&1
    nohup bash -c "sleep 0.1; osascript -e 'tell application \\"Terminal\\" to close (every window whose id is \$WIN_ID)'" >/dev/null 2>&1 </dev/null &
fi
exec kill -9 \$\$
EOF
    chmod +x "$APP_DIR/Contents/Resources/run.sh"
    
    if [ -f "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" ]; then
        cp "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" "$APP_DIR/Contents/Resources/applet.icns"
        touch "$APP_DIR"
    fi
    echo -e "    \033[1;32m✓\033[0m ${ACTION_STR} macOS App (\033[4mGitHub Sync.app\033[0m)"

elif [[ "$OS" == "Linux" ]]; then
    DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_ENTRY_DIR"
    DESKTOP_FILE="$DESKTOP_ENTRY_DIR/github-sync.desktop"
    
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=GitHub Sync
Comment=Synchronize all local GitHub repositories
Exec=$SCRIPT_PATH
Icon=utilities-terminal
Terminal=true
Categories=Utility;Development;
Keywords=git;github;sync;repository;
EOF

    chmod +x "$DESKTOP_FILE"
    echo -e "    \033[1;32m✓\033[0m ${ACTION_STR} Linux Application (\033[4mgithub-sync.desktop\033[0m)"
fi

PATH_INJECTED=0
for rc in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile"; do
    if [ -f "$rc" ] && grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$rc" 2>/dev/null; then
        PATH_INJECTED=1
        break
    fi
done

if [ "$PATH_INJECTED" -eq 0 ]; then
    SHELL_RC=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        if [[ "$OS" == "Darwin" ]]; then
            SHELL_RC="$HOME/.bash_profile"
        else
            SHELL_RC="$HOME/.bashrc"
        fi
    else
        SHELL_RC="$HOME/.profile"
    fi

    if [ -n "$SHELL_RC" ]; then
        echo -e "\nexport PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
        echo -e "    \033[1;32m✓\033[0m Configured PATH automatically via \033[4m$(basename "$SHELL_RC")\033[0m"
        echo -e "      \033[3m(Please restart your terminal or run 'source $SHELL_RC' to apply)\033[0m"
    fi
    echo ""
else
    echo -e "    \033[1;32m✓\033[0m PATH is already configured (\033[4m$LOCAL_BIN\033[0m)"
    echo ""
fi

echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;32m  ✅ Installation Complete!\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
echo -e "    You can now launch it by typing \033[1;36mghsync\033[0m or \033[1;36mgithub-sync\033[0m in your terminal,"
if [[ "$OS" == "Darwin" ]]; then
    echo -e "    or by double-clicking \033[1mGitHub Sync.app\033[0m in this folder,"
    echo -e "    or by finding it via Spotlight Search/Launchpad."
elif [[ "$OS" == "Linux" ]]; then
    echo -e "    or by launching it from your Linux application menu."
fi
echo ""

if [[ "$OS" == "Darwin" ]]; then
    osascript -e 'display notification "Installation complete. You can now use the github-sync command." with title "GitHub Sync"'
elif [[ "$OS" == "Linux" ]]; then
    if command -v notify-send >/dev/null; then
        notify-send "GitHub Sync" "Installation complete. You can now use the github-sync command."
    fi
fi

echo -e "\n    ©  2026 Sahil Kamal."
echo ""
