#!/bin/bash
# GitHub Multi-Sync installer — for from-source and GUI installers (macOS/Linux).
# Homebrew uses packaging/homebrew/gh-msync.rb and does not run this script.
# ==========================================
# GitHub Multi-Sync - Installer
# ==========================================

printf '\033[2J\033[3J\033[H'
set -e

# Detect OS
OS="$(uname -s)"

# Define Paths
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_DIR/scripts/gh-msync"

CONFIG_DIR="$HOME/.config/gh-msync"
CONFIG_FILE="$CONFIG_DIR/config"
mkdir -p "$CONFIG_DIR"

# Define Colors
RESET="\033[0m"
PATH_EXPORT_LINE="export PATH=\"\$HOME/.local/bin:\$PATH\""

trim_whitespace() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

string_display_width() {
    local text="$1"
    local width

    width="$(printf '%s' "$text" | wc -m | tr -d ' ')"
    if [[ ! "$width" =~ ^[0-9]+$ ]]; then
        width="${#text}"
    fi
    printf '%s' "$width"
}

escape_applescript_string() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "$value"
}

print_box() {
    local title="$1"
    local border_color="${2:-\033[1;34m}"
    local title_color="${3:-\033[1;36m}"
    local title_width
    local inner_width
    local horizontal

    title_width="$(string_display_width "$title")"
    inner_width=$((title_width + 3))
    horizontal="$(printf '%*s' "$inner_width" '' | tr ' ' '━')"
    echo -e "${border_color}┏${horizontal}┓${RESET}"
    echo -e "${border_color}┃${RESET} ${title_color}${title}${RESET}  ${border_color}┃${RESET}"
    echo -e "${border_color}┗${horizontal}┛${RESET}"
}

print_box "➢  GitHub Multi-Sync Installer" "\033[1;34m" "\033[1;36m"
echo ""

# Run path configuration (same as gh-msync --configure)
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

# Give Terminal a brief moment to render the installer banner before the GUI prompt steals focus.
sleep 0.05
"$CONFIGURE_SCRIPT" "${CONFIGURE_ARGS[@]}"

USER_PATHS=""
if [ -f "$CONFIG_FILE" ]; then
    USER_PATHS=$(paste -sd ',' "$CONFIG_FILE" 2>/dev/null || echo "")
fi

if [ -f "$HOME/.local/bin/gh-msync" ]; then
    echo -e "    Configuration saved. Updating \033[1;36mGitHub Multi-Sync\033[0m..."
else
    echo -e "    Configuration saved. Installing \033[1;36mGitHub Multi-Sync\033[0m..."
fi
echo ""
print_box "❏  Target Repositories" "\033[1;34m" "\033[1;36m"
echo ""

if [ -n "$USER_PATHS" ]; then
    IFS=',' read -ra PATH_ARRAY <<<"$USER_PATHS"
    for p in "${PATH_ARRAY[@]}"; do
        p="$(trim_whitespace "$p")"
        [ -n "$p" ] && echo -e "    \033[1;34m∘\033[0m $p"
    done
else
    echo -e "    \033[1;34m∘\033[0m $HOME/GitHub"
    echo -e "    \033[1;30m(Using Default Configuration)\033[0m"
fi

echo ""
print_box "❏  System Integrations" "\033[1;34m" "\033[1;36m"
echo ""

# 1. Make scripts executable
chmod +x "$SCRIPT_PATH"
chmod +x "$REPO_DIR/scripts/install.sh"
chmod +x "$REPO_DIR/scripts/uninstall.sh"
echo -e "    \033[1;32m∘\033[0m Core scripts made executable"

echo -e "    \033[1;32m∘\033[0m Saved configuration to \033[4m~/.config/gh-msync/config\033[0m"

# 2. Setup CLI command (gh-msync)
LOCAL_BIN="$HOME/.local/bin"
if [ ! -d "$LOCAL_BIN" ]; then
    mkdir -p "$LOCAL_BIN"
    echo -e "    \033[1;32m∘\033[0m Created local bin directory (\033[4m~/.local/bin\033[0m)"
fi

ln -sf "$SCRIPT_PATH" "$LOCAL_BIN/gh-msync"
echo -e "    \033[1;32m∘\033[0m Installed command (\033[1mgh-msync\033[0m)"

# 3. Install unified desktop integrations (macOS app / Linux launcher)
INTEGRATIONS_HELPER="$REPO_DIR/scripts/system-integrations.sh"
if [ -x "$INTEGRATIONS_HELPER" ]; then
    "$INTEGRATIONS_HELPER" install --preferred-script "$SCRIPT_PATH"
else
    echo -e "    \033[1;33m△\033[0m Could not install desktop integrations (missing \033[4msystem-integrations.sh\033[0m)"
fi

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

PATH_INJECTED=0
if [[ ":$PATH:" == *":$LOCAL_BIN:"* ]]; then
    PATH_INJECTED=1
elif [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ] && grep -qF "$PATH_EXPORT_LINE" "$SHELL_RC" 2>/dev/null; then
    PATH_INJECTED=1
fi

if [ "$PATH_INJECTED" -eq 0 ]; then
    if [ -n "$SHELL_RC" ]; then
        echo -e "\nexport PATH=\"\$HOME/.local/bin:\$PATH\"" >>"$SHELL_RC"
        echo -e "    \033[1;32m∘\033[0m Configured PATH automatically via \033[4m$(basename "$SHELL_RC")\033[0m"
        echo -e "      \033[3m(Please restart your terminal or run 'source $SHELL_RC' to apply)\033[0m"
    fi
    echo ""
else
    echo -e "    \033[1;32m∘\033[0m PATH is already configured (\033[4m$LOCAL_BIN\033[0m)"
    echo ""
fi

print_box "✓  Installation Complete!" "\033[1;34m" "\033[1;32m"
echo ""
echo -e "    You can now run \033[1;36mgh-msync\033[0m in your terminal,"
if [[ "$OS" == "Darwin" ]]; then
    echo -e "    or launch \033[1;4;36mGitHub Multi-Sync.app\033[0m from \033[4m~/Applications\033[0m,"
    echo -e "    or find it via Spotlight Search / Launchpad."
elif [[ "$OS" == "Linux" ]]; then
    echo -e "    or launch \033[1mGitHub Multi-Sync\033[0m from your application menu."
fi
echo ""

if [[ "$OS" == "Darwin" ]]; then
    osascript -e 'display notification "Installation complete. You can now run gh-msync." with title "GitHub Multi-Sync"' >/dev/null 2>&1 || true
elif [[ "$OS" == "Linux" ]]; then
    if command -v notify-send >/dev/null; then
        notify-send "GitHub Multi-Sync" "Installation complete. You can now run gh-msync."
    fi
fi

echo -e "\n    ©  2026 Sahil Kamal"
echo ""
