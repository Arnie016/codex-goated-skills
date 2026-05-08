#!/usr/bin/env python3
"""Read the current Finder selection or explicit macOS paths and format them for handoff."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import shlex
import subprocess
import sys
from pathlib import Path


def run_osascript(script: str) -> str:
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as error:
        raise SystemExit("osascript is required on macOS for this helper.") from error
    except subprocess.CalledProcessError as error:
        message = (error.stderr or error.stdout or "").strip() or "AppleScript request failed."
        raise SystemExit(message)
    return result.stdout.strip()


def finder_selected_paths() -> list[Path]:
    script = """
    tell application "Finder"
        set selectedItems to selection
        if (count of selectedItems) is 0 then error "No Finder items selected."
        set outputLines to {}
        repeat with anItem in selectedItems
            set end of outputLines to POSIX path of (anItem as alias)
        end repeat
        set AppleScript's text item delimiters to linefeed
        return outputLines as string
    end tell
    """
    output = run_osascript(script)
    paths = [Path(line.strip()).expanduser() for line in output.splitlines() if line.strip()]
    if not paths:
        raise SystemExit("No Finder paths returned.")
    return paths


def normalize_input_path(raw_path: str) -> Path:
    path = Path(raw_path.strip()).expanduser()
    if not path.is_absolute():
        path = (Path.cwd() / path).resolve()
    return path


def explicit_paths(args: argparse.Namespace) -> list[Path]:
    if args.stdin_paths:
        raw_paths = [line.strip() for line in sys.stdin.read().splitlines() if line.strip()]
        if not raw_paths:
            raise SystemExit("No paths were provided on stdin.")
        return [normalize_input_path(path) for path in raw_paths]

    if args.paths:
        return [normalize_input_path(path) for path in args.paths]

    return []


def iso_timestamp(value: float) -> str:
    return (
        dt.datetime.fromtimestamp(value, tz=dt.timezone.utc)
        .astimezone()
        .replace(microsecond=0)
        .isoformat()
    )


def human_size(size_bytes: int) -> str:
    size = float(size_bytes)
    units = ["B", "KB", "MB", "GB", "TB"]
    for unit in units:
        if size < 1024.0 or unit == units[-1]:
            if unit == "B":
                return f"{int(size)} {unit}"
            return f"{size:.1f} {unit}"
        size /= 1024.0
    return f"{int(size_bytes)} B"


def describe_item(path: Path) -> dict[str, object]:
    try:
        stat = path.stat()
    except OSError as error:
        raise SystemExit(f"Could not inspect {path}: {error}") from error

    is_directory = path.is_dir()
    payload: dict[str, object] = {
        "name": path.name or str(path),
        "path": str(path),
        "kind": "folder" if is_directory else "file",
        "parent": str(path.parent),
        "extension": "" if is_directory else path.suffix.lower(),
        "modified_at": iso_timestamp(stat.st_mtime),
    }
    if not is_directory:
        payload["size_bytes"] = stat.st_size
        payload["size_human"] = human_size(stat.st_size)
    return payload


def common_location(items: list[dict[str, object]]) -> str:
    if not items:
        return ""
    if len(items) == 1:
        return str(items[0]["path"])
    try:
        common_path = os.path.commonpath([str(item["path"]) for item in items])
    except ValueError:
        return "mixed locations"
    if common_path in {"", "/"}:
        return "mixed locations"
    return common_path


def selection_summary(items: list[dict[str, object]]) -> dict[str, object]:
    file_count = sum(1 for item in items if item["kind"] == "file")
    folder_count = sum(1 for item in items if item["kind"] == "folder")
    return {
        "count": len(items),
        "file_count": file_count,
        "folder_count": folder_count,
        "location": common_location(items),
    }


def selection_source(args: argparse.Namespace) -> str:
    if args.stdin_paths:
        return "stdin"
    if args.paths:
        return "explicit paths"
    return "Finder"


def detail_line(item: dict[str, object]) -> str:
    parts = [str(item["kind"])]
    extension = str(item["extension"])
    if extension:
        parts.append(extension.lstrip("."))
    size_human = item.get("size_human")
    if size_human:
        parts.append(str(size_human))
    return f'{item["name"]} ({", ".join(parts)}) - {item["path"]}'


def format_payload(payload: dict[str, object], style: str) -> str:
    summary = payload["summary"]
    items = payload["items"]
    count = summary["count"]
    noun = "item" if count == 1 else "items"
    location = summary["location"]
    source = summary["source"]

    if style == "json":
        return json.dumps(payload, indent=2, ensure_ascii=False)
    if style == "paths":
        return "\n".join(str(item["path"]) for item in items)
    if style == "shell":
        return "\n".join(shlex.quote(str(item["path"])) for item in items)
    if style == "plain":
        lines = [f"Finder selection ({count} {noun})", f"Source: {source}", f"Location: {location}"]
        lines.extend(f"- {detail_line(item)}" for item in items)
        return "\n".join(lines)
    if style == "markdown":
        lines = [
            f"### Finder selection ({count} {noun})",
            f"- Source: `{source}`",
            f"- Location: `{location}`",
            "- Items:",
        ]
        lines.extend(f"  - `{item['name']}` ({item['kind']}) - `{item['path']}`" for item in items)
        return "\n".join(lines)
    if style == "ticket":
        lines = [
            "Finder handoff",
            f"- Count: {count}",
            f"- Files: {summary['file_count']}",
            f"- Folders: {summary['folder_count']}",
            f"- Source: {source}",
            f"- Location: {location}",
            "- Items:",
        ]
        lines.extend(f"  - {detail_line(item)}" for item in items)
        return "\n".join(lines)
    if style == "prompt":
        lines = [
            "Finder selection context",
            f"Summary: {count} {noun}",
            f"Source: {source}",
            f"Location: {location}",
            "Selected items:",
        ]
        lines.extend(f"- {detail_line(item)}" for item in items)
        lines.append("Use these paths as the local context for the next task.")
        return "\n".join(lines)
    raise SystemExit(f"Unsupported format: {style}")


def copy_text(text: str) -> None:
    try:
        subprocess.run(["pbcopy"], input=text, text=True, check=True)
    except FileNotFoundError as error:
        raise SystemExit("pbcopy is required on macOS for clipboard copy.") from error


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["current", "copy"], nargs="?", default="current")
    parser.add_argument(
        "paths",
        nargs="*",
        help="Optional explicit paths to format instead of reading the live Finder selection.",
    )
    parser.add_argument(
        "--format",
        default="json",
        choices=["json", "plain", "paths", "markdown", "ticket", "prompt", "shell"],
        help="Output format for the Finder selection payload.",
    )
    parser.add_argument(
        "--max-items",
        type=int,
        default=25,
        help="Maximum allowed selected items before the helper asks for a narrower selection. Use 0 for no limit.",
    )
    parser.add_argument(
        "--stdin-paths",
        action="store_true",
        help="Read newline-delimited paths from standard input instead of querying Finder.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.stdin_paths and args.paths:
        raise SystemExit("Use explicit path arguments or --stdin-paths, not both.")

    paths = explicit_paths(args) or finder_selected_paths()
    if args.max_items > 0 and len(paths) > args.max_items:
        raise SystemExit(
            f"Selection contains {len(paths)} items. Narrow the Finder selection or rerun with --max-items {len(paths)}."
        )

    items = [describe_item(path) for path in paths]
    summary = selection_summary(items)
    summary["source"] = selection_source(args)
    payload = {"summary": summary, "items": items}
    text = format_payload(payload, args.format)

    if args.command == "copy":
        copy_text(text)
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
