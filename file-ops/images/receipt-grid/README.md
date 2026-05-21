# Receipt Grid

Converts HEIC/HEIF receipt images to JPG when needed and combines receipt
images into one balanced grid image. This is the preferred cross-platform
receipt workflow for Windows, macOS, and Linux.

## Dependencies

- Python 3.10+
- `Pillow`
- `pillow-heif`

## Install

Install dependencies in a standard Python virtual environment.

Windows PowerShell:

```powershell
cd path\to\this\repo
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r file-ops\images\receipt-grid\requirements.txt
```

If Windows blocks the `Activate.ps1` step, enable running local PowerShell
scripts first. Open Windows Settings, search for `PowerShell`, and turn on the
developer setting that allows local PowerShell scripts to run without signing.
Then close and reopen PowerShell and run the commands above again.

macOS or Linux:

```bash
cd /path/to/this/repo
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r file-ops/images/receipt-grid/requirements.txt
```

## Run

Run from the repo root:

```bash
python file-ops/images/receipt-grid/receipt-grid.py ~/Pictures/receipts
```

## Examples

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

## Behavior

- Accepts any number of `.heic`, `.heif`, `.jpg`, `.jpeg`, `.png`, `.webp`,
  `.tif`, `.tiff`, and `.bmp` files.
- Leaves original HEIC/HEIF files untouched.
- Writes converted JPG files to `converted/` inside the input folder by default.
- Uses existing JPG/PNG/WebP/TIFF/BMP files directly in the grid without
  converting them first.
- Builds balanced grids such as `1x2`, `2x2`, `2x3`, `2x4`, `3x4`, and `4x4`.
- Uses JPG output by default.
- Uses a black background by default.
