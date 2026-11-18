#!/bin/sh
# Install the keyboard resume hook into /usr/lib/systemd/system-sleep/.
#
# NOTE: systemd >= 262 executes sleep hooks ONLY from /usr/lib/systemd/system-sleep/
# (support for /etc/systemd/system-sleep/ was dropped). Installing to /etc there is a
# silent no-op — the hook never runs. This script installs to the correct location and
# removes any stale /etc copy from older versions of this fix.
#
# Usage: ./install.sh
# Requires sudo for the privileged steps only — run as a regular user.
set -eu

if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: run as a regular user; the script sudo-extracts only the install steps." >&2
    exit 1
fi

SRC="$(cd "$(dirname "$0")" && pwd)/keyboard-fix.sh"
DEST=/usr/lib/systemd/system-sleep/keyboard-fix.sh
STALE_ETC=/etc/systemd/system-sleep/keyboard-fix.sh

sudo mkdir -p /usr/lib/systemd/system-sleep
sudo install -m755 "$SRC" "$DEST"

if sudo test -f "$STALE_ETC"; then
    sudo rm "$STALE_ETC"
    echo "Removed stale hook: $STALE_ETC (systemd >= 262 ignores /etc/systemd/system-sleep)"
fi

echo "Installed: $DEST"
echo "After your next suspend/resume, verify with:"
echo "  journalctl -t keyboard-fix                      # expect: serio0 re-probed OK"
echo "  cat /sys/devices/platform/i8042/serio0/power/control   # expect: on"
