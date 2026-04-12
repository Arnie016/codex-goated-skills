#!/usr/bin/env python3
"""Normalize browser or clipboard meeting links into clean handoff formats."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from typing import Any
from urllib.parse import parse_qs, unquote, urlparse

SUPPORTED_BROWSERS = {
    "Safari": "safari",
    "Google Chrome": "chrome",
    "Brave Browser": "chrome",
    "Arc": "chrome",
    "Microsoft Edge": "chrome",
}

URL_RE = re.compile(r"https?://[^\s<>\]\)\"']+")


@dataclass
class MeetingLink:
    provider: str
    title: str
    url: str
    host: str
    code: str
    browser: str = ""

    def as_dict(self) -> dict[str, Any]:
        return {
            "provider": self.provider,
            "title": self.title,
            "url": self.url,
            "host": self.host,
            "code": self.code,
            "browser": self.browser,
        }


def fail(message: str) -> None:
    raise SystemExit(message)


def run_command(command: list[str], *, input_text: str | None = None) -> str:
    try:
        result = subprocess.run(
            command,
            input=input_text,
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as error:
        fail(f"Missing required command: {command[0]}")
        raise AssertionError from error
    except subprocess.CalledProcessError as error:
        message = (error.stderr or error.stdout or "").strip() or f"{command[0]} failed."
        fail(message)
        raise AssertionError from error
    return result.stdout.strip()


def run_osascript(script: str) -> str:
    return run_command(["osascript", "-e", script])


def frontmost_app() -> str:
    script = """
    tell application "System Events"
        set frontApp to name of first application process whose frontmost is true
    end tell
    return frontApp
    """
    return run_osascript(script)


def current_tab(browser: str) -> dict[str, str]:
    browser_kind = SUPPORTED_BROWSERS.get(browser)
    if not browser_kind:
        supported = ", ".join(sorted(SUPPORTED_BROWSERS))
        fail(f"Unsupported browser: {browser}. Supported browsers: {supported}")

    if browser_kind == "safari":
        script = f"""
        tell application "{browser}"
            if not (exists front window) then error "{browser} has no open window."
            set tabTitle to name of current tab of front window
            set tabURL to URL of current tab of front window
            return tabTitle & linefeed & tabURL
        end tell
        """
    else:
        script = f"""
        tell application "{browser}"
            if (count of windows) is 0 then error "{browser} has no open window."
            set tabTitle to title of active tab of front window
            set tabURL to URL of active tab of front window
            return tabTitle & linefeed & tabURL
        end tell
        """

    output = run_osascript(script)
    parts = output.splitlines()
    if len(parts) < 2:
        fail(f"Unexpected tab payload from {browser}: {output!r}")
    return {"title": parts[0].strip(), "url": parts[1].strip(), "browser": browser}


def clipboard_text() -> str:
    return run_command(["pbpaste"])


def copy_text(text: str) -> None:
    run_command(["pbcopy"], input_text=text)


def extract_url(text: str) -> str:
    match = URL_RE.search(text.strip())
    if not match:
        fail("No meeting URL found in the provided text.")
    return match.group(0).rstrip(".,)")


def clean_title(raw_title: str, provider: str, code: str) -> str:
    title = re.sub(r"\s*[|\-]\s*(Microsoft Teams|Google Meet|Zoom|Webex)\s*$", "", raw_title).strip()
    if title:
        return title
    if code:
        return f"{provider} meeting {code}"
    return f"{provider} meeting"


def detect_provider(url: str) -> tuple[str, str]:
    parsed = urlparse(url)
    host = parsed.netloc.lower()
    path = parsed.path or ""
    query = parse_qs(parsed.query)

    if host.endswith("teams.microsoft.com") or host.endswith("teams.live.com"):
        meeting_id = query.get("meetingId", [""])[0].strip()
        if meeting_id:
            return "Microsoft Teams", meeting_id
        encoded = path.rsplit("/", 1)[-1]
        decoded = unquote(encoded)
        match = re.search(r"meeting_[^@]+", decoded)
        return "Microsoft Teams", match.group(0)[:18] if match else ""

    if host.endswith("meet.google.com"):
        code = path.strip("/").split("/")[-1]
        return "Google Meet", code

    if host.endswith("zoom.us") or host.endswith("zoomgov.com"):
        parts = [part for part in path.split("/") if part]
        if "j" in parts:
            index = parts.index("j")
            if index + 1 < len(parts):
                return "Zoom", parts[index + 1]
        if "wc" in parts and "join" in parts:
            join_index = parts.index("join")
            if join_index + 1 < len(parts):
                return "Zoom", parts[join_index + 1]
        digits = re.search(r"/(\d{6,})", path)
        return "Zoom", digits.group(1) if digits else ""

    if host.endswith("webex.com"):
        mtid = query.get("MTID", [""])[0].strip()
        if mtid:
            return "Webex", mtid
        slug = path.strip("/").split("/")[-1]
        return "Webex", slug

    fail(f"Unsupported meeting host: {host or 'unknown host'}")
    raise AssertionError


def meeting_from_text(text: str, *, title: str = "", browser: str = "") -> MeetingLink:
    url = extract_url(text)
    parsed = urlparse(url)
    host = parsed.netloc.lower()
    provider, code = detect_provider(url)
    normalized_title = clean_title(title, provider, code)
    return MeetingLink(
        provider=provider,
        title=normalized_title,
        url=url,
        host=host,
        code=code,
        browser=browser,
    )


def format_meeting(meeting: MeetingLink, style: str) -> str:
    if style == "json":
        return json.dumps(meeting.as_dict(), indent=2, ensure_ascii=False)
    if style == "plain":
        return f"{meeting.title}\n{meeting.url}"
    if style == "markdown":
        return f"- [{meeting.title}]({meeting.url})\n  Provider: {meeting.provider}"
    if style == "note":
        return (
            f"Meeting: {meeting.title}\n"
            f"Provider: {meeting.provider}\n"
            f"Join: {meeting.url}"
        )
    if style == "email":
        return (
            f"Subject: {meeting.title}\n\n"
            f"Join link: {meeting.url}\n"
            f"Provider: {meeting.provider}\n"
            "Fallback: Open in the browser if the native app is unavailable."
        )
    if style == "prompt":
        return (
            "Meeting handoff\n"
            f"Title: {meeting.title}\n"
            f"Provider: {meeting.provider}\n"
            f"Join URL: {meeting.url}\n"
            "Next action: open the join link or paste the note into the next destination."
        )
    fail(f"Unsupported format: {style}")
    raise AssertionError


def command_current(args: argparse.Namespace) -> int:
    browser = args.browser or frontmost_app()
    payload = current_tab(browser)
    meeting = meeting_from_text(payload["url"], title=payload["title"], browser=payload["browser"])
    text = format_meeting(meeting, args.format)
    if args.copy:
        copy_text(text)
    print(text)
    return 0


def command_clipboard(args: argparse.Namespace) -> int:
    meeting = meeting_from_text(clipboard_text())
    text = format_meeting(meeting, args.format)
    if args.copy:
        copy_text(text)
    print(text)
    return 0


def command_parse(args: argparse.Namespace) -> int:
    meeting = meeting_from_text(args.text, title=args.title or "")
    text = format_meeting(meeting, args.format)
    if args.copy:
        copy_text(text)
    print(text)
    return 0


def command_open(args: argparse.Namespace) -> int:
    text = args.text if args.text is not None else clipboard_text()
    meeting = meeting_from_text(text)
    subprocess.run(["open", meeting.url], check=True)
    print(meeting.url)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    current_parser = subparsers.add_parser("current", help="Read the current meeting link from the front browser tab.")
    current_parser.add_argument("--browser", help="Browser override. Defaults to the frontmost supported browser.")
    current_parser.add_argument(
        "--format",
        default="json",
        choices=["json", "plain", "markdown", "note", "email", "prompt"],
        help="Output format for the normalized meeting payload.",
    )
    current_parser.add_argument("--copy", action="store_true", help="Copy the formatted output to the clipboard.")
    current_parser.set_defaults(func=command_current)

    clipboard_parser = subparsers.add_parser("clipboard", help="Parse the first meeting URL from the clipboard.")
    clipboard_parser.add_argument(
        "--format",
        default="json",
        choices=["json", "plain", "markdown", "note", "email", "prompt"],
        help="Output format for the normalized meeting payload.",
    )
    clipboard_parser.add_argument("--copy", action="store_true", help="Copy the formatted output to the clipboard.")
    clipboard_parser.set_defaults(func=command_clipboard)

    parse_parser = subparsers.add_parser("parse", help="Parse a pasted meeting URL or text snippet.")
    parse_parser.add_argument("text", help="Meeting URL or text containing a meeting URL.")
    parse_parser.add_argument("--title", help="Optional title override for the meeting.")
    parse_parser.add_argument(
        "--format",
        default="json",
        choices=["json", "plain", "markdown", "note", "email", "prompt"],
        help="Output format for the normalized meeting payload.",
    )
    parse_parser.add_argument("--copy", action="store_true", help="Copy the formatted output to the clipboard.")
    parse_parser.set_defaults(func=command_parse)

    open_parser = subparsers.add_parser(
        "open",
        help="Open a meeting URL with the default macOS handler. Defaults to the clipboard when no text is passed.",
    )
    open_parser.add_argument("text", nargs="?", help="Meeting URL or text containing a meeting URL.")
    open_parser.set_defaults(func=command_open)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
