#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/scripts/install.sh"

read -p "Press [Enter] to exit..."
WIN_ID=$(osascript -e 'tell application "Terminal" to get id of front window' 2>/dev/null)
if [ -n "$WIN_ID" ]; then
    osascript -e "tell application \"Terminal\" to set normal text color of (every window whose id is $WIN_ID) to background color of (every window whose id is $WIN_ID)" >/dev/null 2>&1
    nohup bash -c "sleep 0.1; osascript -e 'tell application \"Terminal\" to close (every window whose id is $WIN_ID)'" >/dev/null 2>&1 </dev/null &
fi
exec kill -9 $PPID
