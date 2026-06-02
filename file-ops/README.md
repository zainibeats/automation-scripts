# File Operations

Scripts for local file and media manipulation.

## Image Utilities

### Receipt PDF Tools

Tools for preparing weekly receipt attachments. The scripts can combine receipt
images into a single JPG grid and optionally append that grid image to the end of
an existing PDF.

This toolset was moved into its own repository because it grew beyond a simple
one-file utility.

Repository: [image-pdf-tools](https://github.com/zainibeats/image-pdf-tools)

### `images/heic-to-jpg.sh`

Batch converts HEIC/HEIF images to JPEG. Supports recursive scanning,
configurable output quality, skipping already-converted files, and optionally
moving originals to an archive directory.

Dependencies:

- `heif-convert`
- Debian/Ubuntu: `sudo apt install libheif-examples`
- macOS: `brew install libheif`

Common configuration values are at the top of the script:

- `INPUT_DIR`
- `OUTPUT_DIR`
- `RECURSIVE`
- `OVERWRITE`
- `QUALITY`
- `MOVE_ORIGINALS`
- `ARCHIVE_DIR`

### `images/montage.sh`

Generates a single composite image from a directory of images using
ImageMagick's `montage`.

Dependencies:

- `montage`
- Debian/Ubuntu: `sudo apt install imagemagick`
- macOS: `brew install imagemagick`

Common configuration values are at the top of the script:

- `INPUT_DIR`
- `OUTPUT_FILE`
- `TILE`
- `GEOMETRY`
- `EXTENSION`
- `BACKGROUND`

### `images/resize_media.bat`

Windows batch script for recursively resizing images while preserving quality.
It prompts for the target directory, resize percentage, and file type.

Dependencies:

- Windows
- ImageMagick on `PATH`
- Read/write permissions in the target directory

Run:

```batch
resize_media.bat
```

Notes:

- Original files are modified in place.
- Supported file types are GIF, PNG, JPG, and JPEG.
- Use `all` at the file type prompt to process every supported format.

## Renaming

### `renaming/rename-from-list.ps1`

PowerShell script for batch renaming files using names from a text file. It
matches files in alphabetical order, preserves extensions, and can ignore
metadata after commas in the names list.

Configure these variables before running:

- `$namesFilePath`
- `$targetFolderPath`
- `$fileFilter`
