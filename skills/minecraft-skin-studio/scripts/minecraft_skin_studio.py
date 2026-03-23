#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from collections import OrderedDict
from datetime import datetime
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageDraw
except ModuleNotFoundError:
    print("Error: Pillow is required. Run this tool through uv or install pillow for the active python.", file=sys.stderr)
    raise SystemExit(1)

try:
    RESAMPLING = Image.Resampling
except AttributeError:  # Pillow < 9
    RESAMPLING = Image


REPO_NAME = "Minecraft Skin Studio"
DEFAULT_OUTPUT_DIR = Path.home() / "Pictures" / "Minecraft Skins"
DEFAULT_MINECRAFT_DIR = Path.home() / "Library" / "Application Support" / "minecraft"
DEFAULT_LAUNCHER_JSON = DEFAULT_MINECRAFT_DIR / "launcher_custom_skins.json"
IMAGEGEN_SCRIPT = Path.home() / ".codex" / "skills" / "imagegen" / "scripts" / "image_gen.py"
UV_BIN = os.environ.get("UV_BIN") or shutil.which("uv") or "/opt/homebrew/bin/uv"
TEMPLATE_SIZE = 1024
SKIN_SIZE = (64, 64)
PREVIEW_SIZE = (288, 384)

# Large rectangles that cover the valid 64x64 skin canvas regions Minecraft actually uses.
LEGAL_RECTS = [
    (0, 0, 32, 16),
    (32, 0, 32, 16),
    (0, 16, 56, 16),
    (0, 32, 56, 16),
    (0, 48, 64, 16),
]

# Fine-grained guide boxes to help the image model stay close to the Minecraft UV layout.
GUIDE_RECTS = [
    (8, 0, 8, 8), (16, 0, 8, 8), (0, 8, 8, 8), (8, 8, 8, 8), (16, 8, 8, 8), (24, 8, 8, 8),
    (40, 0, 8, 8), (48, 0, 8, 8), (32, 8, 8, 8), (40, 8, 8, 8), (48, 8, 8, 8), (56, 8, 8, 8),
    (20, 16, 8, 4), (28, 16, 8, 4), (16, 20, 4, 12), (20, 20, 8, 12), (28, 20, 4, 12), (32, 20, 8, 12),
    (20, 32, 8, 4), (28, 32, 8, 4), (16, 36, 4, 12), (20, 36, 8, 12), (28, 36, 4, 12), (32, 36, 8, 12),
    (4, 16, 4, 4), (8, 16, 4, 4), (0, 20, 4, 12), (4, 20, 4, 12), (8, 20, 4, 12), (12, 20, 4, 12),
    (4, 32, 4, 4), (8, 32, 4, 4), (0, 36, 4, 12), (4, 36, 4, 12), (8, 36, 4, 12), (12, 36, 4, 12),
    (44, 16, 4, 4), (48, 16, 4, 4), (40, 20, 4, 12), (44, 20, 4, 12), (48, 20, 4, 12), (52, 20, 4, 12),
    (44, 32, 4, 4), (48, 32, 4, 4), (40, 36, 4, 12), (44, 36, 4, 12), (48, 36, 4, 12), (52, 36, 4, 12),
    (20, 48, 4, 4), (24, 48, 4, 4), (16, 52, 4, 12), (20, 52, 4, 12), (24, 52, 4, 12), (28, 52, 4, 12),
    (4, 48, 4, 4), (8, 48, 4, 4), (0, 52, 4, 12), (4, 52, 4, 12), (8, 52, 4, 12), (12, 52, 4, 12),
    (36, 48, 4, 4), (40, 48, 4, 4), (32, 52, 4, 12), (36, 52, 4, 12), (40, 52, 4, 12), (44, 52, 4, 12),
    (52, 48, 4, 4), (56, 48, 4, 4), (48, 52, 4, 12), (52, 52, 4, 12), (56, 52, 4, 12), (60, 52, 4, 12),
]


def die(message: str, code: int = 1) -> None:
    print(f"Error: {message}", file=sys.stderr)
    raise SystemExit(code)


def slugify(text: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug or "minecraft-skin"


def iso_now() -> str:
    return datetime.now().replace(microsecond=0).isoformat()


def ensure_output_dir(path: Path) -> Path:
    path.mkdir(parents=True, exist_ok=True)
    return path


def encode_png_data_url(image: Image.Image) -> str:
    buf = io.BytesIO()
    image.save(buf, format="PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode("ascii")


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def make_guide_template(size: int = TEMPLATE_SIZE) -> Image.Image:
    scale = size // 64
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    palette = [
        (34, 197, 94, 255),
        (56, 189, 248, 255),
        (250, 204, 21, 255),
        (248, 113, 113, 255),
        (192, 132, 252, 255),
        (251, 146, 60, 255),
    ]

    for index, (x, y, w, h) in enumerate(GUIDE_RECTS):
        outline = palette[index % len(palette)]
        draw.rectangle(
            (x * scale, y * scale, (x + w) * scale - 1, (y + h) * scale - 1),
            fill=(8, 8, 10, 220),
            outline=outline,
            width=max(2, scale // 8),
        )

    return image


def legal_mask(size: tuple[int, int] = SKIN_SIZE) -> Image.Image:
    sx = size[0] / 64
    sy = size[1] / 64
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    for x, y, w, h in LEGAL_RECTS:
        draw.rectangle(
            (
                int(round(x * sx)),
                int(round(y * sy)),
                int(round((x + w) * sx)) - 1,
                int(round((y + h) * sy)) - 1,
            ),
            fill=255,
        )
    return mask


def clean_skin_sheet(raw_path: Path, out_path: Path) -> Path:
    raw = load_rgba(raw_path)
    resized = raw.resize(SKIN_SIZE, RESAMPLING.NEAREST)
    mask = legal_mask(SKIN_SIZE)
    cleaned = Image.new("RGBA", resized.size, (0, 0, 0, 0))
    cleaned.paste(resized, (0, 0), mask)
    cleaned.save(out_path)
    return out_path


def extract_region(image: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    x, y, w, h = box
    return image.crop((x, y, x + w, y + h))


def paste_scaled(
    canvas: Image.Image,
    tile: Image.Image,
    x: int,
    y: int,
    scale: int,
    overlay: Image.Image | None = None,
) -> None:
    base = tile.resize((tile.width * scale, tile.height * scale), RESAMPLING.NEAREST)
    canvas.alpha_composite(base, (x, y))
    if overlay is not None:
        top = overlay.resize((overlay.width * scale, overlay.height * scale), RESAMPLING.NEAREST)
        canvas.alpha_composite(top, (x, y))


def render_preview_image(skin_path: Path, slim: bool) -> Image.Image:
    skin = load_rgba(skin_path)
    canvas = Image.new("RGBA", PREVIEW_SIZE, (0, 0, 0, 0))

    scale = 12
    body_x = 96
    head_x = 96
    head_y = 0
    torso_y = 96
    legs_y = 240
    arm_y = 96

    arm_width = 3 if slim else 4
    left_arm_x = body_x + (8 * scale)
    right_arm_x = body_x - (arm_width * scale)
    left_leg_x = body_x + (4 * scale)
    right_leg_x = body_x

    paste_scaled(
        canvas,
        extract_region(skin, (8, 8, 8, 8)),
        head_x,
        head_y,
        scale,
        overlay=extract_region(skin, (40, 8, 8, 8)),
    )
    paste_scaled(canvas, extract_region(skin, (20, 20, 8, 12)), body_x, torso_y, scale)
    paste_scaled(canvas, extract_region(skin, (44, 20, arm_width, 12)), right_arm_x, arm_y, scale)
    paste_scaled(canvas, extract_region(skin, (36, 52, arm_width, 12)), left_arm_x, arm_y, scale)
    paste_scaled(canvas, extract_region(skin, (4, 20, 4, 12)), right_leg_x, legs_y, scale)
    paste_scaled(canvas, extract_region(skin, (20, 52, 4, 12)), left_leg_x, legs_y, scale)

    return canvas


def save_preview(skin_path: Path, out_path: Path, slim: bool) -> Path:
    render_preview_image(skin_path, slim).save(out_path)
    return out_path


def launcher_state(path: Path) -> OrderedDict:
    if not path.exists() or path.stat().st_size == 0:
        return OrderedDict((("customSkins", OrderedDict()), ("version", 1)))

    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle, object_pairs_hook=OrderedDict)

    if not isinstance(data, dict):
        die(f"Unexpected launcher JSON shape: {path}")

    custom = data.get("customSkins")
    if not isinstance(custom, dict):
        data["customSkins"] = OrderedDict()
    if "version" not in data:
        data["version"] = 1
    return data


def next_skin_id(custom_skins: dict[str, object]) -> str:
    used = {key for key in custom_skins.keys() if isinstance(key, str)}
    index = 1
    while f"skin_{index}" in used:
        index += 1
    return f"skin_{index}"


def register_skin(
    skin_path: Path,
    name: str,
    slim: bool,
    launcher_json: Path,
    preview_path: Path | None = None,
    replace: bool = False,
) -> str:
    skin_path = skin_path.expanduser().resolve()
    if not skin_path.exists():
        die(f"Skin file not found: {skin_path}")

    skin_image = load_rgba(skin_path)
    if skin_image.size not in {(64, 64), (64, 32)}:
        die("Minecraft skin PNG must be 64x64 or legacy 64x32.")

    if skin_image.size == (64, 32):
        upgraded = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        upgraded.paste(skin_image, (0, 0))
        skin_image = upgraded
        skin_image.save(skin_path)

    if preview_path is None:
        preview_path = skin_path.with_name(f"{skin_path.stem}-preview.png")
    save_preview(skin_path, preview_path, slim)
    preview_image = load_rgba(preview_path)

    launcher_json.parent.mkdir(parents=True, exist_ok=True)
    state = launcher_state(launcher_json)
    custom_skins = state["customSkins"]
    created_at = iso_now()
    target_id = ""

    if replace:
        for skin_id, record in custom_skins.items():
            if isinstance(record, dict) and record.get("name") == name:
                target_id = skin_id
                created_at = record.get("created", created_at)
                break

    if not target_id:
        target_id = next_skin_id(custom_skins)

    custom_skins[target_id] = OrderedDict(
        (
            ("created", created_at),
            ("id", target_id),
            ("modelImage", encode_png_data_url(preview_image)),
            ("name", name),
            ("skinImage", encode_png_data_url(skin_image)),
            ("slim", slim),
            ("updated", iso_now()),
        )
    )

    with launcher_json.open("w", encoding="utf-8") as handle:
        json.dump(state, handle, indent="\t")
        handle.write("\n")

    return target_id


def launcher_running() -> bool:
    result = subprocess.run(
        ["pgrep", "-x", "launcher"],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return result.returncode == 0


def imagegen_available() -> bool:
    return IMAGEGEN_SCRIPT.exists()


def prompt_text(prompt: str, slim: bool) -> str:
    model_lane = "slim arms" if slim else "wide arms"
    return (
        "Create a single Minecraft Java Edition player skin sprite sheet using the exact supplied layout. "
        "Keep every painted section inside the existing UV boxes. "
        "Make it readable as Minecraft pixel art, with clean shapes and strong contrast. "
        f"Target a {model_lane} model. "
        "Outside the skin boxes, keep the background transparent. "
        "Do not add labels, extra panels, shadows, or unrelated objects. "
        f"Theme: {prompt.strip()}"
    )


def generate_skin(args: argparse.Namespace) -> dict[str, Path]:
    if not imagegen_available():
        die(f"Missing image generation helper: {IMAGEGEN_SCRIPT}")
    if not os.getenv("OPENAI_API_KEY"):
        die("OPENAI_API_KEY is not set.")
    if not Path(UV_BIN).exists():
        die("uv is required to run prompt-based skin generation.")

    out_dir = ensure_output_dir(args.out_dir.expanduser())
    stem = slugify(args.name or args.prompt)
    raw_path = out_dir / f"{stem}-draft-raw.png"
    skin_path = out_dir / f"{stem}.png"
    preview_path = out_dir / f"{stem}-preview.png"

    with tempfile.TemporaryDirectory(prefix="mc-skin-") as tmpdir:
        template_path = Path(tmpdir) / "template.png"
        make_guide_template().save(template_path)

        cmd = [
            UV_BIN,
            "run",
            "--with",
            "openai",
            "--with",
            "pillow",
            "python",
            str(IMAGEGEN_SCRIPT),
            "edit",
            "--model",
            args.model,
            "--image",
            str(template_path),
            "--prompt",
            prompt_text(args.prompt, args.slim),
            "--size",
            "1024x1024",
            "--quality",
            args.quality,
            "--background",
            "transparent",
            "--input-fidelity",
            "high",
            "--output-format",
            "png",
            "--out",
            str(raw_path),
        ]

        print("Running image generation draft...", file=sys.stderr)
        subprocess.run(cmd, check=True)

    clean_skin_sheet(raw_path, skin_path)
    save_preview(skin_path, preview_path, args.slim)
    return {"raw": raw_path, "skin": skin_path, "preview": preview_path}


def cmd_generate(args: argparse.Namespace) -> int:
    outputs = generate_skin(args)
    print(f"Draft raw: {outputs['raw']}")
    print(f"Skin PNG: {outputs['skin']}")
    print(f"Preview: {outputs['preview']}")
    print("Note: prompt-generated skins are draft quality. Visually inspect before using.")
    return 0


def cmd_render_preview(args: argparse.Namespace) -> int:
    out_path = args.out.expanduser().resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    save_preview(args.skin.expanduser(), out_path, args.slim)
    print(f"Preview: {out_path}")
    return 0


def cmd_register(args: argparse.Namespace) -> int:
    launcher_json = args.launcher_json.expanduser()
    skin_path = args.skin.expanduser().resolve()
    preview_path = args.preview.expanduser().resolve() if args.preview else skin_path.with_name(f"{skin_path.stem}-preview.png")
    target_id = register_skin(
        skin_path=skin_path,
        name=args.name,
        slim=args.slim,
        launcher_json=launcher_json,
        preview_path=preview_path,
        replace=args.replace,
    )
    print(f"Skin PNG: {skin_path}")
    print(f"Preview: {preview_path}")
    print(f"Registered launcher skin id: {target_id}")
    print(f"Launcher file: {launcher_json}")
    if launcher_running():
        print("Minecraft Launcher is open. Restart it if the new skin does not appear immediately.")
    else:
        print("Open Minecraft Launcher and the skin should appear in your custom skins list.")
    return 0


def cmd_go(args: argparse.Namespace) -> int:
    outputs = generate_skin(args)
    target_id = register_skin(
        skin_path=outputs["skin"],
        name=args.name or slugify(args.prompt).replace("-", " "),
        slim=args.slim,
        launcher_json=args.launcher_json.expanduser(),
        preview_path=outputs["preview"],
        replace=args.replace,
    )
    print(f"Draft raw: {outputs['raw']}")
    print(f"Skin PNG: {outputs['skin']}")
    print(f"Preview: {outputs['preview']}")
    print(f"Registered launcher skin id: {target_id}")
    if launcher_running():
        print("Minecraft Launcher is open. Restart it if the new skin does not appear immediately.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=REPO_NAME)
    sub = parser.add_subparsers(dest="command", required=True)

    gen = sub.add_parser("generate", help="Draft and clean a Minecraft skin from a prompt")
    gen.add_argument("--prompt", required=True)
    gen.add_argument("--name")
    gen.add_argument("--out-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    gen.add_argument("--model", default="gpt-image-1.5")
    gen.add_argument("--quality", choices=["low", "medium", "high", "auto"], default="low")
    gen.add_argument("--slim", action="store_true")
    gen.set_defaults(func=cmd_generate)

    render = sub.add_parser("render-preview", help="Render a front preview from a skin PNG")
    render.add_argument("--skin", type=Path, required=True)
    render.add_argument("--out", type=Path, required=True)
    render.add_argument("--slim", action="store_true")
    render.set_defaults(func=cmd_render_preview)

    reg = sub.add_parser("register", help="Register an existing skin PNG with the local Java launcher")
    reg.add_argument("--skin", type=Path, required=True)
    reg.add_argument("--name", required=True)
    reg.add_argument("--preview", type=Path)
    reg.add_argument("--launcher-json", type=Path, default=DEFAULT_LAUNCHER_JSON)
    reg.add_argument("--slim", action="store_true")
    reg.add_argument("--replace", action="store_true")
    reg.set_defaults(func=cmd_register)

    go = sub.add_parser("go", help="Generate a skin from a prompt and register it in the local launcher")
    go.add_argument("--prompt", required=True)
    go.add_argument("--name")
    go.add_argument("--out-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    go.add_argument("--launcher-json", type=Path, default=DEFAULT_LAUNCHER_JSON)
    go.add_argument("--model", default="gpt-image-1.5")
    go.add_argument("--quality", choices=["low", "medium", "high", "auto"], default="low")
    go.add_argument("--slim", action="store_true")
    go.add_argument("--replace", action="store_true")
    go.set_defaults(func=cmd_go)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return int(args.func(args))
    except subprocess.CalledProcessError as exc:
        die(f"Subprocess failed with exit code {exc.returncode}")
    except KeyboardInterrupt:
        die("Interrupted by user.", code=130)


if __name__ == "__main__":
    raise SystemExit(main())
