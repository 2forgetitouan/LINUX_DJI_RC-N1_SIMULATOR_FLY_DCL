# DJI RC-N1 → XInput Bridge (3.1.0)

Makes a DJI RC-N1 / Mavic-style remote show up to Windows as a standard Xbox 360 gamepad, so you can use it in Liftoff, DCL, Velocidrone, etc.

Forked from [IvanYaky/DJI_RC-N1_SIMULATOR_FLY_DCL](https://github.com/IvanYaky/DJI_RC-N1_SIMULATOR_FLY_DCL) with three changes:

1. **Auto-detects the COM port** by probing for a real DUML response, so it doesn't matter whether the controller shows up as `Device USB VCOM For Protocol` or just `USB Serial Device`.
2. **`config.json`** for port, baudrate, axis invert, etc. — no more editing the source.
3. **Single-file `.exe`** built with PyInstaller. No Python install required for end users.

---

## Quick start (using the .exe)

1. Install **ViGEmBus** (one-time, signed driver): https://github.com/ViGEm/ViGEmBus/releases — grab the latest `ViGEmBus_*_x64.msi`, double-click, next-next-finish.
2. Install **DJI Assistant 2** (needed only so Windows has the DJI USB driver). After install you can leave it closed — in fact, **close it before running this tool**, because it holds the serial port.
3. Plug your RC-N1 into the PC with a **data** USB-C cable, using the **bottom** USB-C port on the remote.
4. Unzip this folder anywhere. Double-click **`dji_rcn1_bridge.exe`**.
5. You should see something like:
   ```
   Available serial ports:
     [try]  COM3  USB Serial Device
     [try]  COM9  USB Serial Device
   Probing candidate ports for DUML response...
     COM3: cannot open (...)
     COM9: DUML response received -> using this port

   Dji RC231 emulation started.
   Close terminal to stop.
   ```
6. Launch your simulator. It should pick up an Xbox 360 controller.

Leave the terminal window open while you play — closing it stops the bridge.

---

## `config.json`

Sits next to the `.exe`. Created automatically on first run if missing. All fields are optional.

```json
{
    "port": null,
    "baudrate": 115200,
    "port_description_keywords": [
        "For Protocol",
        "USB VCOM",
        "USB Serial Device",
        "Silicon Labs",
        "CP210"
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
| `port` | Force a specific COM port, e.g. `"COM9"`. Leave `null` to auto-detect. |
| `baudrate` | Serial baud. Default 115200 — don't change unless you know why. |
| `port_description_keywords` | Substrings to match against COM port descriptions. The auto-detector tries every matching port and uses the one that answers a DUML ping. |
| `probe_timeout_seconds` | How long to wait for each port to respond before giving up on it. |
| `axis_invert.lh / lv / rh / rv / camera` | Flip an axis if your sim expects the opposite direction. |
| `camera_button_threshold` | How far you have to spin the camera dial (±) before it presses Y / B. |
| `verbose` | Log every stick frame to the terminal. Useful for debugging, noisy otherwise. |

After editing the file, just restart the `.exe`.

---

## Troubleshooting

**`None of the candidate ports answered.`**
DJI Assistant 2 is probably running and holding the port. Close it from the system tray and re-run.

**No ports listed at all.**
- Use a **data** USB-C cable (not charge-only).
- Plug into the **bottom** USB-C port on the remote.
- (Re)install DJI Assistant 2 — that ships the USB driver.

**Simulator doesn't see a controller.**
Install ViGEmBus (link above). vgamepad uses it to emit the virtual Xbox 360 device.

**Sticks centered but a bit off.**
That's the controller's mechanical center. Recalibrate in Windows Game Controllers (`joy.cpl`) or in the sim's own bind UI.

**One axis is reversed.**
Flip the corresponding entry in `axis_invert` to `true`.

---

## Building from source

You don't need to do this if you have the `.exe`.

```powershell
pip install -r requirements.txt
python main.py            # run from source
.\build.bat               # rebuild dji_rcn1_bridge.exe in dist\
```

`build.bat` runs PyInstaller with `--onefile --collect-all vgamepad` (vgamepad ships a bundled DLL that needs collecting).

---

## Credits

- Original DUML protocol work and stick mapping: [@IvanYaky](https://github.com/IvanYaky)
- vgamepad / ViGEmBus authors for the virtual Xbox 360 plumbing
