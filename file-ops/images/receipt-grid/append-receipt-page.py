#!/usr/bin/env python3
"""Append a receipt montage image as the last page of a PDF."""

from __future__ import annotations

import argparse
import sys
import tempfile
from pathlib import Path


PAPER_SIZES_INCHES = {
    "letter": (8.5, 11.0),
    "legal": (8.5, 14.0),
    "a4": (8.27, 11.69),
}

SUPPORTED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".tif", ".tiff", ".bmp"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Append a montage image as a US Letter page at the end of a PDF."
    )
    parser.add_argument("pdf", help="Manually downloaded PDF to append to.")
    parser.add_argument("image", help="Receipt montage image to append as the last page.")
    parser.add_argument(
        "-o",
        "--output",
        help=(
            "Final PDF path. Defaults to the image filename with a .pdf extension "
            "in the same folder as the image."
        ),
    )
    parser.add_argument(
        "--paper-size",
        choices=sorted(PAPER_SIZES_INCHES),
        default="letter",
        help="Page size for the appended image page. Defaults to letter.",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=200,
        help="Raster resolution for the appended image page. Defaults to 200.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite the output PDF if it already exists.",
    )
    return parser.parse_args()


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def existing_file(path: str, label: str) -> Path:
    resolved = Path(path).expanduser().resolve()
    if not resolved.is_file():
        fail(f"{label} does not exist: {resolved}")
    return resolved


def default_output_path(image_path: Path) -> Path:
    return image_path.with_suffix(".pdf")


def resolve_output_path(output: str | None, image_path: Path) -> Path:
    if output is None:
        return default_output_path(image_path)
    return Path(output).expanduser().resolve()


def validate_args(
    pdf_path: Path,
    image_path: Path,
    output_path: Path,
    dpi: int,
    overwrite: bool,
) -> None:
    if pdf_path.suffix.lower() != ".pdf":
        fail(f"Input PDF must end with .pdf: {pdf_path}")
    if image_path.suffix.lower() not in SUPPORTED_IMAGE_EXTENSIONS:
        fail(
            "Image must be one of: "
            + ", ".join(sorted(SUPPORTED_IMAGE_EXTENSIONS))
            + f" ({image_path})"
        )
    if output_path.suffix.lower() != ".pdf":
        fail(f"Output path must end with .pdf: {output_path}")
    if output_path == pdf_path:
        fail("Output path cannot be the same as the input PDF.")
    if output_path.exists() and not overwrite:
        fail(f"Output already exists. Pass --overwrite to replace it: {output_path}")
    if dpi < 72 or dpi > 600:
        fail("--dpi must be between 72 and 600")


def make_contained_image_pdf(
    image_path: Path,
    pdf_path: Path,
    paper_size: str,
    dpi: int,
) -> None:
    try:
        from PIL import Image, ImageOps, UnidentifiedImageError
    except ImportError:
        fail(
            "Missing Pillow. Install dependencies with "
            "'python -m pip install -r requirements.txt'."
        )

    width_inches, height_inches = PAPER_SIZES_INCHES[paper_size]
    page_width = round(width_inches * dpi)
    page_height = round(height_inches * dpi)

    try:
        with Image.open(image_path) as image:
            image = ImageOps.exif_transpose(image)
            if image.mode in ("RGBA", "LA") or (
                image.mode == "P" and "transparency" in image.info
            ):
                background = Image.new("RGB", image.size, "white")
                alpha = image.convert("RGBA").split()[-1]
                background.paste(image.convert("RGB"), mask=alpha)
                image = background
            elif image.mode != "RGB":
                image = image.convert("RGB")

            image.thumbnail((page_width, page_height), Image.Resampling.LANCZOS)
            page = Image.new("RGB", (page_width, page_height), "white")
            x = (page_width - image.width) // 2
            y = (page_height - image.height) // 2
            page.paste(image, (x, y))
            page.save(pdf_path, "PDF", resolution=dpi)
    except (OSError, UnidentifiedImageError) as exc:
        fail(f"Could not read image {image_path}: {exc}")


def append_pdf_page(source_pdf: Path, image_page_pdf: Path, output_pdf: Path) -> int:
    try:
        from pypdf import PdfReader, PdfWriter
    except ImportError:
        fail(
            "Missing pypdf. Install dependencies with "
            "'python -m pip install -r requirements.txt'."
        )

    try:
        source_reader = PdfReader(str(source_pdf))
        image_reader = PdfReader(str(image_page_pdf))
    except Exception as exc:
        fail(f"Could not read PDF input: {exc}")

    if source_reader.is_encrypted:
        try:
            source_reader.decrypt("")
        except Exception as exc:
            fail(f"Input PDF is encrypted and could not be opened: {exc}")

    writer = PdfWriter()
    for page in source_reader.pages:
        writer.add_page(page)
    writer.add_page(image_reader.pages[0])

    if source_reader.metadata:
        metadata = {
            key: value
            for key, value in source_reader.metadata.items()
            if isinstance(key, str) and isinstance(value, str)
        }
        if metadata:
            writer.add_metadata(metadata)

    output_pdf.parent.mkdir(parents=True, exist_ok=True)
    try:
        with output_pdf.open("wb") as output_file:
            writer.write(output_file)
    except OSError as exc:
        fail(f"Could not write output PDF {output_pdf}: {exc}")

    return len(writer.pages)


def main() -> None:
    args = parse_args()
    pdf_path = existing_file(args.pdf, "PDF")
    image_path = existing_file(args.image, "Image")
    output_path = resolve_output_path(args.output, image_path)

    validate_args(pdf_path, image_path, output_path, args.dpi, args.overwrite)

    with tempfile.TemporaryDirectory() as temp_dir:
        image_page_pdf = Path(temp_dir) / "receipt-page.pdf"
        make_contained_image_pdf(image_path, image_page_pdf, args.paper_size, args.dpi)
        page_count = append_pdf_page(pdf_path, image_page_pdf, output_path)

    print(f"wrote: {output_path}")
    print(f"pages: {page_count}")


if __name__ == "__main__":
    main()
