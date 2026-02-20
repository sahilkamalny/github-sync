#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/scripts/install.sh"

echo ""
read -p "   Press [Enter] to exit..."
WIN_ID=$(osascript -e 'tell application "Terminal" to get id of front window' 2>/dev/null)
if [ -n "$WIN_ID" ]; then
    osascript -e 'ignoring application responses' \
              -e "tell application \"Terminal\" to close (every window whose id is $WIN_ID)" \
              -e 'end ignoring' >/dev/null 2>&1
    printf '\033c'
    read -t 2 < /dev/tty || true
fi
