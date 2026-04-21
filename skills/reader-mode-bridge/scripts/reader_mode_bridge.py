#!/usr/bin/env python3
"""Turn copied reading input into a deterministic local handoff."""

from __future__ import annotations

import argparse
import json
import math
import re
import shutil
import subprocess
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse


SUPPORTED_BROWSERS = {
    "Safari": "safari",
    "Google Chrome": "chrome",
    "Brave Browser": "chrome",
    "Arc": "chrome",
    "Microsoft Edge": "chrome",
}

BROWSER_ALIASES = {
    "safari": "Safari",
    "chrome": "Google Chrome",
    "google-chrome": "Google Chrome",
    "brave": "Brave Browser",
    "arc": "Arc",
    "edge": "Microsoft Edge",
    "microsoft-edge": "Microsoft Edge",
}

HTML_SUFFIXES = {".html", ".htm", ".xhtml"}
MARKDOWN_SUFFIXES = {".md", ".markdown", ".mdown"}
PDF_SUFFIXES = {".pdf"}

BOILERPLATE_PATTERNS = [
    re.compile(pattern, re.IGNORECASE)
    for pattern in [
        r"^(share|share this|share article|share story)$",
        r"^(subscribe|subscribe now|subscribe today|sign up)$",
        r"^(sign in|log in|create account|open in app)$",
        r"^(cookie|cookie settings|cookie policy)$",
        r"^(advertisement|sponsored)$",
        r"^(follow us|follow me)$",
        r"^(read more|continue reading|next article|previous article)$",
        r"^(print|save|download pdf)$",
        r"^(privacy policy|terms of service|all rights reserved)$",
        r"^(listen$|listen to this article$)",
    ]
]


@dataclass
class TabMetadata:
    browser: str
    title: str
    url: str


@dataclass
class InputPayload:
    body: str
    input_kind: str
    source_label: str
    extracted_title: str | None = None
    extracted_url: str | None = None


@dataclass
class CleanedPayload:
    title: str
    source_label: str
    source_url: str | None
    input_kind: str
    word_count: int
    reading_minutes: int
    cleanup_notes: list[str]
    body: str


class ReaderHTMLParser(HTMLParser):
    """Extract readable text and a best-effort title from HTML."""

    BLOCK_TAGS = {
        "article",
        "blockquote",
        "br",
        "dd",
        "div",
        "dl",
        "dt",
        "figcaption",
        "figure",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "hr",
        "li",
        "main",
        "ol",
        "p",
        "pre",
        "section",
        "tr",
        "ul",
    }
    SKIP_TAGS = {
        "button",
        "footer",
        "form",
        "head",
        "iframe",
        "nav",
        "noscript",
        "script",
        "style",
        "svg",
    }

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self._skip_depth = 0
        self._in_title = False
        self._text_parts: list[str] = []
        self.title_candidates: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr_map = {key.lower(): value for key, value in attrs}

        if tag in self.SKIP_TAGS:
            self._skip_depth += 1
            return
        if self._skip_depth:
            return

        if tag == "title":
            self._in_title = True
            return

        if tag == "meta":
            property_name = (attr_map.get("property") or attr_map.get("name") or "").casefold()
            content = (attr_map.get("content") or "").strip()
            if property_name in {"og:title", "twitter:title"} and content:
                self.title_candidates.append(content)
            return

        if tag == "li":
            self._text_parts.append("\n- ")
            return

        if tag in self.BLOCK_TAGS:
            self._text_parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in self.SKIP_TAGS and self._skip_depth:
            self._skip_depth -= 1
            return
        if self._skip_depth:
            return
        if tag == "title":
            self._in_title = False
            return
        if tag in self.BLOCK_TAGS:
            self._text_parts.append("\n")

    def handle_data(self, data: str) -> None:
        if self._skip_depth:
            return
        text = data.strip()
        if not text:
            return
        if self._in_title:
            self.title_candidates.append(text)
            return
        self._text_parts.append(text)

    @property
    def text(self) -> str:
        return "".join(self._text_parts)


def run_command(command: list[str], *, input_text: str | None = None) -> str:
    try:
        result = subprocess.run(
            command,
            input=input_text,
            text=True,
            capture_output=True,
            check=True,
        )
    except FileNotFoundError as error:
        raise SystemExit(f"Missing required command: {command[0]}") from error
    except subprocess.CalledProcessError as error:
        message = (error.stderr or error.stdout or "").strip() or f"{command[0]} failed."
        raise SystemExit(message)
    return result.stdout


def run_osascript(script: str) -> str:
    return run_command(["osascript", "-e", script]).strip()


def resolve_browser(name: str) -> str:
    raw_name = name.strip()
    if raw_name in SUPPORTED_BROWSERS:
        return raw_name

    normalized = raw_name.casefold().replace("_", "-").replace(" ", "-")
    alias_target = BROWSER_ALIASES.get(normalized)
    if alias_target:
        return alias_target

    supported = ", ".join(sorted(SUPPORTED_BROWSERS))
    aliases = ", ".join(sorted(BROWSER_ALIASES))
    raise SystemExit(
        f"Unsupported browser: {name}. Supported browsers: {supported}. "
        f"Accepted aliases: {aliases}."
    )


def frontmost_app() -> str:
    script = """
    tell application "System Events"
        set frontApp to name of first application process whose frontmost is true
    end tell
    return frontApp
    """
    return run_osascript(script)


def front_tab(browser: str | None) -> TabMetadata:
    chosen_browser = resolve_browser(browser or frontmost_app())
    browser_kind = SUPPORTED_BROWSERS[chosen_browser]

    if browser_kind == "safari":
        script = f"""
        tell application "{chosen_browser}"
            if not (exists front window) then error "{chosen_browser} has no open window."
            set tabTitle to name of current tab of front window
            set tabURL to URL of current tab of front window
            return tabTitle & linefeed & tabURL
        end tell
        """
    else:
        script = f"""
        tell application "{chosen_browser}"
            if (count of windows) is 0 then error "{chosen_browser} has no open window."
            set tabTitle to title of active tab of front window
            set tabURL to URL of active tab of front window
            return tabTitle & linefeed & tabURL
        end tell
        """

    output = run_osascript(script)
    parts = [line.strip() for line in output.splitlines() if line.strip()]
    if len(parts) < 2:
        raise SystemExit(f"Unexpected tab payload from {chosen_browser}: {output!r}")
    return TabMetadata(browser=chosen_browser, title=parts[0], url=parts[1])


def clipboard_text() -> str:
    return run_command(["pbpaste"]).strip()


def looks_like_html(text: str) -> bool:
    sample = text[:400].casefold()
    return any(marker in sample for marker in ("<html", "<article", "<body", "<p", "<div", "<h1", "<section"))


def extract_pdf_text(path: Path) -> str:
    tool = shutil.which("pdftotext")
    if not tool:
        raise SystemExit(
            "pdftotext is required for PDF input. Install poppler or pass copied text with --text/--stdin."
        )
    return run_command([tool, "-q", "-nopgbrk", str(path), "-"]).strip()


def load_input(args: argparse.Namespace) -> InputPayload:
    if args.file:
        path = Path(args.file).expanduser().resolve()
        if not path.is_file():
            raise SystemExit(f"Input file not found: {path}")

        suffix = path.suffix.casefold()
        if suffix in PDF_SUFFIXES:
            return InputPayload(
                body=extract_pdf_text(path),
                input_kind="pdf",
                source_label=path.name,
                extracted_title=path.stem.replace("_", " ").replace("-", " ").strip() or None,
            )

        raw_text = path.read_text(encoding="utf-8")
        if suffix in HTML_SUFFIXES or looks_like_html(raw_text):
            parser = ReaderHTMLParser()
            parser.feed(raw_text)
            parser.close()
            title = first_nonempty(parser.title_candidates)
            return InputPayload(
                body=parser.text,
                input_kind="html",
                source_label=path.name,
                extracted_title=title,
            )

        input_kind = "markdown" if suffix in MARKDOWN_SUFFIXES else "text"
        return InputPayload(body=raw_text, input_kind=input_kind, source_label=path.name)

    if args.stdin:
        return InputPayload(body=sys_stdin_text(), input_kind="stdin", source_label="stdin")

    if args.text is not None:
        kind = "html" if looks_like_html(args.text) else "text"
        if kind == "html":
            parser = ReaderHTMLParser()
            parser.feed(args.text)
            parser.close()
            return InputPayload(
                body=parser.text,
                input_kind="html",
                source_label="inline text",
                extracted_title=first_nonempty(parser.title_candidates),
            )
        return InputPayload(body=args.text, input_kind="text", source_label="inline text")

    if args.clipboard:
        text = clipboard_text()
        if not text:
            raise SystemExit("Clipboard is empty.")
        kind = "html" if looks_like_html(text) else "clipboard"
        if kind == "html":
            parser = ReaderHTMLParser()
            parser.feed(text)
            parser.close()
            return InputPayload(
                body=parser.text,
                input_kind="html",
                source_label="clipboard",
                extracted_title=first_nonempty(parser.title_candidates),
            )
        return InputPayload(body=text, input_kind="clipboard", source_label="clipboard")

    raise SystemExit("Choose one input source: --file, --stdin, --text, or --clipboard.")


def sys_stdin_text() -> str:
    import sys

    text = sys.stdin.read().strip()
    if not text:
        raise SystemExit("No stdin content received.")
    return text


def first_nonempty(values: list[str]) -> str | None:
    for value in values:
        cleaned = normalize_inline_whitespace(value)
        if cleaned:
            return cleaned
    return None


def normalize_inline_whitespace(text: str) -> str:
    return re.sub(r"\s+", " ", text.replace("\xa0", " ")).strip()


def should_drop_line(line: str) -> bool:
    normalized = normalize_inline_whitespace(line)
    if not normalized:
        return False
    lowercase = normalized.casefold()
    if any(pattern.match(lowercase) for pattern in BOILERPLATE_PATTERNS):
        return True
    if len(normalized.split()) <= 4 and lowercase in {
        "share",
        "tweet",
        "email",
        "copy link",
        "menu",
        "next",
        "previous",
    }:
        return True
    return False


def split_clean_lines(text: str) -> tuple[list[str], int]:
    text = text.replace("\r\n", "\n").replace("\r", "\n").replace("\xa0", " ")
    lines = []
    removed = 0
    previous_nonempty = ""

    for raw_line in text.splitlines():
        normalized = normalize_inline_whitespace(raw_line)
        if not normalized:
            if lines and lines[-1] != "":
                lines.append("")
            continue
        if should_drop_line(normalized):
            removed += 1
            continue
        if normalized == previous_nonempty:
            removed += 1
            continue
        lines.append(normalized)
        previous_nonempty = normalized

    while lines and lines[0] == "":
        lines.pop(0)
    while lines and lines[-1] == "":
        lines.pop()
    return lines, removed


def derive_title(lines: list[str]) -> tuple[str | None, list[str]]:
    if not lines:
        return None, lines
    first_line = lines[0]
    word_count = len(first_line.split())
    if len(first_line) <= 120 and 2 <= word_count <= 18:
        remaining = lines[1:]
        while remaining and remaining[0] == "":
            remaining.pop(0)
        return first_line, remaining
    return None, lines


def truncate_text(text: str, max_words: int) -> tuple[str, bool]:
    if max_words <= 0:
        return text, False

    paragraphs = [paragraph for paragraph in text.split("\n\n") if paragraph.strip()]
    kept: list[str] = []
    words_so_far = 0

    for paragraph in paragraphs:
        words = paragraph.split()
        if not words:
            continue
        if words_so_far + len(words) <= max_words:
            kept.append(paragraph)
            words_so_far += len(words)
            continue

        remaining = max_words - words_so_far
        if remaining > 0:
            kept.append(" ".join(words[:remaining]))
            words_so_far += remaining
        return "\n\n".join(kept).strip(), True

    return text.strip(), False


def word_count(text: str) -> int:
    return len(re.findall(r"\b[\w'-]+\b", text))


def infer_source_label(source_url: str | None, fallback: str) -> str:
    if source_url:
        parsed = urlparse(source_url)
        if parsed.netloc:
            return parsed.netloc
    return fallback


def clean_payload(
    payload: InputPayload,
    *,
    title_override: str | None,
    source_url: str | None,
    source_label: str | None,
    front_tab_metadata: TabMetadata | None,
    max_words: int,
) -> CleanedPayload:
    lines, removed_lines = split_clean_lines(payload.body)
    derived_title, cleaned_lines = derive_title(lines)
    body_text = "\n\n".join(
        paragraph for paragraph in re.split(r"\n{2,}", "\n".join(cleaned_lines)) if paragraph.strip()
    ).strip()

    cleanup_notes: list[str] = []
    if removed_lines:
        cleanup_notes.append(f"Removed {removed_lines} boilerplate or duplicate lines.")
    if payload.input_kind == "html":
        cleanup_notes.append("Collapsed HTML into readable text blocks.")
    if payload.input_kind == "pdf":
        cleanup_notes.append("Extracted text locally from the PDF with pdftotext.")
    if front_tab_metadata:
        cleanup_notes.append(f"Attached title and URL metadata from {front_tab_metadata.browser}.")

    truncated_body, was_truncated = truncate_text(body_text, max_words)
    if was_truncated:
        cleanup_notes.append(f"Trimmed the clean body to {max_words} words for handoff output.")

    final_title = (
        normalize_inline_whitespace(title_override or "")
        or normalize_inline_whitespace(front_tab_metadata.title if front_tab_metadata else "")
        or normalize_inline_whitespace(payload.extracted_title or "")
        or normalize_inline_whitespace(derived_title or "")
        or "Untitled reading handoff"
    )

    final_source_url = (
        normalize_inline_whitespace(source_url or "")
        or normalize_inline_whitespace(front_tab_metadata.url if front_tab_metadata else "")
        or normalize_inline_whitespace(payload.extracted_url or "")
        or None
    )
    if final_source_url == "":
        final_source_url = None

    final_source_label = (
        normalize_inline_whitespace(source_label or "")
        or infer_source_label(final_source_url, payload.source_label)
    )

    final_word_count = word_count(truncated_body)
    final_minutes = max(1, math.ceil(final_word_count / 220)) if final_word_count else 1

    if not cleanup_notes:
        cleanup_notes.append("Normalized whitespace and preserved the readable body only.")

    return CleanedPayload(
        title=final_title,
        source_label=final_source_label,
        source_url=final_source_url,
        input_kind=payload.input_kind,
        word_count=final_word_count,
        reading_minutes=final_minutes,
        cleanup_notes=cleanup_notes,
        body=truncated_body,
    )


def format_source_line(payload: CleanedPayload) -> str:
    if payload.source_url:
        return f"{payload.source_label} ({payload.source_url})"
    return payload.source_label


def minute_label(minutes: int) -> str:
    suffix = "minute" if minutes == 1 else "minutes"
    return f"{minutes} {suffix}"


def render_payload(payload: CleanedPayload, output_format: str) -> str:
    if output_format == "json":
        return json.dumps(payload.__dict__, indent=2, ensure_ascii=False)

    cleanup_lines = "\n".join(f"- {note}" for note in payload.cleanup_notes)
    source_line = format_source_line(payload)

    if output_format == "plain":
        return (
            f"Title: {payload.title}\n"
            f"Source: {source_line}\n"
            f"Input: {payload.input_kind}\n"
            f"Words: {payload.word_count}\n"
            f"Reading time: {minute_label(payload.reading_minutes)}\n"
            f"Cleanup notes:\n{cleanup_lines}\n\n"
            f"Clean text:\n{payload.body}"
        )

    if output_format == "markdown":
        source_markdown = (
            f"[{payload.source_label}]({payload.source_url})"
            if payload.source_url
            else payload.source_label
        )
        return (
            f"# {payload.title}\n\n"
            f"- Source: {source_markdown}\n"
            f"- Input: `{payload.input_kind}`\n"
            f"- Reading time: `{minute_label(payload.reading_minutes)}`\n"
            f"- Words: `{payload.word_count}`\n\n"
            f"## Cleanup notes\n\n"
            f"{cleanup_lines}\n\n"
            f"## Clean text\n\n"
            f"{payload.body}"
        )

    if output_format == "prompt":
        return (
            "Reader handoff\n"
            f"Title: {payload.title}\n"
            f"Source: {source_line}\n"
            f"Input kind: {payload.input_kind}\n"
            f"Word count: {payload.word_count}\n"
            f"Estimated reading time: {minute_label(payload.reading_minutes)}\n"
            "Cleanup notes:\n"
            f"{cleanup_lines}\n\n"
            "Use the cleaned text below as source material. Keep the original meaning and do not invent missing sections.\n\n"
            "Clean text:\n"
            f"{payload.body}"
        )

    raise SystemExit(f"Unsupported format: {output_format}")


def copy_to_clipboard(text: str) -> None:
    if not shutil.which("pbcopy"):
        raise SystemExit("pbcopy is required to copy output on macOS.")
    subprocess.run(["pbcopy"], input=text, text=True, check=True)


def render_doctor() -> str:
    lines = [
        "Reader Mode Bridge doctor",
        f"- pbcopy: {'available' if shutil.which('pbcopy') else 'missing'}",
        f"- pbpaste: {'available' if shutil.which('pbpaste') else 'missing'}",
        f"- pdftotext: {'available' if shutil.which('pdftotext') else 'missing'}",
        f"- osascript: {'available' if shutil.which('osascript') else 'missing'}",
        "- Front tab browsers: " + ", ".join(sorted(SUPPORTED_BROWSERS)),
        "- Input modes: --file, --stdin, --text, --clipboard",
        "- Output formats: plain, markdown, prompt, json",
    ]
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["doctor", "clean", "copy"], nargs="?", default="clean")
    parser.add_argument("--file", help="Local input file: html, markdown, text, or pdf.")
    parser.add_argument("--stdin", action="store_true", help="Read the source body from stdin.")
    parser.add_argument("--text", help="Use the provided inline text or HTML snippet.")
    parser.add_argument("--clipboard", action="store_true", help="Read the source body from the macOS clipboard.")
    parser.add_argument("--title", help="Override the cleaned handoff title.")
    parser.add_argument("--source-url", help="Attach a canonical source URL.")
    parser.add_argument("--source-label", help="Override the source label shown in the output.")
    parser.add_argument(
        "--front-tab",
        action="store_true",
        help="Attach title and URL metadata from the current Safari or Chrome-family front tab.",
    )
    parser.add_argument(
        "--browser",
        help="Browser override for --front-tab. Accepts Safari, Chrome, Brave, Arc, or Edge aliases.",
    )
    parser.add_argument(
        "--format",
        default="markdown",
        choices=["plain", "markdown", "prompt", "json"],
        help="Output format for the cleaned handoff.",
    )
    parser.add_argument(
        "--max-words",
        type=int,
        default=900,
        help="Maximum body words to keep in the cleaned handoff. Use 0 to keep the full body.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.command == "doctor":
        print(render_doctor())
        return 0

    payload = load_input(args)
    tab_metadata = front_tab(args.browser) if args.front_tab else None
    cleaned = clean_payload(
        payload,
        title_override=args.title,
        source_url=args.source_url,
        source_label=args.source_label,
        front_tab_metadata=tab_metadata,
        max_words=args.max_words,
    )
    rendered = render_payload(cleaned, args.format)

    if args.command == "copy":
        copy_to_clipboard(rendered)

    print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
