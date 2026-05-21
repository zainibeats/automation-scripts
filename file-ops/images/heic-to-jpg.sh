#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIG — edit these variables before running
# =============================================================================

INPUT_DIR="${INPUT_DIR:-$HOME/Pictures}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Pictures/converted}"
RECURSIVE="${RECURSIVE:-true}"
OVERWRITE="${OVERWRITE:-false}"
QUALITY="${QUALITY:-90}"
MOVE_ORIGINALS="${MOVE_ORIGINALS:-false}"
ARCHIVE_DIR="${ARCHIVE_DIR:-$HOME/Pictures/originals}"
LOG_FILE="${LOG_FILE:-}"          # leave empty to disable file logging

# =============================================================================
# INTERNAL — do not edit below
# =============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
CONVERTED=0
SKIPPED=0
FAILED=0

# -----------------------------------------------------------------------------
# Logging helpers
# -----------------------------------------------------------------------------

log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '[%s] [%s] %s\n' "$ts" "$level" "$msg"
    if [[ -n "$LOG_FILE" ]]; then
        printf '[%s] [%s] %s\n' "$ts" "$level" "$msg" >> "$LOG_FILE"
    fi
}

info()  { log "INFO " "$@"; }
warn()  { log "WARN " "$@"; }
error() { log "ERROR" "$@" >&2; }
die()   { error "$@"; exit 1; }

# -----------------------------------------------------------------------------
# check_dependencies — abort early if required tools are missing
# -----------------------------------------------------------------------------

check_dependencies() {
    if ! command -v heif-convert &>/dev/null; then
        die "'heif-convert' is not installed or not on PATH. " \
            "Install it via: sudo apt install libheif-examples  (Debian/Ubuntu) " \
            "or: brew install libheif  (macOS)"
    fi
}

# -----------------------------------------------------------------------------
# prepare_directories — validate input, create output/archive dirs as needed
# -----------------------------------------------------------------------------

prepare_directories() {
    if [[ ! -d "$INPUT_DIR" ]]; then
        die "Input directory does not exist: $INPUT_DIR"
    fi

    if [[ ! -d "$OUTPUT_DIR" ]]; then
        info "Creating output directory: $OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR"
    fi

    if [[ "$MOVE_ORIGINALS" == "true" && ! -d "$ARCHIVE_DIR" ]]; then
        info "Creating archive directory: $ARCHIVE_DIR"
        mkdir -p "$ARCHIVE_DIR"
    fi

    if [[ -n "$LOG_FILE" ]]; then
        local log_dir
        log_dir="$(dirname "$LOG_FILE")"
        [[ -d "$log_dir" ]] || mkdir -p "$log_dir"
    fi
}

# -----------------------------------------------------------------------------
# build_output_path — derive the destination .jpg path for a given source file
#   $1 — absolute path to source HEIC/HEIF file
# -----------------------------------------------------------------------------

build_output_path() {
    local src="$1"
    local base_name
    base_name="$(basename "${src%.*}")"

    # Preserve sub-directory structure relative to INPUT_DIR when OUTPUT_DIR
    # differs from INPUT_DIR; otherwise place files flat in OUTPUT_DIR.
    if [[ "$OUTPUT_DIR" != "$INPUT_DIR" ]]; then
        local rel_dir
        rel_dir="$(dirname "${src#"$INPUT_DIR"/}")"
        if [[ "$rel_dir" == "." ]]; then
            printf '%s/%s.jpg' "$OUTPUT_DIR" "$base_name"
        else
            printf '%s/%s/%s.jpg' "$OUTPUT_DIR" "$rel_dir" "$base_name"
        fi
    else
        printf '%s/%s.jpg' "$(dirname "$src")" "$base_name"
    fi
}

# -----------------------------------------------------------------------------
# convert_file — convert a single HEIC/HEIF file to JPEG
#   $1 — absolute path to source file
# -----------------------------------------------------------------------------

convert_file() {
    local src="$1"
    local dest
    dest="$(build_output_path "$src")"

    # Ensure the destination sub-directory exists (relevant in recursive mode)
    local dest_dir
    dest_dir="$(dirname "$dest")"
    [[ -d "$dest_dir" ]] || mkdir -p "$dest_dir"

    # Skip if output already exists and OVERWRITE is off
    if [[ -f "$dest" && "$OVERWRITE" != "true" ]]; then
        info ">>> Skipping (exists): $(basename "$dest")"
        (( SKIPPED++ )) || true
        return 0
    fi

    info ">>> Converting: $(basename "$src")"

    # heif-convert flags: -q <quality> <src> <dest>
    if heif-convert -q "$QUALITY" "$src" "$dest" &>/dev/null; then
        (( CONVERTED++ )) || true

        if [[ "$MOVE_ORIGINALS" == "true" ]]; then
            local archive_dest
            archive_dest="$ARCHIVE_DIR/$(basename "$src")"
            mv -- "$src" "$archive_dest"
            info "    Archived original → $archive_dest"
        fi
    else
        warn "    Conversion FAILED: $(basename "$src")"
        # Remove a potentially partial output file
        [[ -f "$dest" ]] && rm -f "$dest"
        (( FAILED++ )) || true
    fi
}

# -----------------------------------------------------------------------------
# collect_files — populate FILES array with all target paths
# -----------------------------------------------------------------------------

collect_files() {
    FILES=()
    local find_args=( "$INPUT_DIR" )

    if [[ "$RECURSIVE" != "true" ]]; then
        find_args+=( -maxdepth 1 )
    fi

    find_args+=( -type f \( -iname "*.heic" -o -iname "*.heif" \) )

    while IFS= read -r -d '' file; do
        FILES+=( "$file" )
    done < <(find "${find_args[@]}" -print0 | sort -z)
}

# -----------------------------------------------------------------------------
# process_files — iterate over collected files and convert each one
# -----------------------------------------------------------------------------

process_files() {
    local total="${#FILES[@]}"

    if (( total == 0 )); then
        info "No HEIC/HEIF files found in: $INPUT_DIR"
        return 0
    fi

    info "Found $total file(s) to process."
    info "Output directory: $OUTPUT_DIR"
    [[ "$RECURSIVE"      == "true"  ]] && info "Mode: recursive"
    [[ "$OVERWRITE"      == "true"  ]] && info "Overwrite: enabled"
    [[ "$MOVE_ORIGINALS" == "true"  ]] && info "Archive originals → $ARCHIVE_DIR"
    printf '\n'

    local i=1
    for file in "${FILES[@]}"; do
        printf '[%d/%d] ' "$i" "$total"
        convert_file "$file"
        (( i++ )) || true
    done
}

# -----------------------------------------------------------------------------
# print_summary — report totals at the end
# -----------------------------------------------------------------------------

print_summary() {
    printf '\n'
    info "========================================="
    info "Done."
    info "  Converted : $CONVERTED"
    info "  Skipped   : $SKIPPED"
    info "  Failed    : $FAILED"
    info "========================================="
    if [[ -n "$LOG_FILE" ]]; then
        info "Log saved to: $LOG_FILE"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    info "Starting $SCRIPT_NAME"
    check_dependencies
    prepare_directories

    declare -a FILES
    collect_files
    process_files
    print_summary

    (( FAILED == 0 ))   # exit 1 if any conversions failed
}

main "$@"
