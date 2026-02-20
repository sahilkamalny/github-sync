#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/scripts/uninstall.sh"

echo ""
read -p "   Press [Enter] to exit..."
kill -9 $PPID
