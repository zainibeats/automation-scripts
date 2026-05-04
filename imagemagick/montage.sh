#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIG — edit these variables before running
# =============================================================================

INPUT_DIR="${INPUT_DIR:-$HOME/Pictures}"
OUTPUT_FILE="${OUTPUT_FILE:-output.png}"
TILE="${TILE:-3x}"
GEOMETRY="${GEOMETRY:-+2+2}"
EXTENSION="${EXTENSION:-jpg}"         # file extension to glob (jpg, png, etc.)
BACKGROUND="${BACKGROUND:-none}"      # montage background color
LOG_FILE="${LOG_FILE:-}"              # leave empty to disable file logging

# =============================================================================
# HELPERS
# =============================================================================

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    [[ -n "$LOG_FILE" ]] && echo "$msg" >> "$LOG_FILE"
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
