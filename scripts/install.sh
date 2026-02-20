#!/bin/bash

# ==========================================
# GitHub Sync - Installer
# ==========================================

clear
set -e

# Detect OS
OS="$(uname -s)"

# Define Paths
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_DIR/scripts/github-sync.sh"

echo ""
echo -e "\033[1;36mStarting installation for github-sync...\033[0m"
echo ""

# ---------- Configuration Prompt ----------
CONFIG_DIR="$HOME/.config/github-sync"
CONFIG_FILE="$CONFIG_DIR/config"

mkdir -p "$CONFIG_DIR"

echo -e "\033[1;36mConfigure Repository Paths\033[0m"
echo "By default, GitHub Sync looks in ~/GitHub, ~/Scripts, and ~/Projects."
echo "You can specify exactly where your repositories are located."
echo ""

USER_PATHS=""

if [[ "$OS" == "Darwin" ]]; then
    # macOS native AppleScript folder picker
    USER_PATHS=$(osascript -e '
        try
            set chosen_folders to choose folder with prompt "Select your GitHub repository folders (You can select multiple by holding Command):" default location (path to home folder) multiple selections allowed true
            set path_list to ""
            repeat with f in chosen_folders
                set path_list to path_list & POSIX path of f & ","
            end repeat
            if (length of path_list) > 0 then
                return text 1 thru -2 of path_list
            else
                return ""
            end if
        on error
            return ""
        end try
    ' 2>/dev/null || echo "")
elif [[ "$OS" == "Linux" ]]; then
    # Linux GUI native folder picker
    if command -v zenity >/dev/null; then
        USER_PATHS=$(zenity --file-selection --directory --multiple --separator="," --title="Select your GitHub repository folders" 2>/dev/null || echo "")
    elif command -v kdialog >/dev/null; then
        # kdialog does not easily support multiple directory selection in one go natively in all versions, but we provide standard text fallback if it fails.
        USER_PATHS=$(kdialog --getexistingdirectory "$HOME" --title "Select a GitHub repository folder" 2>/dev/null || echo "")
    else
        read -p "Enter custom repository paths (comma separated) or press Enter for defaults: " USER_PATHS
    fi
fi

if [ -n "$USER_PATHS" ]; then
    > "$CONFIG_FILE"
    IFS=',' read -ra PATH_ARRAY <<< "$USER_PATHS"
    for p in "${PATH_ARRAY[@]}"; do
        # Trim whitespace
        p=$(echo "$p" | xargs)
        if [ -n "$p" ]; then
            echo "$p" >> "$CONFIG_FILE"
        fi
    done
    echo "* Saved custom paths to $CONFIG_FILE"
    echo ""
else
    echo "* Using default paths."
    echo ""
fi

# 1. Make script executable
chmod +x "$SCRIPT_PATH"
echo "* Made script executable"

# 2. Setup CLI symlink
# We prefer ~/.local/bin to avoid sudo requirements, falling back to /usr/local/bin if necessary.
LOCAL_BIN="$HOME/.local/bin"
if [ ! -d "$LOCAL_BIN" ]; then
    mkdir -p "$LOCAL_BIN"
    echo "* Created $LOCAL_BIN"
    # Note: user might need to add ~/.local/bin to their PATH.
fi

ln -sf "$SCRIPT_PATH" "$LOCAL_BIN/github-sync"
echo "* Linked 'github-sync' into $LOCAL_BIN/"

# Check if ~/.local/bin is in PATH, if not recommend adding it
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo -e "\033[1;33m⚠️  Warning: $LOCAL_BIN is not in your PATH.\033[0m"
    if [[ "$OS" == "Darwin" ]]; then
        echo -e "Add this to your ~/.zshrc or ~/.bash_profile: \033[1;32mexport PATH=\"\$HOME/.local/bin:\$PATH\"\033[0m"
    else
        echo -e "Add this to your ~/.bashrc or ~/.profile: \033[1;32mexport PATH=\"\$HOME/.local/bin:\$PATH\"\033[0m"
    fi
fi

# 3. Handle OS-specific App Wrappers
if [[ "$OS" == "Darwin" ]]; then
    # Generate macOS Application Wrapper
    APP_NAME="GitHub Sync.app"
    echo "* Detected macOS. Generating $APP_NAME..."
    
    # We create a simple AppleScript application that binds to our script.
    APP_DIR="$REPO_DIR/$APP_NAME"
    osacompile -o "$APP_DIR" -e "tell application \"Terminal\"" -e "activate" -e "do script \"'$SCRIPT_PATH'\"" -e "end tell"
    
    # Replace default AppleScript icon with native Terminal icon
    if [ -f "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" ]; then
        cp "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" "$APP_DIR/Contents/Resources/applet.icns"
        touch "$APP_DIR"
    fi
    
    echo "* Created macOS application at $APP_DIR"
    echo "* You can drag this into your /Applications folder or run via Spotlight."

elif [[ "$OS" == "Linux" ]]; then
    # Generate Linux .desktop Entry
    echo "* Detected Linux. Generating .desktop entry..."
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
    echo "* Created application shortcut at $DESKTOP_FILE"
fi

echo ""
echo -e "\033[1;32m✅ Installation Complete!\033[0m"
echo "You can now run 'github-sync' from anywhere."
echo ""
