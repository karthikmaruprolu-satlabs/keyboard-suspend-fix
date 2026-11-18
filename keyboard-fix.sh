#!/bin/sh
# Re-probe the built-in PS/2 (i8042/atkbd) keyboard around suspend/resume.
# Workaround for "atkbd serio0: Failed to deactivate keyboard on isa0060/serio0"
# (built-in keyboard dead after suspend until reboot; USB keyboards unaffected).
#
# Install (systemd ≥ 262 runs sleep hooks from /usr/lib only — /etc/systemd/system-sleep
# is no longer consulted):
#   sudo install -m755 keyboard-fix.sh /usr/lib/systemd/system-sleep/keyboard-fix.sh
#
# Behavior:
#   pre  : keep runtime PM from auto-suspending the i8042 serio device, so the
#          FIRST suspend of a session is protected too (the sysfs setting
#          resets to "auto" on every boot).
#   post : force a fresh atkbd probe (unbind/bind) to repair a dead keyboard,
#          verify the driver re-bound, and log the outcome to the journal.

log() { logger -t keyboard-fix "$*"; }

case "$1/$2" in
    pre/*)
        echo on > /sys/devices/platform/i8042/serio0/power/control 2>/dev/null
        ;;
    post/*)
        sleep 1
        for serio in /sys/bus/serio/drivers/atkbd/serio*; do
            [ -e "$serio" ] || continue
            d=${serio##*/}
            echo "$d" > /sys/bus/serio/drivers/atkbd/unbind 2>/dev/null
            sleep 1
            if echo "$d" > /sys/bus/serio/drivers/atkbd/bind 2>/dev/null \
               && [ -e "/sys/bus/serio/devices/$d/driver" ]; then
                log "$d re-probed OK"
            else
                log "ERROR: $d re-probe failed"
            fi
        done
        ;;
esac
