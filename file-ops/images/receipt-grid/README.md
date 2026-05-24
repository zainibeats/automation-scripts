# Receipt Grid

Combines HEIC, HEIF, JPG, JPEG, and PNG receipt images into one balanced JPG
montage. It processes a local folder of receipt images and writes a single JPG
grid that can be attached to a report, archived, or added to a PDF.

## Dependencies

- Python 3.10+
- `Pillow`
- `pillow-heif`
- `pypdf[crypto]`

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

# Raise the batch limit for an unusually large receipt set
python file-ops/images/receipt-grid/receipt-grid.py ~/Pictures/receipts --max-images 60
```

## Append the grid to a PDF

Append the montage as the final US Letter page of an existing PDF:

```bash
python file-ops/images/receipt-grid/append-receipt-page.py ~/Desktop/firstname-expenses_date.jpg
```

The append script looks for `AX_CON_EXP.pdf` in the current user's Downloads
folder by default. Use `--pdf` to choose a different input PDF.

By default, the final PDF uses the image name with a `.pdf` extension:

```text
~/Desktop/firstname-expenses_date.pdf
```

The montage image is preserved. The appended page keeps the image aspect ratio,
centers it on a white page, and never crops or stretches receipts.

Choose an explicit output path:

```bash
python file-ops/images/receipt-grid/append-receipt-page.py ~/Desktop/firstname-expenses_date.jpg -o ~/Desktop/final.pdf
```

Choose a different input PDF location:

```bash
python file-ops/images/receipt-grid/append-receipt-page.py ~/Desktop/firstname-expenses_date.jpg --pdf ~/Desktop/AX_CON_EXP.pdf
```

Existing output files are not replaced unless `--overwrite` is passed.

The append script can handle unencrypted PDFs and owner-restricted PDFs that
open with an empty password. PDFs that require a user password are not
supported. The default input PDF limit is 10 pages; raise it only when larger
files are expected:

```bash
python file-ops/images/receipt-grid/append-receipt-page.py ~/Desktop/firstname-expenses_date.jpg --max-pdf-pages 20
```

## Behavior

- Accepts `.heic`, `.heif`, `.jpg`, `.jpeg`, and `.png` receipt images up to
  the default safety limit of 40 images.
- Only scans files directly inside the input folder. Subfolders are ignored.
- Leaves original receipt images untouched and does not keep converted copies.
- Builds balanced grids such as `1x1`, `2x1`, `2x2`, `3x2`, `3x3`, and `4x3`.
- Always writes the montage as JPG.
- Uses a white background.
- Replaces generated image/PDF files atomically, so an interrupted run is less
  likely to leave a partial final output.
- Fails clearly when inputs exceed configured safety limits. Use
  `--max-images`, `--max-image-pixels`, `--max-output-pixels`, or
  `--max-pdf-pages` to raise a limit for larger trusted inputs.
