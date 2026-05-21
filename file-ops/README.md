# File Operations

Scripts for local file and media manipulation.

## Image Utilities

### `images/receipt-grid/receipt-grid.py`

Converts HEIC/HEIF receipt images to JPG when needed and combines receipt
images into one balanced grid image. This is the preferred cross-platform
receipt workflow for Windows, macOS, and Linux.

Dependencies:

- Python 3.10+
- `Pillow`
- `pillow-heif`

Install dependencies with either:

```bash
python -m pip install -r file-ops/images/receipt-grid/requirements.txt
```

or:

```bash
uv pip install -r file-ops/images/receipt-grid/requirements.txt
```

Run from the repo root:

```bash
python file-ops/images/receipt-grid/receipt-grid.py ~/Pictures/receipts
```

Common examples:

```bash
# Write a JPG grid to the input folder as weekly-receipts.jpg
python file-ops/images/receipt-grid/receipt-grid.py ~/Pictures/receipts

# Choose the final output path
python file-ops/images/receipt-grid/receipt-grid.py ~/Pictures/receipts -o ~/Desktop/receipts.jpg

# Search subfolders too
python file-ops/images/receipt-grid/receipt-grid.py ~/Pictures/receipts --recursive

# Build a grid only from existing JPG/PNG/WebP/TIFF/BMP files
python file-ops/images/receipt-grid/receipt-grid.py ~/Pictures/receipts --no-convert

# Convert HEIC/HEIF files to JPG and stop before building the grid
python file-ops/images/receipt-grid/receipt-grid.py ~/Pictures/receipts --convert-only

# PNG output is supported by using a .png filename
python file-ops/images/receipt-grid/receipt-grid.py ~/Pictures/receipts -o weekly-receipts.png
```

Behavior:

- Accepts any number of `.heic`, `.heif`, `.jpg`, `.jpeg`, `.png`, `.webp`,
  `.tif`, `.tiff`, and `.bmp` files.
- Leaves original HEIC/HEIF files untouched.
- Writes converted JPG files to `converted/` inside the input folder by default.
- Uses existing JPG/PNG/WebP/TIFF/BMP files directly in the grid without
  converting them first.
- Builds balanced grids such as `1x2`, `2x2`, `2x3`, `2x4`, `3x4`, and `4x4`.
- Uses JPG output by default.
- Uses a black background by default.

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
