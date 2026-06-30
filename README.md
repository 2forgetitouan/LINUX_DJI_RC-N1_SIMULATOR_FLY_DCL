# DJI RC-N1 → Virtual Gamepad Bridge (Linux/Wayland) (3.1.0-linux)

Makes a DJI RC-N1 / Mavic-style remote show up to Linux as a standard Xbox 360-style gamepad, so you can use it in Liftoff, DCL, Velocidrone, etc.

Forked from [MaSsTerKidd0/DJI_RC-N1_SIMULATOR_FLY_DCL](https://github.com/MaSsTerKidd0/DJI_RC-N1_SIMULATOR_FLY_DCL), itself forked from [IvanYaky/DJI_RC-N1_SIMULATOR_FLY_DCL](https://github.com/IvanYaky/DJI_RC-N1_SIMULATOR_FLY_DCL), with one major change on top of MaSsTerKidd0's improvements:

1. **vgamepad/ViGEmBus replaced with evdev + `/dev/uinput`** the virtual gamepad is now created natively at the kernel level. Works identically under X11 and Wayland, since uinput sits below the display server entirely.
2. **Serial port auto-detection adapted for Linux** (`/dev/ttyACM*`, `/dev/ttyUSB*`), with the same DUML-response probing logic and `config.json` settings as upstream.
3. **`setup_and_run.sh`** one script that creates a virtual environment, installs missing dependencies, checks and fixes the permissions required for serial and uinput access, and launches the bridge.

---

## Quick start

1. Clone or unzip this folder anywhere.
2. Make the setup script executable and run it:
   ```bash
   chmod +x setup_and_run.sh
   ./setup_and_run.sh
   ```
   On first run it will create a `.venv`, install `pyserial` and `evdev`, and check whether your user has access to the serial port and to `/dev/uinput`. If it needs to add you to the `dialout` or `input` groups, it will ask you to reboot once — that's normal, group membership only takes effect on a new session.
3. Plug your RC-N1 into the PC with a **data** USB-C cable, using the **bottom** USB-C port on the remote.
4. Run `./setup_and_run.sh` again. Once permissions are in order, it activates the virtual environment and launches the bridge directly. You should see something like:
   ```
   Available serial ports:
     [match]  /dev/ttyACM0  C5 - V1 ACM Ctrl  (DJI)
     [skip]   /dev/ttyACM1  C5 - Log ACM Ctrl  (DJI)
   Probing candidate ports for a DUML response...
     /dev/ttyACM0: DUML response received, using this port

   DJI RC231 emulation started.
   Close the terminal (or press Ctrl+C) to stop.
   ```
5. Launch your simulator. It should pick up a standard gamepad.

Leave the terminal window open while you play — closing it stops the bridge.

---

## `config.json`

Sits next to `main.py`. Created automatically on first run if missing. All fields are optional.

```json
{
    "port": null,
    "baudrate": 115200,
    "port_description_keywords": [
        "V1 ACM Ctrl",
        "DJI",
        "C5"
    ],
    "linux_port_glob_patterns": [
        "/dev/ttyACM*",
        "/dev/ttyUSB*"
    ],
    "probe_timeout_seconds": 1.5,
    "axis_invert": {
        "lh": false,
        "lv": false,
        "rh": false,
        "rv": false,
        "camera": false
    },
    "camera_button_threshold": 32000,
    "verbose": false
}

```

| Field | Meaning |
| --- | --- |
| `port` | Force a specific device, e.g. `"/dev/ttyACM0"`. Leave `null` to auto-detect. |
| `baudrate` | Serial baud. Default 115200 — don't change unless you know why. |
| `port_description_keywords` | Substrings to match against port descriptions/manufacturer. The auto-detector tries every matching port and uses the one that answers a DUML ping. |
| `linux_port_glob_patterns` | Fallback used only if no port matches by description — tries these glob patterns directly. |
| `probe_timeout_seconds` | How long to wait for each port to respond before giving up on it. |
| `axis_invert.lh / lv / rh / rv / camera` | Flip an axis if your sim expects the opposite direction. |
| `camera_button_threshold` | How far you have to spin the camera dial (±) before it presses the mapped button. |
| `verbose` | Log every stick frame to the terminal. Useful for debugging, noisy otherwise. |

After editing the file, just restart the bridge.

---

## Troubleshooting

**`UInputError: "/dev/uinput" cannot be opened for writing`**
Permissions issue. Run `./setup_and_run.sh` — it sets up the required udev rule and group membership. If it just added you to a group, you need to reboot before it takes effect.

**`No candidate port responded.`**
Some other process is holding the serial port — typically DJI Assistant 2 running under Wine, if you use it. Close it and re-run.

**No ports listed at all.**
- Use a **data** USB-C cable (not charge-only).
- Plug into the **bottom** USB-C port on the remote.
- Check `dmesg` after plugging in — the `cdc_acm` kernel driver should pick up the device automatically; if it doesn't show up there, it's a cabling or kernel module issue, not a script issue.

**Simulator doesn't see a controller.**
Make sure `setup_and_run.sh` completed without warnings (no pending reboot, `/dev/uinput` writable). The script exposes the device as soon as it starts; no separate driver install is needed on Linux.

**Sticks centered but a bit off.**
That's the controller's mechanical center. Recalibrate in your sim's own bind UI, or check with `evtest` / `jstest` against the created device.

**One axis is reversed.**
Flip the corresponding entry in `axis_invert` to `true`. Note: vertical stick axes are already corrected internally for the XInput/evdev convention mismatch — `axis_invert` is only for actual hardware/wiring quirks.

---

## Building from source

You don't need to do this if you just want to run the bridge, `setup_and_run.sh` handles environment setup automatically.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pyserial evdev
python main.py
```

---

## Credits

- Original DUML protocol work and stick mapping: [@IvanYaky](https://github.com/IvanYaky)
- COM port auto-detection, `config.json`, single-file packaging: [@MaSsTerKidd0](https://github.com/MaSsTerKidd0)
- Linux/Wayland port (evdev/uinput, no Windows dependencies): this fork
