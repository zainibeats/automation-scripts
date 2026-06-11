#!/usr/bin/env bash

# NFS Auto-Mount Script

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
Usage: $(basename "$0") [OPTIONS]

Mount an NFS share.

Options:
  -s, --server-ip IP     NFS server IP or hostname
  -n, --nfs-share PATH   Remote NFS share path
  -m, --mount-point DIR  Local mount directory
  -o, --options VALUE    Mount options, optional
  -h, --help             Show this help message

Configuration:
  SERVER_IP, NFS_SHARE, MOUNT_POINT, and NFS_OPTIONS can also be set in
  $SCRIPT_DIR/.env or the environment.
EOF
}

require_value() {
    if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires a value." >&2
        exit 1
    fi
}

SERVER_IP="${SERVER_IP:-}"
NFS_SHARE="${NFS_SHARE:-}"
MOUNT_POINT="${MOUNT_POINT:-$HOME/remote-mount/nfs}"
NFS_OPTIONS="${NFS_OPTIONS:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--server-ip)    require_value "$@"; SERVER_IP="$2"; shift 2 ;;
        -n|--nfs-share)    require_value "$@"; NFS_SHARE="$2"; shift 2 ;;
        -m|--mount-point)  require_value "$@"; MOUNT_POINT="$2"; shift 2 ;;
        -o|--options)      require_value "$@"; NFS_OPTIONS="$2"; shift 2 ;;
        -h|--help)         usage; exit 0 ;;
        *)                 echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [[ -z "$SERVER_IP" || -z "$NFS_SHARE" || -z "$MOUNT_POINT" ]]; then
    echo "Error: SERVER_IP, NFS_SHARE, and MOUNT_POINT are required." >&2
    usage >&2
    exit 1
fi

# Check root privileges
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Error: This script must be run as root. Use: sudo $0"
    exit 1
fi

# Create mount point if needed
echo "Checking mount point: $MOUNT_POINT"
if [[ ! -d "$MOUNT_POINT" ]]; then
    echo "Creating directory: $MOUNT_POINT"
    mkdir -p "$MOUNT_POINT"
fi

# Check if already mounted
if mount | grep -q "$MOUNT_POINT"; then
    echo "Error: $MOUNT_POINT is already mounted"
    mount | grep "$MOUNT_POINT"
    exit 1
fi

# Perform the mount
echo "Mounting $SERVER_IP:$NFS_SHARE to $MOUNT_POINT..."
if [[ -n "$NFS_OPTIONS" ]]; then
    mount -t nfs -o "$NFS_OPTIONS" "$SERVER_IP:$NFS_SHARE" "$MOUNT_POINT"
else
    mount -t nfs "$SERVER_IP:$NFS_SHARE" "$MOUNT_POINT"
fi

# Verify success
echo -e "\nMount successful!"
echo "Share: $SERVER_IP:$NFS_SHARE"
echo "Location: $MOUNT_POINT"
df -hT | grep -w "$MOUNT_POINT"
