#!/bin/bash

# ssh-wav-mp3.sh
# Purpose: Transfer WAV and MP3 files to a remote server using rsync over SSH

# Configuration variables
# Source directory containing audio files to transfer
SOURCE_DIR="/path/to/source/folder"

# Remote destination in format: user@host:/path
# Ensure SSH key-based authentication is configured
DEST_SSH="user@192.xxx.x.xx:/destination/folder"

# Validate source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist"
    exit 1
fi

# Display transfer information
echo "Copying music files from: $SOURCE_DIR"
echo "To remote destination: $DEST_SSH"
echo "(Skipping files that exist and are unchanged)"

# Execute rsync with optimized settings
# Flags:
#   -r: recursive
#   -v: verbose output
#   -u: skip files newer on receiver
#   -i: output a change-summary for all updates
#   --progress: show progress during transfer
#   --include/exclude: filter rules for file selection
#   --compress: compress during transfer
#   --partial: keep partially transferred files
rsync \
    -r \
    -v \
    -u \
    -i \
    --progress \
    --include='*/' \
    --include='*.mp3' \
    --include='*.wav' \
    --exclude='*' \
    --compress \
    --compress-level=9 \
    --partial \
    --stats \
    "${SOURCE_DIR}/" \
    "${DEST_SSH}"

# Check transfer status and report results
status=$?
if [ $status -eq 0 ]; then
    echo "Transfer complete!"
else
    echo "Error: Transfer failed with status $status"
    exit 1
fi 
