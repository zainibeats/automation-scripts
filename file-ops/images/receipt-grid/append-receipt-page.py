#!/usr/bin/env python3
"""Append a receipt montage image as the last page of a PDF."""

from __future__ import annotations

import argparse
import sys
import tempfile
from pathlib import Path


LETTER_SIZE_INCHES = (8.5, 11.0)
SUPPORTED_IMAGE_EXTENSIONS = {".jpg", ".jpeg"}
DEFAULT_MAX_IMAGE_PIXELS = 80_000_000
DEFAULT_MAX_PDF_PAGES = 10
DEFAULT_PDF_PATH = Path.home() / "Downloads" / "AX_CON_EXP.pdf"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Append a montage image as a US Letter page at the end of a PDF."
    )
    parser.add_argument("image", help="Receipt montage image to append as the last page.")
    parser.add_argument(
        "--pdf",
        default=str(DEFAULT_PDF_PATH),
        help=(
            "Downloaded PDF to append to. Defaults to "
            f"{DEFAULT_PDF_PATH}."
        ),
    )
    parser.add_argument(
        "-o",
        "--output",
        help=(
            "Final PDF path. Defaults to the image filename with a .pdf extension "
            "in the same folder as the image."
        ),
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
    parser.add_argument(
        "--max-image-pixels",
        type=int,
        default=DEFAULT_MAX_IMAGE_PIXELS,
        help=(
            "Maximum pixels allowed in the montage image. "
            f"Defaults to {DEFAULT_MAX_IMAGE_PIXELS}."
        ),
    )
    parser.add_argument(
        "--max-pdf-pages",
        type=int,
        default=DEFAULT_MAX_PDF_PAGES,
        help=f"Maximum pages allowed in the input PDF. Defaults to {DEFAULT_MAX_PDF_PAGES}.",
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
    dpi: int,
    max_image_pixels: int,
) -> None:
    from PIL import Image, ImageOps, UnidentifiedImageError

    width_inches, height_inches = LETTER_SIZE_INCHES
    page_width = round(width_inches * dpi)
    page_height = round(height_inches * dpi)

    try:
        with Image.open(image_path) as image:
            image = ImageOps.exif_transpose(image)
            image_pixels = image.width * image.height
            if image_pixels > max_image_pixels:
                fail(
                    f"{image_path} is {image_pixels:,} pixels, above "
                    f"--max-image-pixels ({max_image_pixels:,}). Resize it or raise the limit."
                )
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
    except (OSError, UnidentifiedImageError, Image.DecompressionBombError) as exc:
        fail(f"Could not read image {image_path}: {exc}")


def write_pdf_atomically(writer: object, output_pdf: Path) -> None:
    output_pdf.parent.mkdir(parents=True, exist_ok=True)
    temp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=output_pdf.parent,
            prefix=f".{output_pdf.name}.",
            suffix=".pdf",
            delete=False,
        ) as temp_file:
            temp_path = Path(temp_file.name)
            writer.write(temp_file)  # type: ignore[attr-defined]
        temp_path.replace(output_pdf)
    except Exception as exc:
        if temp_path is not None:
            temp_path.unlink(missing_ok=True)
        fail(f"Could not write output PDF {output_pdf}: {exc}")


def append_pdf_page(
    source_pdf: Path,
    image_page_pdf: Path,
    output_pdf: Path,
    max_pdf_pages: int,
) -> int:
    from pypdf import PdfReader, PdfWriter

    try:
        source_reader = PdfReader(str(source_pdf))
        image_reader = PdfReader(str(image_page_pdf))
    except Exception as exc:
        fail(f"Could not read PDF input: {exc}")

    if source_reader.is_encrypted:
        fail("Input PDF is encrypted. This workflow expects the downloaded PDF to be unencrypted.")

    source_page_count = len(source_reader.pages)
    if source_page_count < 1:
        fail(f"Input PDF has no pages: {source_pdf}")
    if source_page_count > max_pdf_pages:
        fail(
            f"Input PDF has {source_page_count} pages, above --max-pdf-pages "
            f"({max_pdf_pages}). Raise the limit if this is expected."
        )
    if len(image_reader.pages) != 1:
        fail(f"Internal image page PDF should have one page, found {len(image_reader.pages)}.")

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

    write_pdf_atomically(writer, output_pdf)

    return len(writer.pages)


def main() -> None:
    args = parse_args()
    if args.max_image_pixels < 1:
        fail("--max-image-pixels must be positive")
    if args.max_pdf_pages < 1:
        fail("--max-pdf-pages must be positive")

    from PIL import Image

    Image.MAX_IMAGE_PIXELS = args.max_image_pixels

    pdf_path = existing_file(args.pdf, "PDF")
    image_path = existing_file(args.image, "Image")
    output_path = resolve_output_path(args.output, image_path)

    validate_args(pdf_path, image_path, output_path, args.dpi, args.overwrite)

    with tempfile.TemporaryDirectory() as temp_dir:
        image_page_pdf = Path(temp_dir) / "receipt-page.pdf"
        make_contained_image_pdf(
            image_path,
            image_page_pdf,
            args.dpi,
            args.max_image_pixels,
        )
        page_count = append_pdf_page(
            pdf_path,
            image_page_pdf,
            output_path,
            args.max_pdf_pages,
        )

    print(f"wrote: {output_path}")
    print(f"pages: {page_count}")


if __name__ == "__main__":
    main()
