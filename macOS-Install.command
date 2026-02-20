#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/scripts/install.sh"

echo ""
read -p "   Press [Enter] to exit..."
osascript -e 'tell application "Terminal" to close front window' >/dev/null 2>&1 &
kill -9 $PPID
