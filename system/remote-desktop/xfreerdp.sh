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

Start an xfreerdp session.

Options:
  -s, --server HOST      RDP server
  -u, --username USER    RDP username
  -p, --password PASS    RDP password
      --windowed         Do not start full-screen
      --extra-args ARGS  Additional xfreerdp arguments
  -h, --help             Show this help message

Configuration:
  RDP_SERVER, RDP_USERNAME, RDP_PASSWORD, RDP_FULLSCREEN, and RDP_EXTRA_ARGS
  can also be set in $SCRIPT_DIR/.env or the environment.
EOF
}

require_value() {
    if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires a value." >&2
        exit 1
    fi
}

RDP_SERVER="${RDP_SERVER:-}"
RDP_USERNAME="${RDP_USERNAME:-}"
RDP_PASSWORD="${RDP_PASSWORD:-}"
RDP_FULLSCREEN="${RDP_FULLSCREEN:-true}"
RDP_EXTRA_ARGS="${RDP_EXTRA_ARGS:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--server)     require_value "$@"; RDP_SERVER="$2"; shift 2 ;;
        -u|--username)   require_value "$@"; RDP_USERNAME="$2"; shift 2 ;;
        -p|--password)   require_value "$@"; RDP_PASSWORD="$2"; shift 2 ;;
        --windowed)      RDP_FULLSCREEN="false"; shift ;;
        --extra-args)    require_value "$@"; RDP_EXTRA_ARGS="$2"; shift 2 ;;
        -h|--help)       usage; exit 0 ;;
        *)               echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [[ -z "$RDP_SERVER" || -z "$RDP_USERNAME" || -z "$RDP_PASSWORD" ]]; then
    echo "Error: RDP_SERVER, RDP_USERNAME, and RDP_PASSWORD are required." >&2
    usage >&2
    exit 1
fi

args=()
if [[ "$RDP_FULLSCREEN" == "true" ]]; then
    args+=(/f)
fi

args+=("/v:$RDP_SERVER" "/u:$RDP_USERNAME" "/p:$RDP_PASSWORD")

if [[ -n "$RDP_EXTRA_ARGS" ]]; then
    # Split extra args intentionally so .env can contain native xfreerdp flags.
    # shellcheck disable=SC2206
    extra_args=( $RDP_EXTRA_ARGS )
    args+=("${extra_args[@]}")
fi

xfreerdp "${args[@]}"
