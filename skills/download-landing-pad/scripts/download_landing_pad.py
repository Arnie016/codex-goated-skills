#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse


DEFAULT_LIMIT = 8
DEFAULT_DOWNLOADS_DIR = Path.home() / "Downloads"
MDLS_BINARY = shutil.which("mdls")
OPEN_BINARY = shutil.which("open")
PBCOPY_BINARY = shutil.which("pbcopy")

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".heic", ".webp", ".svg"}
DOCUMENT_SUFFIXES = {".pdf", ".doc", ".docx", ".pages", ".txt", ".md", ".rtf"}
SPREADSHEET_SUFFIXES = {".csv", ".tsv", ".xlsx", ".xls", ".numbers"}
ARCHIVE_SUFFIXES = {".zip", ".tar", ".gz", ".tgz", ".rar", ".7z"}
MEDIA_SUFFIXES = {".mov", ".mp4", ".m4v", ".mp3", ".wav", ".aiff"}
CODE_SUFFIXES = {".json", ".yaml", ".yml", ".toml", ".xml", ".swift", ".py", ".js", ".ts", ".sql"}


@dataclass
class DownloadItem:
    name: str
    path: str
    kind: str
    age: str
    size: str
    modified_at: str
    source: str
    suggested_name: str
    suggested_destinations: list[str]


@dataclass
class DoctorCheck:
    key: str
    label: str
    status: str
    detail: str


def fail(message: str, **extra: object) -> None:
    payload: dict[str, object] = {"ok": False, "error": message}
    payload.update(extra)
    raise SystemExit(json.dumps(payload, indent=2))


def run_command(command: list[str]) -> str | None:
    result = subprocess.run(command, capture_output=True, check=False, text=True)
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def format_bytes(size: int) -> str:
    units = ["B", "KB", "MB", "GB", "TB"]
    value = float(size)
    unit = units[0]
    for candidate in units:
        unit = candidate
        if value < 1024.0 or candidate == units[-1]:
            break
        value /= 1024.0
    if unit == "B":
        return f"{int(value)} {unit}"
    return f"{value:.1f} {unit}"


def age_label(path: Path) -> str:
    modified = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
    delta_seconds = max(0, int((datetime.now(timezone.utc) - modified).total_seconds()))
    minutes = delta_seconds // 60
    if minutes < 1:
        return "just now"
    if minutes < 60:
        return f"{minutes}m ago"
    hours = minutes // 60
    if hours < 24:
        return f"{hours}h ago"
    days = hours // 24
    return f"{days}d ago"


def parse_mdls_array(raw: str | None) -> list[str]:
    if not raw:
        return []
    text = raw.strip()
    if not text or text == "(null)":
        return []
    if text.startswith("(") and text.endswith(")"):
        values: list[str] = []
        for line in text[1:-1].splitlines():
            cleaned = line.strip().rstrip(",").strip().strip('"')
            if cleaned:
                values.append(cleaned)
        return values
    return [text.strip('"')]


def source_hint(path: Path) -> str:
    if MDLS_BINARY is None:
        return "Source metadata unavailable"
    raw = run_command([MDLS_BINARY, "-name", "kMDItemWhereFroms", "-raw", str(path)])
    values = parse_mdls_array(raw)
    for value in values:
        if "://" in value:
            host = urlparse(value).netloc.lower()
            if host.startswith("www."):
                host = host[4:]
            if host:
                return host
    if values:
        return values[0]
    return "Source metadata unavailable"


def classify_kind(path: Path) -> str:
    suffix = path.suffix.lower()
    lower_name = path.name.lower()
    if lower_name.startswith("screen shot") or lower_name.startswith("screenshot"):
        return "Screenshot"
    if suffix in IMAGE_SUFFIXES:
        return "Image"
    if suffix in DOCUMENT_SUFFIXES:
        return "Document"
    if suffix in SPREADSHEET_SUFFIXES:
        return "Spreadsheet"
    if suffix in ARCHIVE_SUFFIXES:
        return "Archive"
    if suffix in MEDIA_SUFFIXES:
        return "Media"
    if suffix in CODE_SUFFIXES:
        return "Code or data"
    return "File"


def slugify(value: str) -> str:
    cleaned = []
    last_was_dash = False
    for character in value.lower():
        if character.isalnum():
            cleaned.append(character)
            last_was_dash = False
        elif not last_was_dash:
            cleaned.append("-")
            last_was_dash = True
    return "".join(cleaned).strip("-")


def rename_suggestion(path: Path, kind: str) -> str:
    modified = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
    extension = path.suffix.lower()
    if kind == "Screenshot":
        return f"screenshot-{modified.strftime('%Y%m%d-%H%M')}{extension or '.png'}"
    stem = slugify(path.stem) or "download"
    return f"{stem}{extension}"


def suggested_destinations(kind: str) -> list[str]:
    mapping = {
        "Screenshot": ["Ticket comment", "Design review folder", "Chat upload"],
        "Image": ["Project assets", "Design review folder", "Chat upload"],
        "Document": ["Reference folder", "Meeting notes", "Share-ready handoff"],
        "Spreadsheet": ["Analysis workspace", "Finance folder", "Prompt context"],
        "Archive": ["Staging folder", "Project assets", "Archive shelf"],
        "Media": ["Review queue", "Project assets", "Share draft"],
        "Code or data": ["Repo scratch folder", "Issue attachment", "Prompt context"],
        "File": ["Desktop staging", "Project drop", "Notes attachment"],
    }
    return mapping.get(kind, mapping["File"])


def build_item(path: Path) -> DownloadItem:
    modified = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).isoformat()
    kind = classify_kind(path)
    return DownloadItem(
        name=path.name,
        path=str(path.resolve()),
        kind=kind,
        age=age_label(path),
        size=format_bytes(path.stat().st_size),
        modified_at=modified,
        source=source_hint(path),
        suggested_name=rename_suggestion(path, kind),
        suggested_destinations=suggested_destinations(kind),
    )


def recent_downloads(downloads_dir: Path, limit: int) -> list[Path]:
    if not downloads_dir.is_dir():
        fail("downloads directory not found", downloads_dir=str(downloads_dir))
    files = [path for path in downloads_dir.iterdir() if path.is_file() and not path.name.startswith(".")]
    files.sort(key=lambda item: item.stat().st_mtime, reverse=True)
    return files[:limit]


def doctor_checks(downloads_dir: Path) -> list[DoctorCheck]:
    checks: list[DoctorCheck] = []

    if downloads_dir.is_dir():
        visible_files = [path for path in downloads_dir.iterdir() if path.is_file() and not path.name.startswith(".")]
        if visible_files:
            newest = max(visible_files, key=lambda item: item.stat().st_mtime)
            checks.append(
                DoctorCheck(
                    key="downloads",
                    label="Downloads access",
                    status="ready",
                    detail=f"{len(visible_files)} visible files in {downloads_dir} · latest: {newest.name}",
                )
            )
        else:
            checks.append(
                DoctorCheck(
                    key="downloads",
                    label="Downloads access",
                    status="warning",
                    detail=f"{downloads_dir} is readable but currently empty",
                )
            )
    else:
        checks.append(
            DoctorCheck(
                key="downloads",
                label="Downloads access",
                status="limited",
                detail=f"{downloads_dir} is missing or not a folder",
            )
        )

    checks.append(
        DoctorCheck(
            key="metadata",
            label="Source hints",
            status="ready" if MDLS_BINARY else "warning",
            detail="Spotlight metadata is available for source hints" if MDLS_BINARY else "mdls is unavailable, so source hints will be omitted",
        )
    )
    checks.append(
        DoctorCheck(
            key="reveal",
            label="Reveal support",
            status="ready" if OPEN_BINARY else "limited",
            detail="Finder reveal is available through `open -R`" if OPEN_BINARY else "`open` is unavailable, so reveal mode will fail",
        )
    )
    checks.append(
        DoctorCheck(
            key="copy_path",
            label="Copy-path support",
            status="ready" if PBCOPY_BINARY else "limited",
            detail="pbcopy is available for copy-path actions" if PBCOPY_BINARY else "`pbcopy` is unavailable, so copy-path mode will fail",
        )
    )
    checks.append(
        DoctorCheck(
            key="safe_writes",
            label="Safe writes",
            status="ready",
            detail="Rename and move stay preview-first until `--yes` is passed",
        )
    )
    return checks


def render_doctor(checks: list[DoctorCheck], format_name: str) -> str:
    overall = "ready" if all(check.status == "ready" for check in checks) else "attention needed"

    if format_name == "json":
        return json.dumps(
            {
                "ok": True,
                "overall": overall,
                "checks": [asdict(check) for check in checks],
            },
            indent=2,
        )

    if format_name == "markdown":
        lines = [
            "# Download Landing Pad doctor",
            "",
            f"- Overall: {overall}",
            "",
        ]
        for check in checks:
            lines.append(f"- **{check.label}** · {check.status}")
            lines.append(f"  - {check.detail}")
        return "\n".join(lines)

    lines = [
        "Download Landing Pad doctor",
        f"Overall: {overall}",
    ]
    for check in checks:
        lines.append(f"- {check.label}: {check.status} — {check.detail}")
    return "\n".join(lines)


def resolve_target(target: str, downloads_dir: Path) -> Path:
    if target == "latest":
        matches = recent_downloads(downloads_dir, 1)
        if not matches:
            fail("no files found in downloads directory", downloads_dir=str(downloads_dir))
        return matches[0]

    candidate = Path(target).expanduser()
    if candidate.exists():
        return candidate.resolve()

    download_candidate = downloads_dir / target
    if download_candidate.exists():
        return download_candidate.resolve()

    fail("target file not found", target=target, downloads_dir=str(downloads_dir))


def render_list(items: list[DownloadItem], format_name: str) -> str:
    if format_name == "json":
        return json.dumps({"ok": True, "count": len(items), "items": [asdict(item) for item in items]}, indent=2)

    if format_name == "markdown":
        lines = [
            "# Recent downloads",
            "",
        ]
        for item in items:
            destinations = ", ".join(item.suggested_destinations)
            lines.append(f"- **{item.name}** · {item.kind} · {item.age} · {item.size}")
            lines.append(f"  - source: {item.source}")
            lines.append(f"  - suggested name: `{item.suggested_name}`")
            lines.append(f"  - route options: {destinations}")
        return "\n".join(lines)

    lines = []
    for index, item in enumerate(items, start=1):
        lines.append(
            f"{index}. {item.name} | {item.kind} | {item.age} | {item.size} | {item.source}"
        )
    return "\n".join(lines)


def render_brief(items: list[DownloadItem], format_name: str) -> str:
    if format_name == "json":
        return json.dumps(
            {
                "ok": True,
                "summary": "Sort the most recent downloads before they sink into Finder clutter.",
                "items": [asdict(item) for item in items],
            },
            indent=2,
        )

    if format_name == "markdown":
        lines = [
            "# Download Landing Pad brief",
            "",
            "Sort the newest files before they disappear into Finder clutter.",
            "",
        ]
        for item in items:
            destinations = ", ".join(item.suggested_destinations)
            lines.append(f"- **{item.name}**")
            lines.append(f"  - kind: {item.kind}")
            lines.append(f"  - source: {item.source}")
            lines.append(f"  - next rename: `{item.suggested_name}`")
            lines.append(f"  - route options: {destinations}")
        return "\n".join(lines)

    if format_name == "prompt":
        lines = [
            "Recent downloads to triage:",
        ]
        for item in items:
            destinations = ", ".join(item.suggested_destinations)
            lines.append(
                f"- {item.name} ({item.kind}, {item.age}, {item.size}, source: {item.source}) -> rename as {item.suggested_name}; route to {destinations}"
            )
        lines.append("Recommended next step: rename or move the top item before opening Finder.")
        return "\n".join(lines)

    lines = [
        "Download Landing Pad brief",
        "Sort the newest files before they disappear into Finder clutter.",
    ]
    for item in items:
        destinations = ", ".join(item.suggested_destinations)
        lines.append(
            f"- {item.name}: {item.kind}, {item.age}, {item.source}; rename to {item.suggested_name}; route to {destinations}"
        )
    return "\n".join(lines)


def rename_file(path: Path, new_name: str, yes: bool) -> dict[str, object]:
    sanitized = Path(new_name).name
    if sanitized != new_name:
        fail("new name must not include path separators", new_name=new_name)
    if not Path(sanitized).suffix and path.suffix:
        sanitized = f"{sanitized}{path.suffix.lower()}"
    destination = path.with_name(sanitized)
    if destination.exists():
        fail("destination file already exists", destination=str(destination))
    payload: dict[str, object] = {
        "ok": True,
        "action": "rename",
        "dry_run": not yes,
        "from": str(path),
        "to": str(destination),
    }
    if yes:
        path.rename(destination)
    return payload


def move_file(path: Path, destination_dir: str, yes: bool) -> dict[str, object]:
    directory = Path(destination_dir).expanduser().resolve()
    if not directory.is_dir():
        fail("destination directory not found", destination_dir=str(directory))
    destination = directory / path.name
    if destination.exists():
        fail("destination file already exists", destination=str(destination))
    payload: dict[str, object] = {
        "ok": True,
        "action": "move",
        "dry_run": not yes,
        "from": str(path),
        "to": str(destination),
    }
    if yes:
        shutil.move(str(path), str(destination))
    return payload


def reveal_file(path: Path) -> dict[str, object]:
    if OPEN_BINARY is None:
        fail("open is unavailable, so reveal mode cannot run", path=str(path))
    result = subprocess.run([OPEN_BINARY, "-R", str(path)], capture_output=True, check=False, text=True)
    if result.returncode != 0:
        fail("failed to reveal file in Finder", stderr=result.stderr.strip(), path=str(path))
    return {"ok": True, "action": "reveal", "path": str(path)}


def copy_path(path: Path) -> dict[str, object]:
    if PBCOPY_BINARY is None:
        fail("pbcopy is unavailable, so copy-path mode cannot run", path=str(path))
    result = subprocess.run([PBCOPY_BINARY], input=str(path), capture_output=True, check=False, text=True)
    if result.returncode != 0:
        fail("failed to copy path to clipboard", stderr=result.stderr.strip(), path=str(path))
    return {"ok": True, "action": "copy-path", "path": str(path)}


def main() -> int:
    parser = argparse.ArgumentParser(description="List and route recent macOS downloads without a Finder detour.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    doctor_parser = subparsers.add_parser("doctor", help="Check local Downloads readiness.")
    doctor_parser.add_argument("--downloads-dir", default=str(DEFAULT_DOWNLOADS_DIR))
    doctor_parser.add_argument("--format", choices=["plain", "markdown", "json"], default="plain")

    list_parser = subparsers.add_parser("list", help="List recent downloads.")
    list_parser.add_argument("--downloads-dir", default=str(DEFAULT_DOWNLOADS_DIR))
    list_parser.add_argument("--limit", type=int, default=DEFAULT_LIMIT)
    list_parser.add_argument("--format", choices=["plain", "markdown", "json"], default="plain")

    brief_parser = subparsers.add_parser("brief", help="Render a concise download triage brief.")
    brief_parser.add_argument("--downloads-dir", default=str(DEFAULT_DOWNLOADS_DIR))
    brief_parser.add_argument("--limit", type=int, default=DEFAULT_LIMIT)
    brief_parser.add_argument("--format", choices=["plain", "markdown", "prompt", "json"], default="plain")

    rename_parser = subparsers.add_parser("rename", help="Rename a selected download.")
    rename_parser.add_argument("target", help="A file path, relative name in Downloads, or `latest`.")
    rename_parser.add_argument("--downloads-dir", default=str(DEFAULT_DOWNLOADS_DIR))
    rename_parser.add_argument("--name", required=True, help="New file name.")
    rename_parser.add_argument("--yes", action="store_true", help="Actually rename the file.")

    move_parser = subparsers.add_parser("move", help="Move a selected download into an explicit folder.")
    move_parser.add_argument("target", help="A file path, relative name in Downloads, or `latest`.")
    move_parser.add_argument("--downloads-dir", default=str(DEFAULT_DOWNLOADS_DIR))
    move_parser.add_argument("--to", required=True, help="Destination directory.")
    move_parser.add_argument("--yes", action="store_true", help="Actually move the file.")

    reveal_parser = subparsers.add_parser("reveal", help="Reveal a selected download in Finder.")
    reveal_parser.add_argument("target", help="A file path, relative name in Downloads, or `latest`.")
    reveal_parser.add_argument("--downloads-dir", default=str(DEFAULT_DOWNLOADS_DIR))

    copy_parser = subparsers.add_parser("copy-path", help="Copy the selected file path to the clipboard.")
    copy_parser.add_argument("target", help="A file path, relative name in Downloads, or `latest`.")
    copy_parser.add_argument("--downloads-dir", default=str(DEFAULT_DOWNLOADS_DIR))

    args = parser.parse_args()

    if args.command == "doctor":
        downloads_dir = Path(args.downloads_dir).expanduser().resolve()
        print(render_doctor(doctor_checks(downloads_dir), args.format))
        return 0

    if args.command in {"list", "brief"}:
        downloads_dir = Path(args.downloads_dir).expanduser().resolve()
        items = [build_item(path) for path in recent_downloads(downloads_dir, args.limit)]
        rendered = render_list(items, args.format) if args.command == "list" else render_brief(items, args.format)
        print(rendered)
        return 0

    downloads_dir = Path(args.downloads_dir).expanduser().resolve()
    target = resolve_target(args.target, downloads_dir)

    if args.command == "rename":
        print(json.dumps(rename_file(target, args.name, args.yes), indent=2))
        return 0
    if args.command == "move":
        print(json.dumps(move_file(target, args.to, args.yes), indent=2))
        return 0
    if args.command == "reveal":
        print(json.dumps(reveal_file(target), indent=2))
        return 0
    if args.command == "copy-path":
        print(json.dumps(copy_path(target), indent=2))
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
