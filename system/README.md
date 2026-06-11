# System

Scripts for host-level automation.

Most scripts accept command-line options and also read a per-directory `.env`
file when present. Copy the relevant `.env.example` file to `.env` for repeated
local defaults.

## Bluetooth

### `bluetooth/bluetoothctl-connect.sh`

Connects to, disconnects from, toggles, or checks the status of a configured
Bluetooth device.

Usage:

```bash
./bluetooth/bluetoothctl-connect.sh connect
./bluetooth/bluetoothctl-connect.sh disconnect
./bluetooth/bluetoothctl-connect.sh toggle
./bluetooth/bluetoothctl-connect.sh status
./bluetooth/bluetoothctl-connect.sh --device-mac AA:BB:CC:DD:EE:FF toggle
```

Dependencies:

- `bluetoothctl` / BlueZ

Options and `.env` values:

- `DEVICE_MAC`
- `DEFAULT_ACTION`

## Remote Desktop

### `remote-desktop/xfreerdp.sh`

Starts a full-screen RDP session with `xfreerdp`.

Dependencies:

- `xfreerdp`

Usage:

```bash
./remote-desktop/xfreerdp.sh --server 192.168.1.100 --username username --password password
```

Options and `.env` values:

- `RDP_SERVER`
- `RDP_USERNAME`
- `RDP_PASSWORD`
- `RDP_FULLSCREEN`
- `RDP_EXTRA_ARGS`
