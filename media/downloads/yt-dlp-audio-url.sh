#!/bin/bash

# yt-dlp-audio-url.sh
# Purpose: Download audio from URLs listed in a text file,
#          name each file after its track identifier, and convert to MP3.

# Text file containing one URL per line
URL_FILE="/path/to/text/file.txt"

# Target directory for downloaded MP3s
DOWNLOAD_DIR="/path/to/ytdlp-output"

# Ensure download directory exists
mkdir -p "$DOWNLOAD_DIR"

# Read each URL and process
while IFS= read -r url; do
    # Extract the filename portion, e.g. "converted_tired-eyes-...-stream..."
    base=$(basename "$url")
    
    # Strip "converted_" prefix and "-stream..." suffix to get the track name
    title=$(echo "$base" \
        | sed -e 's/^converted_//' \
              -e 's/-stream.*//')
    
    # Download and convert directly to MP3, naming it after the track
    yt-dlp \
      --extract-audio \
      --audio-format mp3 \
      -o "$DOWNLOAD_DIR/${title}.%(ext)s" \
      "$url"
done < "$URL_FILE"

