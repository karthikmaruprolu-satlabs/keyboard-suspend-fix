#!/bin/sh
# Install the keyboard resume hook into /etc/systemd/system-sleep/.
# Also removes a legacy copy from /usr/lib/systemd/system-sleep/ if present.
#
# Usage: ./install.sh
# Requires sudo for the privileged steps only — run as a regular user.
set -eu

if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: run as a regular user; the script sudo-extracts only the install steps." >&2
    exit 1
fi

SRC="$(cd "$(dirname "$0")" && pwd)/keyboard-fix.sh"
DEST=/etc/systemd/system-sleep/keyboard-fix.sh
LEGACY=/usr/lib/systemd/system-sleep/keyboard-fix.sh

sudo mkdir -p /etc/systemd/system-sleep
sudo install -m755 "$SRC" "$DEST"

if sudo test -f "$LEGACY"; then
    sudo rm "$LEGACY"
    echo "Removed legacy hook: $LEGACY"
fi

echo "Installed: $DEST"
echo "After your next suspend/resume, verify with:"
echo "  journalctl -t keyboard-fix                      # expect: serio0 re-probed OK"
echo "  cat /sys/devices/platform/i8042/serio0/power/control   # expect: on"
