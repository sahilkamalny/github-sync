#!/bin/bash

# ==========================================
# Modern GitHub Repository Sync Utility
# ==========================================

printf '\033c'

CONFIG_DIR="$HOME/.config/github-sync"
CONFIG_FILE="$CONFIG_DIR/config"

DEFAULT_DIRS=(
    "$HOME/GitHub"
    "$HOME/Projects"
    "$HOME/Scripts"
    "$HOME/Repositories"
)

CONFIG_DIRS=()
if [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        # Safely expand tildes in stored configuration paths
        eval "expanded_path=\"$line\""
        CONFIG_DIRS+=("$expanded_path")
    done < "$CONFIG_FILE"
fi

if [ $# -gt 0 ]; then
    BASE_DIRS=("$@")
elif [ "${#CONFIG_DIRS[@]}" -gt 0 ]; then
    BASE_DIRS=("${CONFIG_DIRS[@]}")
else
    BASE_DIRS=("${DEFAULT_DIRS[@]}")
fi

OS="$(uname -s)"

# ---------- Colors ----------
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# ---------- Collect repos ----------
repos=()

for base in "${BASE_DIRS[@]}"; do
    [ -d "$base" ] || continue
    for d in "$base"/*/; do
        [ -d "$d/.git" ] && repos+=("$d")
    done
done

total=${#repos[@]}

# Safety check
if [ "$total" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No Git repositories found in configured directories.${RESET}"
    exit 0
fi

# ---------- Header ----------
echo -e "${BLUE}🚀  Syncing $total repositories concurrently...${RESET}"
echo ""

# Arrays to track state (Bash 3 compatible)
pids=()
tmp_files=()
repo_paths=()
before_commits=()
statuses=() # 0=Pulling, 1=Skipped, 2=Error Accessing

count=0
for repo in "${repos[@]}"; do
    repo_paths[$count]="$repo"
    
    cd "$repo" || {
        statuses[$count]=2
        ((count++))
        continue
    }

    # Convert HTTPS → SSH if needed
    current_url=$(git remote get-url origin 2>/dev/null)
    if [[ "$current_url" == https://github.com/* ]]; then
        ssh_url=$(echo "$current_url" | sed 's|https://github.com/|git@github.com:|')
        git remote set-url origin "$ssh_url"
    fi

    # Detect uncommitted changes
    modified_files=$(git status --porcelain | wc -l | tr -d ' ')

    if [ "$modified_files" -gt 0 ]; then
        statuses[$count]=1
        ((count++))
        continue
    fi

    statuses[$count]=0
    before_commits[$count]=$(git rev-parse HEAD 2>/dev/null)
    
    tmp=$(mktemp)
    tmp_files[$count]="$tmp"
    
    git pull --rebase >"$tmp" 2>&1 &
    pids[$count]=$!
    
    ((count++))
done

# Wait for all background pulls to finish, with an animated spinner
spinner=( "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" )
spin_idx=0

while true; do
    jobs_running=0
    for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            jobs_running=1
            break
        fi
    done
    
    if [ $jobs_running -eq 0 ]; then
        break
    fi
    
    printf "\r${CYAN}%s  Fetching updates from GitHub...${RESET}" "${spinner[$spin_idx]}"
    spin_idx=$(( (spin_idx + 1) % 10 ))
    sleep 0.1
done

# Clear the spinner line
printf "\r\033[K"

# Process and print results sequentially for a clean UI
display_count=1
for i in "${!repo_paths[@]}"; do
    repo="${repo_paths[$i]}"
    REPO_NAME=$(basename "$repo")
    printf "[%d/%d] %s " "$display_count" "$total" "$REPO_NAME"
    ((display_count++))
    
    if [ "${statuses[$i]}" -eq 2 ]; then
        echo -e "... ${YELLOW}⚠️  Unable to access repository${RESET}"
        continue
    elif [ "${statuses[$i]}" -eq 1 ]; then
        # We didn't save the modified file count, so we just print skipped
        echo -e "... ${YELLOW}⚠️  modified files — sync skipped${RESET}"
        continue
    fi
    
    # Check wait status of the specific background job
    wait "${pids[$i]}" 2>/dev/null
    RESULT=$?
    
    cd "$repo" || continue
    after_commit=$(git rev-parse HEAD 2>/dev/null)
    
    if [ $RESULT -ne 0 ]; then
        git rebase --abort 2>/dev/null || true
        echo -e "... ${YELLOW}⚠️  pull failed (rebase aborted to protect repo)${RESET}"
    elif [ "${before_commits[$i]}" = "$after_commit" ]; then
        echo -e "... ${GREEN}✅ already up to date${RESET}"
    else
        commit_count=$(git rev-list --count "${before_commits[$i]}..$after_commit" 2>/dev/null || echo "1")
        file_count=$(git diff --name-only "${before_commits[$i]}..$after_commit" 2>/dev/null | wc -l | tr -d ' ')
        echo -e "... ${CYAN}⬇ pulled $commit_count commit(s) affecting $file_count file(s) — now synced${RESET}"
    fi

    # Clean up temp files
    rm -f "${tmp_files[$i]}"
done

echo ""
echo -e "${BLUE}🎉  Repository sync complete.${RESET}\n"

if [[ "$OS" == "Darwin" ]]; then
    osascript -e 'display notification "GitHub repository sync complete." with title "Sync Repositories"'
elif [[ "$OS" == "Linux" ]]; then
    if command -v notify-send >/dev/null; then
        notify-send "Sync Repositories" "GitHub repository sync complete."
    fi
fi

echo -e "\n\033[3mBuilt with care by Sahil Kamal for the GitHub community.\033[0m\n"
