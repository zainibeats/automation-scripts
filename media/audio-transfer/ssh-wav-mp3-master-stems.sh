#!/bin/bash

# ssh-wav-mp3-master-stems.sh
# Purpose: Transfer WAV/MP3 files to remote server with special handling for master/stem files

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
echo "(Skipping stem/stems files unless they contain 'master')"

# Execute rsync with optimized settings and stem file handling
# Flags:
#   -r: recursive
#   -v: verbose output
#   -u: skip files newer on receiver
#   -i: output a change-summary for all updates
#   --progress: show progress during transfer
#
# Include/Exclude Rules (processed in order):
# 1. Include master stem files (various naming patterns)
# 2. Exclude all other stem files
# 3. Include remaining WAV/MP3 files
# 4. Exclude everything else
rsync \
    -r \
    -v \
    -u \
    -i \
    --progress \
    --include='*/' \
    --include='*[Mm]aster*[Ss][Tt][Ee][Mm][Ss]*.mp3' \
    --include='*[Mm]aster*[Ss][Tt][Ee][Mm]*.mp3' \
    --include='*[Mm]aster*[Ss][Tt][Ee][Mm][Ss]*.wav' \
    --include='*[Mm]aster*[Ss][Tt][Ee][Mm]*.wav' \
    --exclude='*[Ss][Tt][Ee][Mm][Ss]*.mp3' \
    --exclude='*[Ss][Tt][Ee][Mm]*.mp3' \
    --exclude='*[Ss][Tt][Ee][Mm][Ss]*.wav' \
    --exclude='*[Ss][Tt][Ee][Mm]*.wav' \
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
