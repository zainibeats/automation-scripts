#!/bin/bash
# bluetoothctl-connect.sh
# Connects to, disconnects from, or checks a configured Bluetooth device.
# Requires: bluetoothctl

# --- Config ---
DEVICE_MAC="AA:BB:CC:DD:EE:FF"
DEFAULT_ACTION="connect" # Options: "connect", "disconnect", "toggle", "status"

ACTION="${1:-$DEFAULT_ACTION}"

run_bluetoothctl() {
    bluetoothctl "$@" "$DEVICE_MAC"
}

is_connected() {
    bluetoothctl info "$DEVICE_MAC" | grep -q "Connected: yes"
}

connect_device() {
    echo ">>> Connecting to $DEVICE_MAC"
    run_bluetoothctl connect
}

disconnect_device() {
    echo ">>> Disconnecting from $DEVICE_MAC"
    run_bluetoothctl disconnect
}

show_status() {
    if is_connected; then
        echo ">>> $DEVICE_MAC is connected."
    else
        echo ">>> $DEVICE_MAC is disconnected."
    fi
}

toggle_device() {
    if is_connected; then
        disconnect_device
    else
        connect_device
    fi
}

case "$ACTION" in
    connect)
        connect_device
        ;;
    disconnect)
        disconnect_device
        ;;
    toggle)
        toggle_device
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 [connect|disconnect|toggle|status]"
        exit 1
        ;;
esac
