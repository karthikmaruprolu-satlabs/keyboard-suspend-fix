#!/bin/sh
# Remove the keyboard resume hook installed by install.sh.
# Usage: ./uninstall.sh
set -eu

DEST=/etc/systemd/system-sleep/keyboard-fix.sh

if [ ! -f "$DEST" ]; then
    echo "Nothing to remove: $DEST is not installed."
    exit 0
fi

sudo rm "$DEST"
echo "Removed: $DEST"
echo "No reboot needed — the hook only runs around suspend/resume."
