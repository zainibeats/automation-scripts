#!/usr/bin/env bash

# ssh-wav-mp3-master-stems.sh
# Purpose: Transfer WAV/MP3 files to remote server with special handling for master/stem files

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

Transfer WAV/MP3 files to a remote destination, excluding stem files unless
they contain "master" in the filename.

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
echo "(Skipping stem/stems files unless they contain 'master')"

# Execute rsync with optimized settings and stem file handling
# Flags:
#   -r: recursive
#   -v: verbose output
#   -u: skip files newer on receiver
#   -i: output a change-summary for all updates
#   --progress: show progress during transfer
#
# Include/Exclude Rules (processed in order):
# 1. Include master stem files (various naming patterns)
# 2. Exclude all other stem files
# 3. Include remaining WAV/MP3 files
# 4. Exclude everything else
rsync \
    -r \
    -v \
    -u \
    -i \
    --progress \
    --include='*/' \
    --include='*[Mm]aster*[Ss][Tt][Ee][Mm][Ss]*.mp3' \
    --include='*[Mm]aster*[Ss][Tt][Ee][Mm]*.mp3' \
    --include='*[Mm]aster*[Ss][Tt][Ee][Mm][Ss]*.wav' \
    --include='*[Mm]aster*[Ss][Tt][Ee][Mm]*.wav' \
    --exclude='*[Ss][Tt][Ee][Mm][Ss]*.mp3' \
    --exclude='*[Ss][Tt][Ee][Mm]*.mp3' \
    --exclude='*[Ss][Tt][Ee][Mm][Ss]*.wav' \
    --exclude='*[Ss][Tt][Ee][Mm]*.wav' \
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
