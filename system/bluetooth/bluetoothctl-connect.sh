#!/usr/bin/env bash
# bluetoothctl-connect.sh
# Connects to, disconnects from, or checks a configured Bluetooth device.
# Requires: bluetoothctl

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
fi

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [connect|disconnect|toggle|status]

Control or inspect a configured Bluetooth device.

Options:
  -m, --device-mac MAC  Bluetooth device MAC address
      --default-action ACTION
  -h, --help            Show this help message

Configuration:
  DEVICE_MAC and DEFAULT_ACTION can also be set in $SCRIPT_DIR/.env or the
  environment.
EOF
}

require_value() {
    if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires a value." >&2
        exit 1
    fi
}

DEVICE_MAC="${DEVICE_MAC:-}"
DEFAULT_ACTION="${DEFAULT_ACTION:-connect}"
ACTION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--device-mac)     require_value "$@"; DEVICE_MAC="$2"; shift 2 ;;
        --default-action)    require_value "$@"; DEFAULT_ACTION="$2"; shift 2 ;;
        -h|--help)           usage; exit 0 ;;
        connect|disconnect|toggle|status)
            ACTION="$1"
            shift
            ;;
        *)
            echo "Unknown option or action: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

ACTION="${ACTION:-$DEFAULT_ACTION}"

if [[ -z "$DEVICE_MAC" ]]; then
    echo "Error: DEVICE_MAC is required." >&2
    usage >&2
    exit 1
fi

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
