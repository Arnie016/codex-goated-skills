#!/usr/bin/env python3
"""Fetch public RSS or Atom feeds into a lightweight trading article archive."""

from __future__ import annotations

import argparse
import datetime as dt
import email.utils
import html
import json
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET


USER_AGENT = "codex-goated-skills/trading-archive"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fetch and merge RSS or Atom feeds into a reading archive.")
    parser.add_argument("--feed-url", action="append", required=True, help="Repeat for each public RSS or Atom feed URL.")
    parser.add_argument("--limit", type=int, default=20, help="Maximum number of merged entries to return.")
    parser.add_argument("--days", type=int, default=30, help="Only keep entries newer than this many days when dated.")
    parser.add_argument("--query", help="Filter merged entries by a simple case-insensitive query.")
    parser.add_argument("--format", choices=["json", "markdown"], default="markdown", help="Output format.")
    return parser.parse_args()


def fetch_url(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/rss+xml, application/atom+xml, application/xml, text/xml"})
    with urllib.request.urlopen(request, timeout=20) as response:
        return response.read()


def strip_html(text: str) -> str:
    clean = re.sub(r"<[^>]+>", " ", text or "")
    clean = html.unescape(clean)
    return " ".join(clean.split())


def parse_date(value: str | None) -> str | None:
    if not value:
        return None
    value = value.strip()
    if not value:
        return None
    try:
        parsed = email.utils.parsedate_to_datetime(value)
        if parsed is not None:
            return parsed.astimezone(dt.timezone.utc).isoformat()
    except (TypeError, ValueError):
        pass
    for fmt in (
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%S.%f%z",
        "%Y-%m-%dT%H:%M:%SZ",
    ):
        try:
            parsed = dt.datetime.strptime(value, fmt)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=dt.timezone.utc)
            return parsed.astimezone(dt.timezone.utc).isoformat()
        except ValueError:
            continue
    return None


def child_text(element: ET.Element, names: list[str]) -> str:
    for name in names:
        child = element.find(name)
        if child is not None and child.text:
            return child.text.strip()
    return ""


def parse_feed(xml_bytes: bytes, source_url: str) -> tuple[str, list[dict[str, object]]]:
    root = ET.fromstring(xml_bytes)
    tag = root.tag.lower()
    namespace = ""
    if tag.startswith("{"):
        namespace = tag.split("}", 1)[0] + "}"

    if tag.endswith("rss") or tag.endswith("rdf"):
        channel = root.find("channel")
        source_name = child_text(channel if channel is not None else root, ["title"]) or source_url
        items = []
        for item in root.findall(".//item"):
            link = child_text(item, ["link"])
            title = child_text(item, ["title"]) or "Untitled article"
            summary = child_text(item, ["description"])
            published = parse_date(child_text(item, ["pubDate"]))
            tags = [strip_html(category.text or "") for category in item.findall("category") if (category.text or "").strip()]
            items.append(
                {
                    "id": (child_text(item, ["guid"]) or link or title).lower(),
                    "title": strip_html(title),
                    "summary": strip_html(summary),
                    "source": strip_html(source_name),
                    "link": link,
                    "published_at": published,
                    "tags": sorted(set(filter(None, tags))),
                }
            )
        return strip_html(source_name), items

    source_name = child_text(root, [f"{namespace}title"]) or source_url
    items = []
    for entry in root.findall(f".//{namespace}entry"):
        link = ""
        for link_element in entry.findall(f"{namespace}link"):
            href = link_element.attrib.get("href", "").strip()
            if href:
                link = href
                break
        title = child_text(entry, [f"{namespace}title"]) or "Untitled article"
        summary = child_text(entry, [f"{namespace}summary", f"{namespace}content"])
        published = parse_date(child_text(entry, [f"{namespace}updated", f"{namespace}published"]))
        tags = [strip_html(element.attrib.get("term", "")) for element in entry.findall(f"{namespace}category") if element.attrib.get("term", "").strip()]
        items.append(
            {
                "id": (child_text(entry, [f"{namespace}id"]) or link or title).lower(),
                "title": strip_html(title),
                "summary": strip_html(summary),
                "source": strip_html(source_name),
                "link": link,
                "published_at": published,
                "tags": sorted(set(filter(None, tags))),
            }
        )
    return strip_html(source_name), items


def filter_and_merge(all_items: list[dict[str, object]], days: int, query: str | None, limit: int) -> list[dict[str, object]]:
    cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=max(days, 0))
    filtered = []
    for item in all_items:
        published = item.get("published_at")
        if isinstance(published, str):
            try:
                published_dt = dt.datetime.fromisoformat(published)
            except ValueError:
                published_dt = None
            if published_dt is not None and published_dt < cutoff:
                continue
        if query:
            haystack = " ".join(
                [
                    str(item.get("title", "")),
                    str(item.get("summary", "")),
                    str(item.get("source", "")),
                    " ".join(item.get("tags", [])),
                ]
            ).lower()
            if query.lower() not in haystack:
                continue
        filtered.append(item)

    deduped = {}
    for item in filtered:
        key = (item.get("link") or item.get("id") or item.get("title") or "").lower()
        if key not in deduped:
            deduped[key] = item

    def sort_key(item: dict[str, object]) -> tuple[int, str]:
        published = item.get("published_at")
        if isinstance(published, str):
            return (0, published)
        return (1, str(item.get("title", "")))

    return sorted(deduped.values(), key=sort_key, reverse=True)[0:limit]


def render_markdown(items: list[dict[str, object]], feed_reports: list[dict[str, object]]) -> str:
    lines = ["# Trading Archive Queue", ""]
    for item in items:
        lines.append(f"- **{item['title']}**")
        lines.append(f"  - Source: {item['source']}")
        if item.get("published_at"):
            lines.append(f"  - Published: {item['published_at']}")
        if item.get("summary"):
            lines.append(f"  - Summary: {item['summary']}")
        if item.get("link"):
            lines.append(f"  - Link: {item['link']}")
    lines.append("")
    lines.append("## Source Health")
    for report in feed_reports:
        lines.append(f"- {report['source']}: {report['status']} ({report['count']} articles)")
        if report.get("note"):
            lines.append(f"  - {report['note']}")
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    all_items: list[dict[str, object]] = []
    feed_reports: list[dict[str, object]] = []

    for feed_url in args.feed_url:
        try:
            payload = fetch_url(feed_url)
            source_name, items = parse_feed(payload, feed_url)
            all_items.extend(items)
            feed_reports.append({"source": source_name, "url": feed_url, "status": "live", "count": len(items), "note": ""})
        except Exception as exc:  # noqa: BLE001
            feed_reports.append({"source": feed_url, "url": feed_url, "status": "failed", "count": 0, "note": str(exc)})

    merged = filter_and_merge(all_items, days=args.days, query=args.query, limit=args.limit)
    result = {
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "feed_count": len(args.feed_url),
        "article_count": len(merged),
        "articles": merged,
        "feeds": feed_reports,
    }

    if args.format == "json":
        json.dump(result, sys.stdout, indent=2, ensure_ascii=True)
        sys.stdout.write("\n")
    else:
        sys.stdout.write(render_markdown(merged, feed_reports))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
