#!/bin/bash

# ==========================================
# Sync GitHub Repositories - Installer
# ==========================================

clear
set -e

# Detect OS
OS="$(uname -s)"

# Define Paths
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$REPO_DIR/scripts/sync-github.sh"

echo ""
echo -e "\033[1;36mStarting installation for sync-github...\033[0m"
echo ""

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

ln -sf "$SCRIPT_PATH" "$LOCAL_BIN/sync-github"
echo "* Linked 'sync-github' into $LOCAL_BIN/"

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
    APP_NAME="Sync GitHub.app"
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
    
    DESKTOP_FILE="$DESKTOP_ENTRY_DIR/sync-github.desktop"
    
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Sync GitHub
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
echo "You can now run 'sync-github' from anywhere."
echo ""
