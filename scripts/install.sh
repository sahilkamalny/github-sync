#!/bin/bash
# Git Multi-Sync installer — for from-source and GUI installers (macOS/Linux).
# Homebrew uses packaging/homebrew/git-msync.rb and does not run this script.
# ==========================================
# Git Multi-Sync - Installer
# ==========================================

printf '\033[2J\033[3J\033[H'
set -e

# Detect OS
OS="$(uname -s)"

# Define Paths
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_DIR/scripts/git-msync"

CONFIG_DIR="$HOME/.config/git-msync"
CONFIG_FILE="$CONFIG_DIR/config"
mkdir -p "$CONFIG_DIR"

# Run path configuration (same as git msync --configure)
CONFIGURE_SCRIPT="$REPO_DIR/scripts/configure-paths.sh"
if [ ! -x "$CONFIGURE_SCRIPT" ]; then
    echo "Installer error: configure-paths.sh not found." >&2
    exit 1
fi
CONFIGURE_ARGS=("--quiet")
for arg in "$@"; do
    if [[ "$arg" == "--cli" || "$arg" == "--headless" ]]; then
        CONFIGURE_ARGS+=("$arg")
        break
    fi
done
"$CONFIGURE_SCRIPT" "${CONFIGURE_ARGS[@]}"

USER_PATHS=""
if [ -f "$CONFIG_FILE" ]; then
    USER_PATHS=$(paste -sd ',' "$CONFIG_FILE" 2>/dev/null || echo "")
fi

# Define Colors
CYAN="\033[1;36m"
RESET="\033[0m"

echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;36m  ➢  Git Multi-Sync Installer\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

if [ -f "$HOME/.local/bin/git-msync" ]; then
    echo -e "    Configuration saved. Updating \033[1;36mGit Multi-Sync\033[0m..."
    ACTION_STR="Updated"
else
    echo -e "    Configuration saved. Installing \033[1;36mGit Multi-Sync\033[0m..."
    ACTION_STR="Generated"
fi
echo ""
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;36m  ❏  Target Repositories\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

if [ -n "$USER_PATHS" ]; then
    IFS=',' read -ra PATH_ARRAY <<< "$USER_PATHS"
    for p in "${PATH_ARRAY[@]}"; do
        p=$(echo "$p" | xargs)
        [ -n "$p" ] && echo -e "    \033[1;34m∘\033[0m $p"
    done
else
    echo -e "    \033[1;34m∘\033[0m $HOME/GitHub"
    echo -e "    \033[1;30m(Using Default Configuration)\033[0m"
fi

echo ""
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;36m  ❏  System Integrations\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# 1. Make scripts executable
chmod +x "$SCRIPT_PATH"
chmod +x "$REPO_DIR/scripts/install.sh"
chmod +x "$REPO_DIR/scripts/uninstall.sh"
echo -e "    \033[1;32m∘\033[0m Core scripts made executable"

echo -e "    \033[1;32m∘\033[0m Saved configuration to \033[4m~/.config/git-msync/config\033[0m"

# 2. Setup CLI (Git subcommand: git msync)
LOCAL_BIN="$HOME/.local/bin"
if [ ! -d "$LOCAL_BIN" ]; then
    mkdir -p "$LOCAL_BIN"
    echo -e "    \033[1;32m∘\033[0m Created local bin directory (\033[4m~/.local/bin\033[0m)"
fi

ln -sf "$SCRIPT_PATH" "$LOCAL_BIN/git-msync"
echo -e "    \033[1;32m∘\033[0m Installed Git subcommand (\033[1mgit msync\033[0m)"

# 3. Handle OS-specific App Wrappers
if [[ "$OS" == "Darwin" ]]; then
    APP_NAME="Git Multi-Sync.app"
    APP_DIR="$REPO_DIR/$APP_NAME"
    
    rm -rf "$APP_DIR"
    osacompile -o "$APP_DIR" -e "tell application \"Terminal\"" -e "activate" -e "do script \"exec bash \\\"$APP_DIR/Contents/Resources/run.sh\\\"\"" -e "end tell" >/dev/null 2>&1
    
    cat << EOF > "$APP_DIR/Contents/Resources/run.sh"
#!/bin/bash
export APP_GUI=1
"$REPO_DIR/scripts/git-msync"

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
    echo -e "    \033[1;32m∘\033[0m ${ACTION_STR} macOS App (\033[1;4;37mGit Multi-Sync.app\033[0m)"

elif [[ "$OS" == "Linux" ]]; then
    DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_ENTRY_DIR"
    DESKTOP_FILE="$DESKTOP_ENTRY_DIR/git-msync.desktop"
    
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Git Multi-Sync
Comment=Synchronize all local GitHub repositories
Exec=$SCRIPT_PATH
Icon=utilities-terminal
Terminal=true
Categories=Utility;Development;
Keywords=git;github;sync;repository;
EOF

    chmod +x "$DESKTOP_FILE"
    echo -e "    \033[1;32m∘\033[0m ${ACTION_STR} Linux Application (\033[4mgit-msync.desktop\033[0m)"
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
        echo -e "    \033[1;32m∘\033[0m Configured PATH automatically via \033[4m$(basename "$SHELL_RC")\033[0m"
        echo -e "      \033[3m(Please restart your terminal or run 'source $SHELL_RC' to apply)\033[0m"
    fi
    echo ""
else
    echo -e "    \033[1;32m∘\033[0m PATH is already configured (\033[4m$LOCAL_BIN\033[0m)"
    echo ""
fi

echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;32m  ✓  Installation Complete!\033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
echo -e "    You can now run \033[1;36mgit msync\033[0m in your terminal (native Git subcommand),"
if [[ "$OS" == "Darwin" ]]; then
    echo -e "    or double-click \033[1;4;36mGit Multi-Sync.app\033[0m in this folder,"
    echo -e "    or find it via Spotlight Search / Launchpad."
elif [[ "$OS" == "Linux" ]]; then
    echo -e "    or launch \033[1mGit Multi-Sync\033[0m from your application menu."
fi
echo ""

if [[ "$OS" == "Darwin" ]]; then
    osascript -e 'display notification "Installation complete. You can now run git msync." with title "Git Multi-Sync"'
elif [[ "$OS" == "Linux" ]]; then
    if command -v notify-send >/dev/null; then
        notify-send "Git Multi-Sync" "Installation complete. You can now run git msync."
    fi
fi

echo -e "\n    ©  2026 Sahil Kamal"
echo ""
