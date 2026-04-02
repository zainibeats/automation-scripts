#!/bin/bash
# batch-dl.sh
# Downloads URLs from a text file (supports both individual links and playlists).
# Requires: yt-dlp with curl-cffi → pip install "yt-dlp[default,curl-cffi]"

# --- Config ---
URL_FILE="$HOME/Documents/playlist.txt"
BASE_NAME=$(basename "$URL_FILE" .txt)
OUTPUT_DIR="$HOME/Downloads/$BASE_NAME"
ARCHIVE_FILE="$OUTPUT_DIR/.archive"       # Tracks completed downloads for resume
MEDIA_TYPE="Episode"                       # Naming label: Episode, Part, etc.
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

# Check if URL looks like a playlist (contains list= or /playlist)
is_playlist() {
    [[ "$1" == *"list="* || "$1" == *"/playlist"* ]]
}

# Read from fd3 so yt-dlp/ffmpeg don't consume stdin
while IFS= read -r url <&3; do
    # Skip blank lines and comments
    [[ -z "$url" || "$url" == \#* ]] && continue

    if is_playlist "$url"; then
        echo ">>> Playlist detected: $url"
        yt-dlp \
            --download-archive "$ARCHIVE_FILE" \
            -f "$FORMAT" \
            "${SUB_FLAGS[@]}" \
            --downloader ffmpeg \
            --hls-use-mpegts \
            --impersonate chrome \
            --extractor-args "generic:impersonate" \
            -o "$OUTPUT_DIR/${BASE_NAME}_${MEDIA_TYPE}_%(playlist_index)02d.%(ext)s" \
            "$url"
    else
        # Scan existing files to find the next available number
        max=0
        shopt -s nullglob
        for f in "$OUTPUT_DIR/${BASE_NAME}_${MEDIA_TYPE}_"*.*; do
            num=$(echo "$f" | grep -oP "(?<=${MEDIA_TYPE}_)\d+")
            [[ "$num" -gt "$max" ]] && max=$num
        done
        episode=$((max + 1))
        ep=$(printf "%02d" "$episode")

        echo ">>> Downloading as ${MEDIA_TYPE}_${ep}: $url"
        yt-dlp \
            --download-archive "$ARCHIVE_FILE" \
            -f "$FORMAT" \
            "${SUB_FLAGS[@]}" \
            --downloader ffmpeg \
            --hls-use-mpegts \
            --impersonate chrome \
            --extractor-args "generic:impersonate" \
            -o "$OUTPUT_DIR/${BASE_NAME}_${MEDIA_TYPE}_${ep}.%(ext)s" \
            "$url"
    fi
done 3< "$URL_FILE"

echo ">>> Done."
