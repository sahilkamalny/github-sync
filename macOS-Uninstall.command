#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/scripts/uninstall.sh"

echo ""
read -p "   Press [Enter] to exit..."
osascript -e 'tell application "Terminal" to close front window' >/dev/null 2>&1
