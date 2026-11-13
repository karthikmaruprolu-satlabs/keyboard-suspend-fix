# Keyboard Dead After Suspend — i8042/atkbd Resume Fix

A systemd sleep hook that repairs the **built-in laptop keyboard** after
suspend/resume on Linux. Typical symptom: after waking from suspend, the
internal keyboard is completely dead (until reboot) while USB/wireless
keyboards keep working, and the journal shows:

```
atkbd serio0: Failed to deactivate keyboard on isa0060/serio0
```

## Why it happens

Most laptop internal keyboards connect through the legacy **i8042** controller
and are driven by the `atkbd` kernel driver — even on modern hardware. If the
controller gets into a bad power state around suspend (runtime PM putting
`serio0` to sleep is a common trigger), the deactivation handshake fails and
the driver never recovers on resume.

Fixing it in the kernel isn't possible from userspace, but re-probing the
driver is: an **unbind/bind** of `atkbd` forces a fresh probe and keyboard
reset. This hook automates that, and additionally pins the device's runtime
power state so the failure is *prevented*, not just repaired.

## How it works

Installed to `/etc/systemd/system-sleep/keyboard-fix.sh`, systemd runs it as
root around every suspend/hibernate:

- **`pre` (before suspend):** sets
  `/sys/devices/platform/i8042/serio0/power/control` to `on`, so the i8042
  serio device never runtime-suspends. This matters for the *first* suspend of
  a session — the sysfs setting resets to `auto` on every boot.
- **`post` (after resume):** unbinds and rebinds `atkbd` on every attached
  serio device (not just `serio0`), verifies the driver re-bound via sysfs,
  and logs the result to the journal under the tag `keyboard-fix`.

Resume latency cost: ~2 seconds.

## Compatibility

- Any Linux distribution using **systemd** (Arch, Omarchy, Debian, Ubuntu,
  Fedora, …) — nothing distro-specific.
- Only needed when the internal keyboard is on the **i8042/atkbd** path.
  Check with:
  ```bash
  cat /proc/bus/input/devices | grep -B1 -A3 "AT Translated Set"
  ```
  If your internal keyboard enumerates as a plain USB HID device instead, this
  hook is harmless but unnecessary.
- Note: the boot-time kernel option `i8042.reset` helps but is **not
  sufficient by itself** on affected machines — that's exactly why this hook
  exists.

## Install

```bash
git clone https://github.com/karthikreddy-satlabs/keyboard-resume-fix.git
cd keyboard-resume-fix
./install.sh
```

The installer asks for sudo only for the privileged steps; it also removes a
legacy copy from `/usr/lib/systemd/system-sleep/` if one exists.

## Verify

Suspend and resume once, then:

```bash
journalctl -t keyboard-fix
# expect:  serio0 re-probed OK

cat /sys/devices/platform/i8042/serio0/power/control
# expect: on
```

Then test the built-in keyboard after a few more suspend cycles.

## Uninstall

```bash
./uninstall.sh
```

No reboot needed — the hook only runs around suspend/resume.

## Troubleshooting

- **`ERROR: <serio> re-probe failed` in the journal** — the controller is in a
  worse state than a re-probe can fix. Try a BIOS/UEFI update, and consider
  adding `atkbd.reset=1` to the kernel command line as a stronger variant.
- **Hook seems to never run** — confirm it's executable
  (`ls -l /etc/systemd/system-sleep/`) and watch it fire with
  `journalctl -u systemd-suspend -f` while suspending.
- **Keyboard dies even with the hook** — check whether the failure mode is the
  first suspend after boot (older versions of this fix only protected
  subsequent suspends; the `pre` branch covers that gap).

## License

[MIT](LICENSE)
