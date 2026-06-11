#!/usr/bin/env bash

# ssh-wav-mp3.sh
# Purpose: Transfer WAV and MP3 files to a remote server using rsync over SSH

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
Usage: $(basename "$0") [OPTIONS] [SOURCE_DIR] [DEST_SSH]

Transfer WAV and MP3 files to a remote destination with rsync over SSH.

Arguments:
  SOURCE_DIR  Local directory containing audio files
  DEST_SSH    Remote destination, for example user@host:/path

Options:
  -s, --source-dir DIR  Source directory
  -d, --dest-ssh DEST   Remote rsync destination
  -h, --help            Show this help message

Configuration:
  SOURCE_DIR and DEST_SSH can also be set in $SCRIPT_DIR/.env or the environment.
EOF
}

require_value() {
    if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires a value." >&2
        exit 1
    fi
}

SOURCE_DIR="${SOURCE_DIR:-}"
DEST_SSH="${DEST_SSH:-}"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source-dir) require_value "$@"; SOURCE_DIR="$2"; shift 2 ;;
        -d|--dest-ssh)   require_value "$@"; DEST_SSH="$2"; shift 2 ;;
        -h|--help)       usage; exit 0 ;;
        -*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            POSITIONAL+=( "$1" )
            shift
            ;;
    esac
done

if [[ ${#POSITIONAL[@]} -gt 2 ]]; then
    echo "Unexpected argument: ${POSITIONAL[2]}" >&2
    usage >&2
    exit 1
fi

if [[ ${#POSITIONAL[@]} -ge 1 ]]; then
    SOURCE_DIR="${POSITIONAL[0]}"
fi
if [[ ${#POSITIONAL[@]} -ge 2 ]]; then
    DEST_SSH="${POSITIONAL[1]}"
fi

if [[ -z "$SOURCE_DIR" || -z "$DEST_SSH" ]]; then
    echo "Error: SOURCE_DIR and DEST_SSH are required." >&2
    usage >&2
    exit 1
fi

# Validate source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist" >&2
    exit 1
fi

# Display transfer information
echo "Copying music files from: $SOURCE_DIR"
echo "To remote destination: $DEST_SSH"
echo "(Skipping files that exist and are unchanged)"

# Execute rsync with optimized settings
# Flags:
#   -r: recursive
#   -v: verbose output
#   -u: skip files newer on receiver
#   -i: output a change-summary for all updates
#   --progress: show progress during transfer
#   --include/exclude: filter rules for file selection
#   --compress: compress during transfer
#   --partial: keep partially transferred files
rsync \
    -r \
    -v \
    -u \
    -i \
    --progress \
    --include='*/' \
    --include='*.mp3' \
    --include='*.wav' \
    --exclude='*' \
    --compress \
    --compress-level=9 \
    --partial \
    --stats \
    "${SOURCE_DIR}/" \
    "${DEST_SSH}"

echo "Transfer complete!"
