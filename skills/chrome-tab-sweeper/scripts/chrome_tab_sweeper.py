#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
from collections import Counter
from urllib.parse import urlparse


TOKEN_RE = re.compile(r"^w(\d+):t(\d+)$")


def run_jxa(source: str) -> str:
    result = subprocess.run(
        ["osascript", "-l", "JavaScript", "-e", source],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit(
            json.dumps(
                {
                    "ok": False,
                    "error": "osascript failed",
                    "stderr": result.stderr.strip(),
                },
                indent=2,
            )
        )
    return result.stdout.strip()


def tab_domain(url: str) -> str:
    host = urlparse(url).netloc.lower()
    if host.startswith("www."):
        host = host[4:]
    return host or "untitled"


def list_tabs() -> dict:
    source = r"""
const chrome = Application("Google Chrome");
if (!chrome.running()) {
  JSON.stringify({ ok: true, running: false, tabs: [] });
} else {
  const rows = [];
  const windows = chrome.windows();
  for (let windowIndex = 0; windowIndex < windows.length; windowIndex++) {
    const tabs = windows[windowIndex].tabs();
    for (let tabIndex = 0; tabIndex < tabs.length; tabIndex++) {
      const tab = tabs[tabIndex];
      rows.push({
        token: `w${windowIndex + 1}:t${tabIndex + 1}`,
        window: windowIndex + 1,
        tab: tabIndex + 1,
        title: String(tab.title() || ""),
        url: String(tab.url() || "")
      });
    }
  }
  JSON.stringify({ ok: true, running: true, tabs: rows });
}
"""
    payload = json.loads(run_jxa(source))
    tabs = payload.get("tabs", [])
    for tab in tabs:
        tab["domain"] = tab_domain(tab.get("url", ""))
    domain_counts = Counter(tab["domain"] for tab in tabs)
    payload["count"] = len(tabs)
    payload["domain_counts"] = dict(domain_counts.most_common())
    payload["top_domains"] = [
        {"domain": domain, "count": count}
        for domain, count in domain_counts.most_common(10)
    ]
    return payload


def parse_tokens(tokens: list[str]) -> list[tuple[int, int, str]]:
    parsed = []
    for token in tokens:
        match = TOKEN_RE.fullmatch(token)
        if not match:
            raise SystemExit(
                json.dumps(
                    {"ok": False, "error": f"invalid token: {token}", "expected": "w1:t2"},
                    indent=2,
                )
            )
        parsed.append((int(match.group(1)), int(match.group(2)), token))
    return parsed


def close_tabs(tokens: list[str], yes: bool) -> dict:
    parsed = parse_tokens(tokens)
    if not yes:
        return {
            "ok": False,
            "dry_run": True,
            "message": "Add --yes to close these tab tokens.",
            "tokens": tokens,
        }

    # Close highest tab indices first so earlier indices stay valid inside a window.
    ordered = sorted(parsed, key=lambda item: (item[0], item[1]), reverse=True)
    source = f"""
const chrome = Application("Google Chrome");
const tokens = {json.dumps(ordered)};
const closed = [];
const skipped = [];
if (!chrome.running()) {{
  JSON.stringify({{ ok: false, error: "Google Chrome is not running", closed, skipped }});
}} else {{
  const windows = chrome.windows();
  for (const item of tokens) {{
    const windowIndex = item[0] - 1;
    const tabIndex = item[1] - 1;
    const token = item[2];
    try {{
      const win = windows[windowIndex];
      if (!win) {{
        skipped.push({{ token, reason: "window not found" }});
        continue;
      }}
      const tabs = win.tabs();
      const tab = tabs[tabIndex];
      if (!tab) {{
        skipped.push({{ token, reason: "tab not found" }});
        continue;
      }}
      const title = String(tab.title() || "");
      const url = String(tab.url() || "");
      tab.close();
      closed.push({{ token, title, url }});
    }} catch (error) {{
      skipped.push({{ token, reason: String(error) }});
    }}
  }}
  JSON.stringify({{ ok: skipped.length === 0, closed, skipped }});
}}
"""
    return json.loads(run_jxa(source))


def main() -> int:
    parser = argparse.ArgumentParser(description="List and close explicit Google Chrome tab tokens on macOS.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("list", help="List Chrome tabs as JSON with window/tab tokens.")

    close_parser = subparsers.add_parser("close", help="Close explicit tab tokens from a fresh list.")
    close_parser.add_argument("tokens", nargs="+", help="Tab tokens like w1:t2.")
    close_parser.add_argument("--yes", action="store_true", help="Actually close the provided tabs.")

    args = parser.parse_args()
    if args.command == "list":
        print(json.dumps(list_tabs(), indent=2))
        return 0
    if args.command == "close":
        print(json.dumps(close_tabs(args.tokens, args.yes), indent=2))
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
