#!/bin/bash
# append-mp3.sh
# Purpose: Append .mp3 extension to all files in a directory
# Requirements: Bash shell environment and write permissions
#
# Features:
#   - Processes all files in target directory
#   - Adds .mp3 extension to each file
#   - Skips directories and special files
#   - Simple error handling for directory validation

# --- Configuration ---
# Edit the following constant to your desired directory full of files.
TARGET_DIR="/Path/To/Your/Folder"

# --- Check if directory exists ---
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

# --- Change to the target directory ---
cd "$TARGET_DIR" || exit

# --- Process each file ---
for file in *; do
    # Only proceed if it is a regular file.
    if [ -f "$file" ]; then
        # Append .mp3 to the filename.
        mv -- "$file" "$file.mp3"
    fi
done

echo "Finished renaming files."

