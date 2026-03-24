#!/usr/bin/env python3
"""Convert a PDF, document, or image into a dark-background PDF."""

from __future__ import annotations

import argparse
import importlib
import io
import shutil
import subprocess
import tempfile
import textwrap
from pathlib import Path
from typing import Dict, Iterable, Tuple


THEMES: Dict[str, Dict[str, Tuple[int, int, int]]] = {
    "graphite": {
        "background": (24, 28, 34),
        "foreground": (239, 244, 250),
    },
    "midnight": {
        "background": (10, 14, 24),
        "foreground": (232, 240, 255),
    },
    "navy": {
        "background": (14, 24, 42),
        "foreground": (233, 242, 253),
    },
}

DOCUMENT_EXTENSIONS = {".doc", ".docx", ".rtf", ".odt", ".txt", ".md", ".html", ".htm"}
TEXT_LIKE_EXTENSIONS = {".txt", ".md"}
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".tif", ".tiff", ".bmp", ".gif", ".heic"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert a PDF, document, or image into a dark-background PDF."
    )
    parser.add_argument("--input", required=True, help="Input PDF, document, or image path.")
    parser.add_argument("--output", required=True, help="Output dark PDF path.")
    parser.add_argument(
        "--theme",
        default="graphite",
        choices=sorted(THEMES.keys()),
        help="Dark theme background preset.",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=160,
        help="Rasterization DPI for PDF pages. Higher values improve fidelity but increase file size.",
    )
    return parser.parse_args()


def require_module(name: str, package_hint: str):
    try:
        return importlib.import_module(name)
    except ImportError as exc:
        raise SystemExit(f"{name} is required. Install {package_hint} and retry.") from exc


def run_command(args: Iterable[str]) -> subprocess.CompletedProcess[bytes]:
    try:
        return subprocess.run(list(args), check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as exc:
        stderr = exc.stderr.decode("utf-8", errors="ignore").strip()
        raise SystemExit(stderr or f"Command failed: {' '.join(args)}") from exc


def normalize_to_pdf(input_path: Path, temp_dir: Path) -> Path:
    suffix = input_path.suffix.lower()

    if suffix == ".pdf":
        return input_path

    if suffix in IMAGE_EXTENSIONS:
        return image_to_pdf(input_path, temp_dir)

    if suffix in DOCUMENT_EXTENSIONS:
        return document_to_pdf(input_path, temp_dir)

    raise SystemExit(f"Unsupported input type: {input_path.suffix or 'no extension'}")


def document_to_pdf(input_path: Path, temp_dir: Path) -> Path:
    text = extract_text_from_document(input_path)
    out_path = temp_dir / f"{input_path.stem}-normalized.pdf"
    text_to_pdf(text, out_path)
    return out_path


def extract_text_from_document(input_path: Path) -> str:
    suffix = input_path.suffix.lower()

    if suffix in TEXT_LIKE_EXTENSIONS:
        return input_path.read_text(encoding="utf-8", errors="ignore")

    textutil = shutil.which("textutil")
    if textutil:
        result = run_command([textutil, "-convert", "txt", "-stdout", str(input_path)])
        return result.stdout.decode("utf-8", errors="ignore")

    soffice = shutil.which("soffice") or shutil.which("libreoffice")
    if soffice:
        with tempfile.TemporaryDirectory(prefix="dark-pdf-doc-") as temp_dir_str:
            temp_dir = Path(temp_dir_str)
            run_command([soffice, "--headless", "--convert-to", "txt:Text", "--outdir", str(temp_dir), str(input_path)])
            converted = temp_dir / f"{input_path.stem}.txt"
            if converted.exists():
                return converted.read_text(encoding="utf-8", errors="ignore")

    raise SystemExit("Document conversion needs macOS textutil or LibreOffice.")


def text_to_pdf(text: str, out_path: Path) -> None:
    fitz = require_module("fitz", "PyMuPDF")

    pdf = fitz.open()
    page_width = 612
    page_height = 792
    margin = 54
    line_height = 15
    wrap_width = 88
    max_lines_per_page = int((page_height - margin * 2) / line_height)

    paragraphs = text.replace("\r\n", "\n").split("\n")
    lines = []

    for paragraph in paragraphs:
        stripped = paragraph.strip()
        if not stripped:
            lines.append("")
            continue
        wrapped = textwrap.wrap(stripped, width=wrap_width, break_long_words=False, replace_whitespace=False)
        lines.extend(wrapped or [""])

    if not lines:
        lines = [""]

    for start_index in range(0, len(lines), max_lines_per_page):
        page = pdf.new_page(width=page_width, height=page_height)
        y = margin
        for line in lines[start_index:start_index + max_lines_per_page]:
            page.insert_text((margin, y), line, fontsize=11, fontname="helv", color=(0, 0, 0))
            y += line_height

    pdf.save(out_path)
    pdf.close()


def image_to_pdf(input_path: Path, temp_dir: Path) -> Path:
    fitz = require_module("fitz", "PyMuPDF")
    Image = require_module("PIL.Image", "Pillow")

    with Image.open(input_path) as image:
        rgb = image.convert("RGB")
        buffer = io.BytesIO()
        rgb.save(buffer, format="PNG")
        pdf = fitz.open()
        page = pdf.new_page(width=rgb.width, height=rgb.height)
        page.insert_image(page.rect, stream=buffer.getvalue())
        out_path = temp_dir / f"{input_path.stem}.pdf"
        pdf.save(out_path)
        pdf.close()
    return out_path


def themed_image(pil_image, background, foreground):
    Image = require_module("PIL.Image", "Pillow")
    ImageOps = require_module("PIL.ImageOps", "Pillow")

    grayscale = pil_image.convert("L")
    inverted = ImageOps.invert(grayscale)
    remapped = inverted.point(lambda value: int((value / 255.0) ** 0.88 * 255))

    bg_r, bg_g, bg_b = background
    fg_r, fg_g, fg_b = foreground

    r = remapped.point(lambda value: bg_r + (value * (fg_r - bg_r)) // 255)
    g = remapped.point(lambda value: bg_g + (value * (fg_g - bg_g)) // 255)
    b = remapped.point(lambda value: bg_b + (value * (fg_b - bg_b)) // 255)

    return Image.merge("RGB", (r, g, b))


def render_dark_pdf(source_pdf: Path, output_pdf: Path, theme: str, dpi: int) -> None:
    fitz = require_module("fitz", "PyMuPDF")
    Image = require_module("PIL.Image", "Pillow")

    colors = THEMES[theme]
    scale = dpi / 72.0
    matrix = fitz.Matrix(scale, scale)

    src = fitz.open(source_pdf)
    out = fitz.open()

    try:
        for page_index in range(src.page_count):
            page = src.load_page(page_index)
            pixmap = page.get_pixmap(matrix=matrix, alpha=False)
            pil_image = Image.frombytes("RGB", [pixmap.width, pixmap.height], pixmap.samples)
            dark_page = themed_image(pil_image, colors["background"], colors["foreground"])

            buffer = io.BytesIO()
            dark_page.save(buffer, format="PNG")

            new_page = out.new_page(width=page.rect.width, height=page.rect.height)
            new_page.insert_image(new_page.rect, stream=buffer.getvalue())

        output_pdf.parent.mkdir(parents=True, exist_ok=True)
        out.save(output_pdf)
    finally:
        out.close()
        src.close()


def main() -> int:
    args = parse_args()
    input_path = Path(args.input).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve()

    if not input_path.exists():
        raise SystemExit(f"Input file not found: {input_path}")

    with tempfile.TemporaryDirectory(prefix="dark-pdf-studio-") as temp_dir_str:
        temp_dir = Path(temp_dir_str)
        normalized_pdf = normalize_to_pdf(input_path, temp_dir)
        render_dark_pdf(normalized_pdf, output_path, args.theme, args.dpi)

    print(output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
