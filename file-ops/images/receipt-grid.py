#!/usr/bin/env python3
"""Convert receipt images and combine them into a balanced grid."""

from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageOps, UnidentifiedImageError

HEIC_EXTENSIONS = {".heic", ".heif"}
JPEG_EXTENSIONS = {".jpg", ".jpeg"}
SUPPORTED_EXTENSIONS = HEIC_EXTENSIONS | JPEG_EXTENSIONS


@dataclass(frozen=True)
class GridSize:
    rows: int
    columns: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Convert HEIC/HEIF receipts to JPG and combine receipts into a "
            "balanced grid image."
        )
    )
    parser.add_argument(
        "input_dir",
        nargs="?",
        default=".",
        help="Folder containing receipt images. Defaults to the current folder.",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="weekly-receipts.jpg",
        help="Final grid image path. Use .jpg/.jpeg or .png. Defaults to weekly-receipts.jpg.",
    )
    parser.add_argument(
        "--converted-dir",
        default="converted",
        help="Folder for converted JPG files. Relative paths live inside input_dir.",
    )
    parser.add_argument(
        "--quality",
        type=int,
        default=90,
        help="JPEG quality for converted files and JPG grid output. Defaults to 90.",
    )
    parser.add_argument(
        "--cell-width",
        type=int,
        default=1200,
        help="Width of each grid cell in pixels. Defaults to 1200.",
    )
    parser.add_argument(
        "--cell-height",
        type=int,
        default=1600,
        help="Height of each grid cell in pixels. Defaults to 1600.",
    )
    parser.add_argument(
        "--gap",
        type=int,
        default=24,
        help="Spacing between receipts in pixels. Defaults to 24.",
    )
    parser.add_argument(
        "--background",
        default="white",
        help="Grid background color understood by Pillow. Defaults to white.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing converted JPG files.",
    )
    parser.add_argument(
        "--no-convert",
        action="store_true",
        help="Skip HEIC conversion and only use existing JPG/JPEG files.",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Search input_dir recursively.",
    )
    return parser.parse_args()


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def ensure_heif_support() -> None:
    try:
        from pillow_heif import register_heif_opener
    except ImportError:
        fail(
            "HEIC/HEIF files require pillow-heif. Install dependencies with "
            "'python -m pip install -r file-ops/images/requirements-receipts.txt'."
        )

    register_heif_opener()


def normalize_dir(path: str) -> Path:
    directory = Path(path).expanduser().resolve()
    if not directory.is_dir():
        fail(f"Input directory does not exist: {directory}")
    return directory


def resolve_child_path(base: Path, path: str) -> Path:
    candidate = Path(path).expanduser()
    if candidate.is_absolute():
        return candidate.resolve()
    return (base / candidate).resolve()


def collect_images(input_dir: Path, recursive: bool) -> list[Path]:
    iterator: Iterable[Path]
    iterator = input_dir.rglob("*") if recursive else input_dir.iterdir()
    return sorted(
        path
        for path in iterator
        if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS
    )


def is_relative_to(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def build_converted_path(source: Path, input_dir: Path, converted_dir: Path) -> Path:
    relative_parent = source.parent.relative_to(input_dir)
    return converted_dir / relative_parent / f"{source.stem}.jpg"


def save_as_jpeg(source: Path, destination: Path, quality: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as image:
        image = ImageOps.exif_transpose(image)
        if image.mode not in ("RGB", "L"):
            image = image.convert("RGB")
        image.save(destination, "JPEG", quality=quality, optimize=True)


def convert_heic_files(
    sources: list[Path],
    input_dir: Path,
    converted_dir: Path,
    quality: int,
    overwrite: bool,
) -> list[Path]:
    heic_files = [path for path in sources if path.suffix.lower() in HEIC_EXTENSIONS]
    if not heic_files:
        return []

    ensure_heif_support()

    converted: list[Path] = []
    for source in heic_files:
        destination = build_converted_path(source, input_dir, converted_dir)
        if destination.exists() and not overwrite:
            print(f"skip existing: {destination}")
            converted.append(destination)
            continue

        print(f"convert: {source} -> {destination}")
        try:
            save_as_jpeg(source, destination, quality)
        except (OSError, UnidentifiedImageError) as exc:
            fail(f"Could not convert {source}: {exc}")
        converted.append(destination)

    return converted


def balanced_grid_size(count: int) -> GridSize:
    if count < 1:
        fail("No images available for the grid.")
    rows = max(1, math.floor(math.sqrt(count)))
    columns = math.ceil(count / rows)
    return GridSize(rows=rows, columns=columns)


def fit_image(image: Image.Image, cell_width: int, cell_height: int) -> Image.Image:
    image = ImageOps.exif_transpose(image)
    image.thumbnail((cell_width, cell_height), Image.Resampling.LANCZOS)
    if image.mode != "RGB":
        image = image.convert("RGB")
    return image.copy()


def make_grid(
    images: list[Path],
    output: Path,
    cell_width: int,
    cell_height: int,
    gap: int,
    background: str,
    quality: int,
) -> None:
    size = balanced_grid_size(len(images))
    canvas_width = size.columns * cell_width + (size.columns + 1) * gap
    canvas_height = size.rows * cell_height + (size.rows + 1) * gap
    canvas = Image.new("RGB", (canvas_width, canvas_height), background)

    for index, image_path in enumerate(images):
        row = index // size.columns
        column = index % size.columns
        try:
            with Image.open(image_path) as image:
                fitted = fit_image(image, cell_width, cell_height)
        except (OSError, UnidentifiedImageError) as exc:
            fail(f"Could not read {image_path}: {exc}")

        x = gap + column * (cell_width + gap) + (cell_width - fitted.width) // 2
        y = gap + row * (cell_height + gap) + (cell_height - fitted.height) // 2
        canvas.paste(fitted, (x, y))

    output.parent.mkdir(parents=True, exist_ok=True)
    output_format = output.suffix.lower()
    if output_format in {".jpg", ".jpeg"}:
        canvas.save(output, "JPEG", quality=quality, optimize=True)
    elif output_format == ".png":
        canvas.save(output, "PNG", optimize=True)
    else:
        fail("Output file must end with .jpg, .jpeg, or .png")

    print(f"grid: {len(images)} image(s), {size.rows}x{size.columns}, {output}")


def main() -> None:
    args = parse_args()

    if not 1 <= args.quality <= 100:
        fail("--quality must be between 1 and 100")
    if args.cell_width < 1 or args.cell_height < 1:
        fail("--cell-width and --cell-height must be positive")
    if args.gap < 0:
        fail("--gap must be zero or greater")

    input_dir = normalize_dir(args.input_dir)
    output = Path(args.output).expanduser()
    if not output.is_absolute():
        output = (input_dir / output).resolve()
    converted_dir = resolve_child_path(input_dir, args.converted_dir)

    sources = collect_images(input_dir, args.recursive)
    sources = [path for path in sources if path.resolve() != output]
    sources = [path for path in sources if not is_relative_to(path.resolve(), converted_dir)]
    sources = [path for path in sources if not path.name.startswith(".")]
    if not sources:
        fail(f"No HEIC/JPG images found in {input_dir}")

    heic_sources = [path for path in sources if path.suffix.lower() in HEIC_EXTENSIONS]
    jpeg_sources = [path for path in sources if path.suffix.lower() in JPEG_EXTENSIONS]

    converted_heic: list[Path] = []
    if heic_sources and not args.no_convert:
        converted_heic = convert_heic_files(
            heic_sources,
            input_dir,
            converted_dir,
            args.quality,
            args.overwrite,
        )
    elif heic_sources:
        print(f"skip HEIC conversion: {len(heic_sources)} file(s)")

    grid_images = sorted(set(converted_heic + jpeg_sources))
    if not grid_images:
        fail("No JPG images available after conversion.")

    make_grid(
        grid_images,
        output,
        args.cell_width,
        args.cell_height,
        args.gap,
        args.background,
        args.quality,
    )


if __name__ == "__main__":
    main()
