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

Create an ImageMagick montage from images in a directory.

Options:
  -i, --input-dir DIR    Source directory
  -o, --output-file FILE Output image path
      --tile VALUE       Tile layout, default: $TILE
      --geometry VALUE   Geometry, default: $GEOMETRY
  -e, --extension EXT    File extension, default: $EXTENSION
      --background VALUE Background color, default: $BACKGROUND
      --log-file FILE    Optional log file
  -h, --help             Show this help message

Configuration:
  Options can also be set in $SCRIPT_DIR/.env or the environment using the
  matching uppercase variable names.
EOF
}

require_value() {
    if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires a value." >&2
        exit 1
    fi
}

# =============================================================================
# CONFIG
# =============================================================================

INPUT_DIR="${INPUT_DIR:-$HOME/Pictures}"
OUTPUT_FILE="${OUTPUT_FILE:-output.png}"
TILE="${TILE:-3x}"
GEOMETRY="${GEOMETRY:-+2+2}"
EXTENSION="${EXTENSION:-jpg}"         # file extension to glob (jpg, png, etc.)
BACKGROUND="${BACKGROUND:-none}"      # montage background color
LOG_FILE="${LOG_FILE:-}"              # leave empty to disable file logging

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input-dir)    require_value "$@"; INPUT_DIR="$2"; shift 2 ;;
        -o|--output-file)  require_value "$@"; OUTPUT_FILE="$2"; shift 2 ;;
        --tile)            require_value "$@"; TILE="$2"; shift 2 ;;
        --geometry)        require_value "$@"; GEOMETRY="$2"; shift 2 ;;
        -e|--extension)    require_value "$@"; EXTENSION="$2"; shift 2 ;;
        --background)      require_value "$@"; BACKGROUND="$2"; shift 2 ;;
        --log-file)        require_value "$@"; LOG_FILE="$2"; shift 2 ;;
        -h|--help)         usage; exit 0 ;;
        *)                 echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

# =============================================================================
# HELPERS
# =============================================================================

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    if [[ -n "$LOG_FILE" ]]; then
        echo "$msg" >> "$LOG_FILE"
    fi
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# =============================================================================
# CHECKS
# =============================================================================

command -v montage &>/dev/null || die "'montage' not found — install ImageMagick"
[[ -d "$INPUT_DIR" ]] || die "Input directory not found: $INPUT_DIR"

shopt -s nullglob
images=("$INPUT_DIR"/*."$EXTENSION")
shopt -u nullglob

[[ ${#images[@]} -gt 0 ]] || die "No .${EXTENSION} files found in: $INPUT_DIR"

# =============================================================================
# MAIN
# =============================================================================

log "Found ${#images[@]} .${EXTENSION} file(s) in $INPUT_DIR"
log "Tile: $TILE | Geometry: $GEOMETRY | Output: $OUTPUT_FILE"

montage "${images[@]}" \
    -tile "$TILE" \
    -geometry "$GEOMETRY" \
    -background "$BACKGROUND" \
    "$OUTPUT_FILE"

log "Done → $OUTPUT_FILE"
