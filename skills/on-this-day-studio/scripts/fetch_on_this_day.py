#!/usr/bin/env python3
"""Fetch and format the official Wikimedia On This Day feed."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path
from zoneinfo import ZoneInfo

API_TEMPLATE = "https://api.wikimedia.org/feed/v1/wikipedia/{language}/onthisday/all/{month}/{day}"
USER_AGENT = "codex-goated-skills/on-this-day-studio (https://github.com/Arnie016/codex-goated-skills)"
ALLOWED_TYPES = ("selected", "events", "births", "deaths", "holidays")


def normalize_text(value: object) -> str:
    return " ".join(str(value).split())


def resolve_date(raw_date: str | None, timezone_name: str) -> dt.date:
    if raw_date:
        return dt.date.fromisoformat(raw_date)
    return dt.datetime.now(ZoneInfo(timezone_name)).date()


def build_url(language: str, date_value: dt.date) -> str:
    return API_TEMPLATE.format(
        language=language,
        month=f"{date_value.month:02d}",
        day=f"{date_value.day:02d}",
    )


def fetch_payload(language: str, date_value: dt.date) -> dict[str, object]:
    request = urllib.request.Request(
        build_url(language, date_value),
        headers={
            "Accept": "application/json",
            "User-Agent": USER_AGENT,
        },
        method="GET",
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        raw = response.read().decode("utf-8")
    return json.loads(raw)


def pick_items(payload: dict[str, object], feed_type: str, limit: int) -> tuple[str, bool, list[dict[str, object]]]:
    items = payload.get(feed_type)
    if not isinstance(items, list):
        items = []

    fallback_used = False
    resolved_type = feed_type

    if feed_type == "selected" and not items:
        fallback = payload.get("events")
        if isinstance(fallback, list):
            items = fallback
            resolved_type = "events"
            fallback_used = True

    return resolved_type, fallback_used, items[:limit]


def normalize_item(feed_type: str, item: dict[str, object]) -> dict[str, str]:
    pages = item.get("pages")
    page = {}
    if isinstance(pages, list):
        for candidate in pages:
            if isinstance(candidate, dict):
                page = candidate
                if candidate.get("content_urls"):
                    break

    titles = page.get("titles") if isinstance(page.get("titles"), dict) else {}
    normalized_title = titles.get("normalized") if isinstance(titles, dict) else None
    title = normalized_title or page.get("normalizedtitle") or page.get("title") or feed_type.title()
    description = page.get("description") if isinstance(page.get("description"), str) else ""
    content_urls = page.get("content_urls") if isinstance(page.get("content_urls"), dict) else {}
    desktop_urls = content_urls.get("desktop") if isinstance(content_urls, dict) else {}
    url = desktop_urls.get("page") if isinstance(desktop_urls, dict) else ""
    year = item.get("year")

    year_label = str(year) if isinstance(year, int) else ("Holiday" if feed_type == "holidays" else "Archive")
    return {
        "year": year_label,
        "title": normalize_text(title),
        "text": normalize_text(item.get("text", "")),
        "description": normalize_text(description),
        "url": str(url),
    }


def render_markdown(
    date_value: dt.date,
    requested_type: str,
    resolved_type: str,
    fallback_used: bool,
    items: list[dict[str, str]],
    source_url: str,
    timezone_name: str,
) -> str:
    lines = [
        f"# On This Day · {date_value.strftime('%B')} {date_value.day}",
        "",
        f"- Date basis: `{date_value.isoformat()}` in `{timezone_name}`",
        f"- View: `{resolved_type}`",
        f"- Source: `{source_url}`",
    ]

    if requested_type != resolved_type or fallback_used:
        lines.append(f"- Fallback: requested `{requested_type}`, rendered `{resolved_type}`")

    lines.append("")

    for item in items:
        lines.append(f"- **{item['year']}** — {item['text']}")
        if item["url"]:
            lines.append(f"  - Link: {item['url']}")
        if item["description"]:
            lines.append(f"  - Context: {item['description']}")

    if not items:
        lines.append("No items returned for this date and view.")

    return "\n".join(lines) + "\n"


def render_json_payload(
    date_value: dt.date,
    language: str,
    requested_type: str,
    resolved_type: str,
    fallback_used: bool,
    items: list[dict[str, str]],
) -> str:
    payload = {
        "date": date_value.isoformat(),
        "language": language,
        "requested_type": requested_type,
        "resolved_type": resolved_type,
        "fallback_used": fallback_used,
        "source_url": build_url(language, date_value),
        "items": items,
    }
    return json.dumps(payload, indent=2, ensure_ascii=True) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fetch the official Wikimedia On This Day feed.")
    parser.add_argument("--date", help="Date in YYYY-MM-DD format. Defaults to today in the chosen timezone.")
    parser.add_argument("--timezone", default="Asia/Singapore", help="Timezone used when --date is omitted.")
    parser.add_argument("--language", default="en", help="Wikipedia language code. Default: en")
    parser.add_argument(
        "--type",
        default="selected",
        choices=ALLOWED_TYPES,
        help="Feed slice to render. Default: selected",
    )
    parser.add_argument("--limit", type=int, default=5, help="Maximum number of items to render. Default: 5")
    parser.add_argument(
        "--format",
        default="markdown",
        choices=("markdown", "json"),
        help="Output format. Default: markdown",
    )
    parser.add_argument("--output", help="Optional output file path.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    limit = max(1, min(args.limit, 20))

    try:
        date_value = resolve_date(args.date, args.timezone)
    except Exception as error:
        print(f"Error: invalid date or timezone: {error}", file=sys.stderr)
        return 1

    try:
        payload = fetch_payload(args.language, date_value)
    except urllib.error.HTTPError as error:
        print(f"Error: Wikimedia returned HTTP {error.code}", file=sys.stderr)
        return 1
    except urllib.error.URLError as error:
        print(f"Error: could not reach Wikimedia: {error.reason}", file=sys.stderr)
        return 1

    resolved_type, fallback_used, raw_items = pick_items(payload, args.type, limit)
    items = [normalize_item(resolved_type, item) for item in raw_items if isinstance(item, dict)]

    if args.format == "json":
        rendered = render_json_payload(
            date_value=date_value,
            language=args.language,
            requested_type=args.type,
            resolved_type=resolved_type,
            fallback_used=fallback_used,
            items=items,
        )
    else:
        rendered = render_markdown(
            date_value=date_value,
            requested_type=args.type,
            resolved_type=resolved_type,
            fallback_used=fallback_used,
            items=items,
            source_url=build_url(args.language, date_value),
            timezone_name=args.timezone,
        )

    if args.output:
        output_path = Path(args.output).expanduser().resolve()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(rendered, encoding="utf-8")
    else:
        sys.stdout.write(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
