#!/bin/bash
# batch-dl.sh
# Downloads URLs from a text file (supports both individual links and playlists).
# Requires: yt-dlp with curl-cffi → pip install "yt-dlp[default,curl-cffi]"

# --- Config ---
URL_FILE="$HOME/Documents/playlist.txt"
BASE_NAME=$(basename "$URL_FILE" .txt)
OUTPUT_DIR="$HOME/Downloads/$BASE_NAME"
ARCHIVE_FILE="$OUTPUT_DIR/.archive"       # Tracks completed downloads for resume
MEDIA_TYPE="Episode"                       # Fallback naming label: Episode, Part, etc.
QUALITY="1080"      # Options: "best", "1080", "720", "480", "audio"
AUTO_SUBS="true"    # "true" or "false"
USE_TITLE="true"    # "true" = use video title, "false" = use MEDIA_TYPE numbering

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
    --downloader ffmpeg
    --hls-use-mpegts
    --impersonate chrome
    --extractor-args "generic:impersonate"
)

mkdir -p "$OUTPUT_DIR"

# Build the output template based on USE_TITLE and whether it's a playlist
get_output_template() {
    local is_pl="$1"
    if [[ "$USE_TITLE" == "true" ]]; then
        if [[ "$is_pl" == "true" ]]; then
            # Playlist: prepend index to title
            echo "$OUTPUT_DIR/%(playlist_index)02d - %(title)s.%(ext)s"
        else
            echo "$OUTPUT_DIR/%(title)s.%(ext)s"
        fi
    else
        # Original numbered naming
        if [[ "$is_pl" == "true" ]]; then
            echo "$OUTPUT_DIR/${BASE_NAME}_${MEDIA_TYPE}_%(playlist_index)02d.%(ext)s"
        else
            echo "__NUMBERED__"
        fi
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

# Check if URL looks like a playlist
is_playlist() {
    [[ "$1" == *"list="* || "$1" == *"/playlist"* ]]
}

# Read from fd3 so yt-dlp/ffmpeg don't consume stdin
while IFS= read -r url <&3; do
    [[ -z "$url" || "$url" == \#* ]] && continue

    if is_playlist "$url"; then
        tmpl=$(get_output_template "true")
        echo ">>> Playlist detected: $url"
        yt-dlp "${YT_OPTS[@]}" -o "$tmpl" "$url"
    else
        tmpl=$(get_output_template "false")

        if [[ "$tmpl" == "__NUMBERED__" ]]; then
            # Numbered mode for individual URLs
            ep=$(next_number)
            echo ">>> Downloading as ${MEDIA_TYPE}_${ep}: $url"
            yt-dlp "${YT_OPTS[@]}" \
                -o "$OUTPUT_DIR/${BASE_NAME}_${MEDIA_TYPE}_${ep}.%(ext)s" \
                "$url"
        else
            # Title mode with numbered fallback
            echo ">>> Downloading: $url"
            yt-dlp "${YT_OPTS[@]}" -o "$tmpl" "$url"

            if [[ $? -ne 0 ]]; then
                ep=$(next_number)
                echo ">>> Title failed, falling back to ${MEDIA_TYPE}_${ep}"
                yt-dlp "${YT_OPTS[@]}" \
                    -o "$OUTPUT_DIR/${BASE_NAME}_${MEDIA_TYPE}_${ep}.%(ext)s" \
                    "$url"
            fi
        fi
    fi
done 3< "$URL_FILE"

echo ">>> Done."
