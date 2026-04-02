#!/bin/bash
# yt-dl-single.sh
# Downloads a single video with yt-dlp.
# Usage: ./yt-dl-single.sh <url> [filename]
# Requires: yt-dlp with curl-cffi → pip install "yt-dlp[default,curl-cffi]"

# --- Config ---
URL_FILE="$HOME/Documents/url"
OUTPUT_DIR="$HOME/Downloads/yt-downloads"
QUALITY="1080"      # Options: "best", "1080", "720", "480", "audio"
AUTO_SUBS="true"    # "true" or "false"

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

mkdir -p "$OUTPUT_DIR"

# Require at least a URL
if [[ -z "$1" ]]; then
    echo "Usage: $0 <url> [filename]"
    exit 1
fi

URL="$1"
# Default to video title, override with optional second argument
FILENAME="${2:-%(title)s}"

yt-dlp \
    -f "$FORMAT" \
    "${SUB_FLAGS[@]}" \
    --downloader ffmpeg \
    --hls-use-mpegts \
    --impersonate chrome \
    --extractor-args "generic:impersonate" \
    -o "$OUTPUT_DIR/${FILENAME}.%(ext)s" \
    "$URL"

echo ">>> Done."
