#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/scripts/uninstall.sh"

echo ""
read -p "   Press [Enter] to exit..."
WIN_ID=$(osascript -e 'tell application "Terminal" to get id of front window' 2>/dev/null)
if [ -n "$WIN_ID" ]; then
    nohup osascript -e "delay 0.2" -e "tell application \"Terminal\" to close (every window whose id is $WIN_ID)" >/dev/null 2>&1 &
fi
kill -9 $PPID
