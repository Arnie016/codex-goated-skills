#!/usr/bin/env python3
"""Scaffold SVG assets and extrude them into local 3D model exports."""

from __future__ import annotations

import argparse
import json
import math
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


PRESET_LIBRARY: dict[str, dict[str, float | str]] = {
    "badge": {"label": "Badge", "width": 512, "height": 512, "corner": 96, "shape": "rounded-rect"},
    "coin": {"label": "Coin", "width": 512, "height": 512, "corner": 0, "shape": "circle"},
    "plaque": {"label": "Plaque", "width": 640, "height": 360, "corner": 44, "shape": "rounded-rect"},
    "keycap": {"label": "Keycap Face", "width": 540, "height": 540, "corner": 56, "shape": "rounded-rect"},
}

OUTPUT_FORMATS = {"stl", "obj", "glb"}


def svg_escape(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&apos;")
    )


def find_blender(explicit: str | None = None) -> str | None:
    if explicit:
        return explicit

    candidates = [
        shutil.which("blender"),
        "/Applications/Blender.app/Contents/MacOS/Blender",
        "/Applications/Blender 4.1.app/Contents/MacOS/Blender",
        "/Applications/Blender 4.0.app/Contents/MacOS/Blender",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return candidate
    return None


def run_blender(blender_path: str, driver_path: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [blender_path, "--background", "--python", str(driver_path)],
        check=False,
        capture_output=True,
        text=True,
    )


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def scaffold_svg(args: argparse.Namespace) -> int:
    preset = PRESET_LIBRARY[args.preset]
    width = int(preset["width"])
    height = int(preset["height"])
    accent = args.accent
    text = svg_escape(args.text)
    subtitle = svg_escape(args.subtitle) if args.subtitle else ""

    if preset["shape"] == "circle":
        frame = f'<circle cx="{width / 2:.0f}" cy="{height / 2:.0f}" r="{min(width, height) / 2 - 28:.0f}" fill="#121417" stroke="{accent}" stroke-width="24" />'
    else:
        frame = f'<rect x="28" y="28" width="{width - 56}" height="{height - 56}" rx="{int(preset["corner"])}" fill="#121417" stroke="{accent}" stroke-width="20" />'

    subtitle_block = ""
    if subtitle:
        subtitle_block = (
            f'<text x="{width / 2:.0f}" y="{height / 2 + 92:.0f}" text-anchor="middle" '
            'font-family="-apple-system, BlinkMacSystemFont, \'SF Pro Text\', sans-serif" '
            'font-size="34" fill="#D1D5DB">'
            f"{subtitle}</text>"
        )

    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-label="{text}">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#171A1F"/>
      <stop offset="100%" stop-color="#0B0D11"/>
    </linearGradient>
  </defs>
  <rect width="{width}" height="{height}" fill="url(#bg)" />
  {frame}
  <text x="{width / 2:.0f}" y="{height / 2 + 18:.0f}" text-anchor="middle"
    font-family="-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif"
    font-size="{args.font_size}" font-weight="800" fill="#FFFFFF">{text}</text>
  {subtitle_block}
</svg>
"""
    output = Path(args.output).expanduser().resolve()
    write_text(output, svg)
    print(output)
    return 0


def blender_driver(input_path: Path, output_path: Path, export_format: str, depth: float, bevel: float, size: float) -> str:
    payload = {
        "input_svg": str(input_path),
        "output_model": str(output_path),
        "format": export_format,
        "depth": depth,
        "bevel": bevel,
        "size": size,
    }
    return f"""import bpy
import json
from pathlib import Path

payload = json.loads({json.dumps(json.dumps(payload))})
input_svg = payload["input_svg"]
output_model = payload["output_model"]
export_format = payload["format"]
depth = float(payload["depth"])
bevel = float(payload["bevel"])
size = float(payload["size"])

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_curve.svg(filepath=input_svg)

curves = [obj for obj in bpy.context.scene.objects if obj.type == "CURVE"]
if not curves:
    raise RuntimeError("No SVG curves were imported.")

for obj in curves:
    obj.data.dimensions = "2D"
    obj.data.fill_mode = "BOTH"
    obj.data.extrude = depth
    obj.data.bevel_depth = bevel
    obj.data.resolution_u = 12

bpy.ops.object.select_all(action="DESELECT")
for obj in curves:
    obj.select_set(True)
bpy.context.view_layer.objects.active = curves[0]
bpy.ops.object.convert(target="MESH")

meshes = [obj for obj in bpy.context.selected_objects if obj.type == "MESH"]
if not meshes:
    raise RuntimeError("SVG import did not yield mesh objects after conversion.")

active = meshes[0]
bpy.context.view_layer.objects.active = active
if len(meshes) > 1:
    bpy.ops.object.join()
    active = bpy.context.view_layer.objects.active

active.location = (0.0, 0.0, 0.0)
bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")

max_dimension = max(active.dimensions.x, active.dimensions.y, active.dimensions.z)
if max_dimension > 0:
    scale_factor = size / max_dimension
    active.scale = (
        active.scale.x * scale_factor,
        active.scale.y * scale_factor,
        active.scale.z * scale_factor,
    )

bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bpy.ops.object.select_all(action="DESELECT")
active.select_set(True)
bpy.context.view_layer.objects.active = active

output_parent = Path(output_model).expanduser().resolve().parent
output_parent.mkdir(parents=True, exist_ok=True)

if export_format == "stl":
    bpy.ops.export_mesh.stl(filepath=str(Path(output_model).expanduser().resolve()), use_selection=True)
elif export_format == "glb":
    bpy.ops.export_scene.gltf(filepath=str(Path(output_model).expanduser().resolve()), export_format="GLB", use_selection=True)
elif export_format == "obj":
    if hasattr(bpy.ops.wm, "obj_export"):
        bpy.ops.wm.obj_export(filepath=str(Path(output_model).expanduser().resolve()), export_selected_objects=True)
    else:
        bpy.ops.export_scene.obj(filepath=str(Path(output_model).expanduser().resolve()), use_selection=True)
else:
    raise RuntimeError(f"Unsupported export format: {{export_format}}")

print(output_model)
"""


def extrude_svg(args: argparse.Namespace) -> int:
    input_path = Path(args.input).expanduser().resolve()
    if not input_path.is_file():
        raise SystemExit(f"Error: input SVG not found at {input_path}")

    export_format = args.format.lower()
    if export_format not in OUTPUT_FORMATS:
        raise SystemExit(f"Error: unsupported format '{args.format}'. Choose from {sorted(OUTPUT_FORMATS)}.")

    blender_path = find_blender(args.blender)
    if not blender_path:
        raise SystemExit("Error: Blender was not found. Run `doctor` or pass `--blender /path/to/Blender`.")

    output_path = Path(args.output).expanduser().resolve()
    driver_text = blender_driver(
        input_path=input_path,
        output_path=output_path,
        export_format=export_format,
        depth=args.depth,
        bevel=args.bevel,
        size=args.size,
    )

    driver_path: Path
    if args.keep_driver:
        driver_path = output_path.with_suffix(".blender-driver.py")
        write_text(driver_path, driver_text)
    else:
        temp_dir = Path(tempfile.mkdtemp(prefix="svg-to-3d-forge-"))
        driver_path = temp_dir / "driver.py"
        write_text(driver_path, driver_text)

    result = run_blender(blender_path, driver_path)
    if result.returncode != 0:
        stderr = result.stderr.strip() or result.stdout.strip() or "Blender export failed."
        raise SystemExit(stderr)

    if not output_path.exists():
        raise SystemExit(f"Error: Blender finished without writing {output_path}")

    print(output_path)
    if args.keep_driver:
        print(driver_path)
    return 0


def doctor(args: argparse.Namespace) -> int:
    blender_path = find_blender(args.blender)
    if blender_path:
        print(f"Blender: {blender_path}")
    else:
        print("Blender: not found")
        return 1

    print("Presets: " + ", ".join(sorted(PRESET_LIBRARY)))
    print("Formats: " + ", ".join(sorted(OUTPUT_FORMATS)))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Scaffold SVG assets and extrude them into local 3D exports.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    doctor_parser = subparsers.add_parser("doctor", help="Check local dependencies.")
    doctor_parser.add_argument("--blender", help="Explicit Blender binary path.")
    doctor_parser.set_defaults(func=doctor)

    scaffold_parser = subparsers.add_parser("scaffold", help="Create a simple starter SVG from a preset.")
    scaffold_parser.add_argument("--preset", choices=sorted(PRESET_LIBRARY), default="badge")
    scaffold_parser.add_argument("--text", required=True, help="Main text or monogram for the SVG.")
    scaffold_parser.add_argument("--subtitle", default="", help="Optional secondary line.")
    scaffold_parser.add_argument("--output", required=True, help="Output SVG file path.")
    scaffold_parser.add_argument("--accent", default="#F97316", help="Accent stroke color for the frame.")
    scaffold_parser.add_argument("--font-size", type=int, default=170, help="Main label font size.")
    scaffold_parser.set_defaults(func=scaffold_svg)

    extrude_parser = subparsers.add_parser("extrude", help="Import an SVG into Blender and export a 3D model.")
    extrude_parser.add_argument("--input", required=True, help="Input SVG path.")
    extrude_parser.add_argument("--output", required=True, help="Output model path.")
    extrude_parser.add_argument("--format", required=True, choices=sorted(OUTPUT_FORMATS), help="3D output format.")
    extrude_parser.add_argument("--depth", type=float, default=2.6, help="Extrusion depth in Blender units.")
    extrude_parser.add_argument("--bevel", type=float, default=0.18, help="Bevel depth in Blender units.")
    extrude_parser.add_argument("--size", type=float, default=100.0, help="Target max dimension after scaling.")
    extrude_parser.add_argument("--blender", help="Explicit Blender binary path.")
    extrude_parser.add_argument("--keep-driver", action="store_true", help="Keep the generated Blender driver script next to the output.")
    extrude_parser.set_defaults(func=extrude_svg)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
