#!/usr/bin/env bash
# append-mp3.sh
# Purpose: Append .mp3 extension to all files in a directory
# Requirements: Bash shell environment and write permissions

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
Usage: $(basename "$0") [OPTIONS] [TARGET_DIR]

Append .mp3 to every regular file in TARGET_DIR.

Options:
  -d, --target-dir DIR  Directory to process
  -h, --help            Show this help message

Configuration:
  TARGET_DIR can also be set in $SCRIPT_DIR/.env or the environment.

Examples:
  $(basename "$0") ~/Music/to-fix
  TARGET_DIR=~/Music/to-fix $(basename "$0")
EOF
}

TARGET_DIR="${TARGET_DIR:-}"
TARGET_DIR_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--target-dir)
            [[ $# -ge 2 ]] || { echo "Error: $1 requires a directory." >&2; exit 1; }
            TARGET_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [[ -n "$TARGET_DIR_ARG" ]]; then
                echo "Error: Target directory was provided more than once." >&2
                usage >&2
                exit 1
            fi
            TARGET_DIR_ARG="$1"
            shift
            ;;
    esac
done

if [[ -n "$TARGET_DIR_ARG" ]]; then
    TARGET_DIR="$TARGET_DIR_ARG"
fi

if [[ -z "$TARGET_DIR" ]]; then
    echo "Error: TARGET_DIR is required." >&2
    usage >&2
    exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist." >&2
    exit 1
fi

cd "$TARGET_DIR"

renamed=0
for file in *; do
    if [[ -f "$file" ]]; then
        mv -- "$file" "$file.mp3"
        (( renamed++ )) || true
    fi
done

echo "Finished renaming $renamed file(s)."
