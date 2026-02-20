#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/scripts/uninstall.sh"

echo ""
read -p "   Press [Enter] to exit..."
MY_TTY=$(tty)
if [[ "$MY_TTY" == /dev/* ]]; then
    nohup osascript -e "
delay 0.5
tell application \"Terminal\"
    repeat with win in windows
        repeat with t in tabs of win
            if tty of t is \"$MY_TTY\" then
                close t
                return
            end if
        end repeat
    end repeat
end tell
" >/dev/null 2>&1 &
fi
kill -9 $PPID
