#!/usr/bin/env bash

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

Mount a remote filesystem with sshfs.

Options:
  -s, --server USER@HOST  SSH server
  -r, --remote-path PATH  Remote path to mount, default: /
  -m, --mount-dir DIR     Local mount directory
  -p, --port PORT         SSH port, default: 22
  -h, --help              Show this help message

Configuration:
  SERVER, REMOTE_PATH, REMOTE_MOUNT_DIR, and PORT can also be set in
  $SCRIPT_DIR/.env or the environment.
EOF
}

require_value() {
  if [[ $# -lt 2 ]]; then
    echo "Error: $1 requires a value." >&2
    exit 1
  fi
}

SERVER="${SERVER:-}"
REMOTE_PATH="${REMOTE_PATH:-/}"
REMOTE_MOUNT_DIR="${REMOTE_MOUNT_DIR:-$HOME/remote_mount/sshfs}"
PORT="${PORT:-22}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--server)      require_value "$@"; SERVER="$2"; shift 2 ;;
    -r|--remote-path) require_value "$@"; REMOTE_PATH="$2"; shift 2 ;;
    -m|--mount-dir)   require_value "$@"; REMOTE_MOUNT_DIR="$2"; shift 2 ;;
    -p|--port)        require_value "$@"; PORT="$2"; shift 2 ;;
    -h|--help)        usage; exit 0 ;;
    *)                echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$SERVER" ]]; then
  echo "Error: SERVER is required." >&2
  usage >&2
  exit 1
fi

if [[ ! -d "$REMOTE_MOUNT_DIR" ]]; then
  mkdir -p "$REMOTE_MOUNT_DIR"
  echo "Created remote mount directory: $REMOTE_MOUNT_DIR"
fi

if mountpoint -q "$REMOTE_MOUNT_DIR"; then
  echo "Remote mount already exists. Skipping mount."
else
  echo "Mounting remote filesystem"
  sshfs \
    -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other \
    -p "$PORT" \
    "$SERVER:$REMOTE_PATH" \
    "$REMOTE_MOUNT_DIR"
  echo "Remote filesystem mounted successfully at $REMOTE_MOUNT_DIR"
fi

if mountpoint -q "$REMOTE_MOUNT_DIR"; then
  echo "Remote mount verified."
else
  echo "Remote mount failed.  Exiting."
  exit 1
fi
