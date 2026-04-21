#!/usr/bin/env python3
"""Manage a local reply queue for copied comments and inbox snippets."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import Any


DEFAULT_STATE_PATH = Path.home() / ".codex" / "reply-queue-bar" / "queue.json"
BUCKET_ORDER = {"urgent": 0, "reusable": 1, "archive": 2}
URGENCY_ORDER = {"high": 0, "normal": 1, "low": 2}


@dataclass
class QueueItem:
    id: str
    source: str
    text: str
    bucket: str
    urgency: str
    status: str
    tags: list[str]
    draft: str
    created_at: str
    updated_at: str


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def utc_stamp() -> str:
    return utc_now().isoformat()


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def fail(message: str) -> None:
    raise SystemExit(f"Error: {message}")


def load_items(state_path: Path) -> list[QueueItem]:
    if not state_path.is_file():
        return []

    payload = json.loads(state_path.read_text(encoding="utf-8"))
    items = payload.get("items", [])
    if not isinstance(items, list):
        fail(f"state file is invalid: {state_path}")

    queue_items: list[QueueItem] = []
    for raw_item in items:
        if not isinstance(raw_item, dict):
            continue
        queue_items.append(
            QueueItem(
                id=str(raw_item.get("id", "")),
                source=str(raw_item.get("source", "Clipboard")),
                text=str(raw_item.get("text", "")).strip(),
                bucket=str(raw_item.get("bucket", "urgent")),
                urgency=str(raw_item.get("urgency", "normal")),
                status=str(raw_item.get("status", "open")),
                tags=[str(tag) for tag in raw_item.get("tags", []) if str(tag).strip()],
                draft=str(raw_item.get("draft", "")).strip(),
                created_at=str(raw_item.get("created_at", "")),
                updated_at=str(raw_item.get("updated_at", "")),
            )
        )
    return queue_items


def save_items(state_path: Path, items: list[QueueItem]) -> None:
    ensure_parent(state_path)
    payload = {
        "version": 1,
        "updated_at": utc_stamp(),
        "items": [asdict(item) for item in items],
    }

    with NamedTemporaryFile("w", encoding="utf-8", delete=False, dir=state_path.parent) as handle:
        handle.write(json.dumps(payload, indent=2, ensure_ascii=True) + "\n")
        temp_path = Path(handle.name)

    temp_path.replace(state_path)


def generate_id() -> str:
    return utc_now().strftime("rqb-%Y%m%d-%H%M%S-%f")


def read_clipboard() -> str:
    result = subprocess.run(["pbpaste"], check=False, capture_output=True, text=True)
    if result.returncode != 0:
        fail("pbpaste is unavailable; use --text, --file, or stdin instead")
    text = result.stdout.strip()
    if not text:
        fail("clipboard is empty")
    return text


def read_text(args: argparse.Namespace) -> str:
    if getattr(args, "text", None):
        return str(args.text).strip()
    if getattr(args, "file", None):
        return Path(args.file).expanduser().read_text(encoding="utf-8").strip()
    if getattr(args, "clipboard", False):
        return read_clipboard()
    if not sys.stdin.isatty():
        text = sys.stdin.read().strip()
        if text:
            return text
    fail("provide --text, --file, --clipboard, or piped stdin")
    return ""


def write_clipboard(text: str) -> None:
    result = subprocess.run(["pbcopy"], input=text, check=False, text=True)
    if result.returncode != 0:
        fail("pbcopy is unavailable")


def normalize_tags(raw_tags: list[str]) -> list[str]:
    ordered: list[str] = []
    seen: set[str] = set()
    for raw_tag in raw_tags:
        for part in raw_tag.split(","):
            tag = part.strip().lower()
            if not tag or tag in seen:
                continue
            seen.add(tag)
            ordered.append(tag)
    return ordered


def actionable_items(items: list[QueueItem]) -> list[QueueItem]:
    ranked = [
        item
        for item in items
        if item.status == "open" and item.bucket in {"urgent", "reusable"}
    ]
    return sorted(
        ranked,
        key=lambda item: (
            BUCKET_ORDER.get(item.bucket, 99),
            URGENCY_ORDER.get(item.urgency, 99),
            item.created_at,
        ),
    )


def find_item(items: list[QueueItem], item_id: str | None, allow_archived: bool = False) -> QueueItem:
    if item_id:
        for item in items:
            if item.id == item_id:
                if item.status == "archived" and not allow_archived:
                    fail(f"item {item_id} is already archived")
                return item
        fail(f"could not find item {item_id}")

    next_items = actionable_items(items)
    if next_items:
        return next_items[0]

    if allow_archived:
        archived = [item for item in items if item.status == "archived"]
        if archived:
            return archived[-1]

    fail("there is no actionable reply item in the queue")
    return items[0]


def queue_counts(items: list[QueueItem]) -> dict[str, int]:
    counts = {"urgent": 0, "reusable": 0, "archive": 0, "archived": 0}
    for item in items:
        if item.status == "archived":
            counts["archived"] += 1
            continue
        counts[item.bucket] = counts.get(item.bucket, 0) + 1
    return counts


def shorten(text: str, width: int = 88) -> str:
    compact = " ".join(text.split())
    if len(compact) <= width:
        return compact
    return compact[: width - 1].rstrip() + "…"


def render_item_line(item: QueueItem) -> str:
    tags = f" · tags: {', '.join(item.tags)}" if item.tags else ""
    return f"{item.id} · {item.source} · {item.bucket}/{item.urgency}{tags}"


def build_snapshot(items: list[QueueItem], limit: int) -> dict[str, Any]:
    open_items = [item for item in items if item.status == "open"]
    next_item = actionable_items(items)[0] if actionable_items(items) else None
    listed = sorted(
        open_items,
        key=lambda item: (
            BUCKET_ORDER.get(item.bucket, 99),
            URGENCY_ORDER.get(item.urgency, 99),
            item.created_at,
        ),
    )[:limit]
    return {
        "generated_at": utc_stamp(),
        "counts": queue_counts(items),
        "open_count": len(open_items),
        "next_item": asdict(next_item) if next_item else None,
        "items": [asdict(item) for item in listed],
    }


def render_snapshot(snapshot: dict[str, Any], format_name: str) -> str:
    if format_name == "json":
        return json.dumps(snapshot, indent=2, ensure_ascii=True)

    counts = snapshot["counts"]
    next_item = snapshot["next_item"]
    items = snapshot["items"]

    if format_name == "markdown":
        lines = [
            "# Reply queue snapshot",
            "",
            f"- Open items: {snapshot['open_count']}",
            f"- Urgent: {counts['urgent']}",
            f"- Reusable: {counts['reusable']}",
            f"- Archive bucket: {counts['archive']}",
            f"- Archived: {counts['archived']}",
            "",
        ]
        if next_item:
            lines.extend(
                [
                    "## Next reply",
                    "",
                    f"- `{next_item['id']}` · {next_item['source']} · {next_item['bucket']}/{next_item['urgency']}",
                    f"- {shorten(next_item['text'])}",
                    f"- Draft: {shorten(next_item['draft']) if next_item['draft'] else 'None yet'}",
                    "",
                ]
            )
        if items:
            lines.extend(["## Queue", ""])
            for item in items:
                tag_text = ", ".join(item["tags"]) if item["tags"] else "no tags"
                lines.append(
                    f"- `{item['id']}` · {item['source']} · {item['bucket']}/{item['urgency']} · {tag_text}"
                )
                lines.append(f"  {shorten(item['text'])}")
        return "\n".join(lines).rstrip()

    if format_name == "prompt":
        lines = [
            "Use this local reply queue snapshot to decide what deserves the next response.",
            f"Open queue: urgent={counts['urgent']}, reusable={counts['reusable']}, archive={counts['archive']}, archived={counts['archived']}.",
        ]
        if next_item:
            lines.append(
                f"Next reply candidate: {next_item['id']} from {next_item['source']} "
                f"({next_item['bucket']}/{next_item['urgency']})."
            )
            lines.append(f"Snippet: {shorten(next_item['text'])}")
            if next_item["draft"]:
                lines.append(f"Current draft: {shorten(next_item['draft'])}")
            else:
                lines.append("Current draft: none yet.")
        if items:
            lines.append("Other open items:")
            for item in items[:5]:
                lines.append(
                    f"- {item['id']} · {item['source']} · {item['bucket']}/{item['urgency']} · {shorten(item['text'], 72)}"
                )
        return "\n".join(lines)

    lines = [
        "Reply Queue Bar",
        f"Open items: {snapshot['open_count']}",
        f"Urgent: {counts['urgent']} · Reusable: {counts['reusable']} · Archive bucket: {counts['archive']} · Archived: {counts['archived']}",
    ]
    if next_item:
        lines.extend(
            [
                "",
                "Next reply",
                render_item_line(QueueItem(**next_item)),
                shorten(next_item["text"]),
                f"Draft: {shorten(next_item['draft']) if next_item['draft'] else 'None yet'}",
            ]
        )
    if items:
        lines.append("")
        lines.append("Queue")
        for item in items:
            lines.append(f"- {item['id']} · {item['source']} · {item['bucket']}/{item['urgency']}")
            lines.append(f"  {shorten(item['text'])}")
    return "\n".join(lines)


def print_item(item: QueueItem, format_name: str) -> str:
    payload = asdict(item)
    if format_name == "json":
        return json.dumps(payload, indent=2, ensure_ascii=True)
    if format_name == "markdown":
        lines = [
            f"# {item.id}",
            "",
            f"- Source: {item.source}",
            f"- Bucket: {item.bucket}",
            f"- Urgency: {item.urgency}",
            f"- Status: {item.status}",
            f"- Tags: {', '.join(item.tags) if item.tags else 'none'}",
            "",
            "## Snippet",
            "",
            item.text,
            "",
            "## Draft",
            "",
            item.draft or "No draft yet.",
        ]
        return "\n".join(lines)
    return (
        f"{render_item_line(item)}\n"
        f"Snippet: {item.text}\n"
        f"Draft: {item.draft or 'No draft yet.'}"
    )


def cmd_capture(args: argparse.Namespace) -> int:
    state_path = Path(args.state_file).expanduser()
    items = load_items(state_path)
    text = read_text(args)
    now = utc_stamp()
    item = QueueItem(
        id=generate_id(),
        source=args.source.strip() or "Clipboard",
        text=text,
        bucket=args.bucket,
        urgency=args.urgency,
        status="open",
        tags=normalize_tags(args.tag),
        draft=(args.draft or "").strip(),
        created_at=now,
        updated_at=now,
    )
    items.append(item)
    save_items(state_path, items)
    print(print_item(item, args.format))
    return 0


def cmd_brief(args: argparse.Namespace) -> int:
    state_path = Path(args.state_file).expanduser()
    snapshot = build_snapshot(load_items(state_path), limit=args.limit)
    rendered = render_snapshot(snapshot, args.format)
    if args.copy:
        write_clipboard(rendered)
    print(rendered)
    return 0


def cmd_list(args: argparse.Namespace) -> int:
    state_path = Path(args.state_file).expanduser()
    items = load_items(state_path)
    if args.status != "all":
        items = [item for item in items if item.status == args.status]
    if args.bucket != "all":
        items = [item for item in items if item.bucket == args.bucket]
    items = sorted(
        items,
        key=lambda item: (
            1 if item.status == "archived" else 0,
            BUCKET_ORDER.get(item.bucket, 99),
            URGENCY_ORDER.get(item.urgency, 99),
            item.created_at,
        ),
    )[: args.limit]
    snapshot = {
        "generated_at": utc_stamp(),
        "counts": queue_counts(load_items(state_path)),
        "open_count": len([item for item in items if item.status == "open"]),
        "next_item": None,
        "items": [asdict(item) for item in items],
    }
    rendered = render_snapshot(snapshot, args.format)
    if args.copy:
        write_clipboard(rendered)
    print(rendered)
    return 0


def cmd_draft(args: argparse.Namespace) -> int:
    state_path = Path(args.state_file).expanduser()
    items = load_items(state_path)
    item = find_item(items, args.id)
    item.draft = read_text(args)
    item.updated_at = utc_stamp()
    save_items(state_path, items)
    output = item.draft if args.copy_draft else print_item(item, args.format)
    if args.copy or args.copy_draft:
        write_clipboard(output)
    print(output)
    return 0


def cmd_archive(args: argparse.Namespace) -> int:
    state_path = Path(args.state_file).expanduser()
    items = load_items(state_path)
    item = find_item(items, args.id)
    item.status = "archived"
    if args.move_to_archive_bucket:
        item.bucket = "archive"
    item.updated_at = utc_stamp()
    save_items(state_path, items)
    print(print_item(item, args.format))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage a local reply queue for copied snippets.")
    parser.add_argument(
        "--state-file",
        default=str(DEFAULT_STATE_PATH),
        help="Path to the local reply queue state file",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    capture = sub.add_parser("capture", help="Capture a new reply item")
    capture.add_argument("--text", help="Reply snippet text")
    capture.add_argument("--file", help="Path to a text file to ingest")
    capture.add_argument("--clipboard", action="store_true", help="Read the snippet from pbpaste")
    capture.add_argument("--source", default="Clipboard", help="Source label for the snippet")
    capture.add_argument("--bucket", choices=["urgent", "reusable", "archive"], default="urgent")
    capture.add_argument("--urgency", choices=["high", "normal", "low"], default="normal")
    capture.add_argument("--tag", action="append", default=[], help="Tag value; repeat or comma-separate")
    capture.add_argument("--draft", help="Optional starter draft")
    capture.add_argument("--format", choices=["plain", "markdown", "json"], default="plain")
    capture.set_defaults(func=cmd_capture)

    brief = sub.add_parser("brief", help="Render a queue summary")
    brief.add_argument("--limit", type=int, default=5, help="Maximum open items to show")
    brief.add_argument("--format", choices=["plain", "markdown", "prompt", "json"], default="plain")
    brief.add_argument("--copy", action="store_true", help="Copy the rendered output to the clipboard")
    brief.set_defaults(func=cmd_brief)

    list_cmd = sub.add_parser("list", help="List queue items")
    list_cmd.add_argument("--limit", type=int, default=10, help="Maximum items to show")
    list_cmd.add_argument("--bucket", choices=["all", "urgent", "reusable", "archive"], default="all")
    list_cmd.add_argument("--status", choices=["all", "open", "archived"], default="open")
    list_cmd.add_argument("--format", choices=["plain", "markdown", "prompt", "json"], default="plain")
    list_cmd.add_argument("--copy", action="store_true", help="Copy the rendered output to the clipboard")
    list_cmd.set_defaults(func=cmd_list)

    draft = sub.add_parser("draft", help="Attach or replace a draft on a queue item")
    draft.add_argument("--id", help="Queue item id; defaults to the next actionable item")
    draft.add_argument("--text", help="Draft text")
    draft.add_argument("--file", help="Read draft text from a file")
    draft.add_argument("--clipboard", action="store_true", help="Read draft text from pbpaste")
    draft.add_argument("--format", choices=["plain", "markdown", "json"], default="plain")
    draft.add_argument("--copy", action="store_true", help="Copy the rendered item output to the clipboard")
    draft.add_argument("--copy-draft", action="store_true", help="Copy only the saved draft text to the clipboard")
    draft.set_defaults(func=cmd_draft)

    archive = sub.add_parser("archive", help="Archive a queue item")
    archive.add_argument("--id", help="Queue item id; defaults to the next actionable item")
    archive.add_argument("--move-to-archive-bucket", action="store_true", help="Also move the item to the archive bucket")
    archive.add_argument("--format", choices=["plain", "markdown", "json"], default="plain")
    archive.set_defaults(func=cmd_archive)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
