#!/usr/bin/env bash
# single-dl.sh
# Downloads a single video from a URL file with yt-dlp.
# Requires: yt-dlp with curl-cffi → pip install "yt-dlp[default,curl-cffi]"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
fi

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [URL_FILE]

Download a single URL listed in URL_FILE.

Options:
  -u, --url-file FILE     File containing one URL
  -o, --output-dir DIR    Download directory
  -q, --quality VALUE     best, 1080, 720, 480, audio
      --media-type VALUE  Fallback naming label
      --auto-subs BOOL    true or false
      --use-title BOOL    true or false
  -h, --help              Show this help message

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

URL_FILE="${URL_FILE:-$HOME/Documents/url.txt}"
OUTPUT_DIR="${OUTPUT_DIR:-}"
MEDIA_TYPE="${MEDIA_TYPE:-Episode}"       # Fallback naming label: Episode, Part, etc.
QUALITY="${QUALITY:-1080}"                # Options: "best", "1080", "720", "480", "audio"
AUTO_SUBS="${AUTO_SUBS:-true}"            # "true" or "false"
USE_TITLE="${USE_TITLE:-true}"            # "true" = use video title, "false" = MEDIA_TYPE numbering

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--url-file)    require_value "$@"; URL_FILE="$2"; shift 2 ;;
        -o|--output-dir)  require_value "$@"; OUTPUT_DIR="$2"; shift 2 ;;
        -q|--quality)     require_value "$@"; QUALITY="$2"; shift 2 ;;
        --media-type)     require_value "$@"; MEDIA_TYPE="$2"; shift 2 ;;
        --auto-subs)      require_value "$@"; AUTO_SUBS="$2"; shift 2 ;;
        --use-title)      require_value "$@"; USE_TITLE="$2"; shift 2 ;;
        -h|--help)        usage; exit 0 ;;
        -*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            URL_FILE="$1"
            shift
            ;;
    esac
done

BASE_NAME=$(basename "$URL_FILE" .txt)
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Downloads/$BASE_NAME}"
ARCHIVE_FILE="$OUTPUT_DIR/.archive"       # Tracks completed downloads for resume

# Map quality to yt-dlp format string
case "$QUALITY" in
    best)  FORMAT="bestvideo+bestaudio/best" ;;
    1080)  FORMAT="bestvideo[height<=1080]+bestaudio/best" ;;
    720)   FORMAT="bestvideo[height<=720]+bestaudio/best" ;;
    480)   FORMAT="bestvideo[height<=480]+bestaudio/best" ;;
    audio) FORMAT="bestaudio/best" ;;
    *)     echo "Invalid QUALITY: $QUALITY"; exit 1 ;;
esac

# Build subtitle flags
SUB_FLAGS=()
if [[ "$AUTO_SUBS" == "true" ]]; then
    SUB_FLAGS+=(--write-auto-sub)
fi

# Shared yt-dlp options
YT_OPTS=(
    --download-archive "$ARCHIVE_FILE"
    -f "$FORMAT"
    "${SUB_FLAGS[@]}"
    --impersonate chrome
    --extractor-args "generic:impersonate"
    --retries 10
    --fragment-retries 10
    --retry-sleep 5
    --file-access-retries 3
)

mkdir -p "$OUTPUT_DIR"

# Build the output template based on USE_TITLE
get_output_template() {
    if [[ "$USE_TITLE" == "true" ]]; then
        echo "$OUTPUT_DIR/%(title)s.%(ext)s"
    else
        # Numbered naming
        echo "__NUMBERED__"
    fi
}

# Find next available number for fallback/numbered mode
next_number() {
    local max=0
    shopt -s nullglob
    for f in "$OUTPUT_DIR/${BASE_NAME}_${MEDIA_TYPE}_"*.*; do
        num=$(echo "$f" | grep -oP "(?<=${MEDIA_TYPE}_)\d+")
        [[ "$num" -gt "$max" ]] && max=$num
    done
    printf "%02d" $((max + 1))
}

# Read the single URL from the file
URL=$(< "$URL_FILE")
if [[ -z "$URL" ]]; then
    echo "Error: $URL_FILE is empty or missing."
    exit 1
fi

tmpl=$(get_output_template)

if [[ "$tmpl" == "__NUMBERED__" ]]; then
    # Numbered mode
    ep=$(next_number)
    echo ">>> Downloading as ${MEDIA_TYPE}_${ep}: $URL"
    yt-dlp "${YT_OPTS[@]}" \
        -o "$OUTPUT_DIR/${BASE_NAME}_${MEDIA_TYPE}_${ep}.%(ext)s" \
        "$URL"
else
    # Title mode with numbered fallback
    echo ">>> Downloading: $URL"
    yt-dlp "${YT_OPTS[@]}" -o "$tmpl" "$URL"

    if [[ $? -ne 0 ]]; then
        ep=$(next_number)
        echo ">>> Title failed, falling back to ${MEDIA_TYPE}_${ep}"
        yt-dlp "${YT_OPTS[@]}" \
            -o "$OUTPUT_DIR/${BASE_NAME}_${MEDIA_TYPE}_${ep}.%(ext)s" \
            "$URL"
    fi
fi

echo ">>> Done."
