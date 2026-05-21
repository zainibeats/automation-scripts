# System

Scripts for host-level automation.

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
```

Dependencies:

- `bluetoothctl` / BlueZ

Set `DEVICE_MAC` at the top of the script before running.

## Remote Desktop

### `remote-desktop/xfreerdp.sh`

Starts a full-screen RDP session with `xfreerdp`.

Dependencies:

- `xfreerdp`

Edit the server, username, and password in the script before use.
