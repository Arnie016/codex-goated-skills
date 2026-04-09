#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


COUNTER_API_BASE = os.environ.get("MACOS_ICON_BARS_COUNTER_API_BASE", "https://api.counterapi.dev/v1")
COUNTER_NAMESPACE = os.environ.get("MACOS_ICON_BARS_COUNTER_NAMESPACE", "arnie016-codex-goated-skills")
COUNTER_PREFIX = os.environ.get("MACOS_ICON_BARS_COUNTER_PREFIX", "macos-icon-bars")

COUNTERS = [
    ("One-command starts", "bootstrap-start"),
    ("One-command successes", "bootstrap-success"),
    ("Installer starts", "install-start"),
    ("Installer successes", "install-success"),
    ("Approx unique installs", "install-unique-success"),
    ("Installer failures", "install-failure"),
]


def fetch_json(url: str) -> dict | list | None:
    try:
        completed = subprocess.run(
            ["curl", "-fsSL", "--max-time", "8", url],
            capture_output=True,
            text=True,
            check=False,
        )
    except Exception:
        return None
    if completed.returncode != 0:
        return None
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError:
        return None


def fetch_counter(name: str) -> int:
    payload = fetch_json(f"{COUNTER_API_BASE}/{COUNTER_NAMESPACE}/{COUNTER_PREFIX}-{name}")
    if not isinstance(payload, dict):
        return 0
    value = payload.get("count", payload.get("data", payload.get("value", 0)))
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def fetch_daily_unique_rows() -> list[dict[str, object]]:
    payload = fetch_json(
        f"{COUNTER_API_BASE}/{COUNTER_NAMESPACE}/{COUNTER_PREFIX}-install-unique-success/list?group_by=day&order_by=desc"
    )
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        rows = payload.get("data", [])
        if isinstance(rows, list):
            return [item for item in rows if isinstance(item, dict)]
    return []


def render_markdown() -> str:
    rows = [(label, fetch_counter(name)) for label, name in COUNTERS]
    unique_daily = fetch_daily_unique_rows()
    rendered_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    total_table = "\n".join(f"| {label} | {value} |" for label, value in rows)

    if unique_daily:
        daily_table = "\n".join(
            f"| {item.get('Date', 'Unknown')} | {item.get('Value', item.get('count', 0))} |"
            for item in unique_daily[:14]
        )
    else:
        daily_table = "| No daily breakdown yet | 0 |"

    return f"""# macOS Icon Bars Metrics

Public install tracker for the `macOS Icon Bars` Codex plugin branch preview.

Last refreshed: {rendered_at}

## Totals

| Metric | Count |
| --- | ---: |
{total_table}

## Daily Approx Unique Installs

| Date | Approx unique installs |
| --- | ---: |
{daily_table}

## Notes

- `Approx unique installs` is counted once per Mac by storing a tiny local marker file after a successful install.
- Reinstalling on the same Mac should not increment that number unless the local tracking file is removed.
- These counters are anonymous aggregates. They do not include usernames, hostnames, or local file paths.
- The one-command install flow is:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Arnie016/codex-goated-skills/refs/heads/codex/macos-icon-bars-plugin/scripts/install_macos_icon_bars_from_github.sh)
```
"""


def main() -> int:
    output_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("MACOS_ICON_BARS_METRICS.md")
    output_path.write_text(render_markdown())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
