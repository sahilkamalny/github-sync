#!/bin/bash
echo "Test 1"
read -p "Press [Enter]..."

osascript -e 'tell application "Terminal" to close (every window whose frontmost is true)' >/dev/null 2>&1
exec kill -9 $PPID
