#!/usr/bin/env python3
"""Format the copied Excel selection on macOS for prompt and document handoffs."""

from __future__ import annotations

import argparse
import csv
import io
import json
import subprocess
import sys
from dataclasses import dataclass


def run_command(args: list[str], *, text_input: str | None = None) -> str:
    try:
        result = subprocess.run(
            args,
            input=text_input,
            text=True,
            capture_output=True,
            check=True,
        )
    except FileNotFoundError as error:
        raise SystemExit(f"Required command is missing: {args[0]}") from error
    except subprocess.CalledProcessError as error:
        message = (error.stderr or error.stdout or "").strip() or f"{args[0]} failed."
        raise SystemExit(message)
    return result.stdout


def run_osascript(script: str) -> str | None:
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            text=True,
            capture_output=True,
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None
    return result.stdout.strip()


def frontmost_app() -> str:
    script = """
    tell application "System Events"
        set frontApp to name of first application process whose frontmost is true
    end tell
    return frontApp
    """
    return run_osascript(script) or ""


def excel_metadata() -> dict[str, str]:
    if frontmost_app() != "Microsoft Excel":
        return {}

    script = """
    tell application "Microsoft Excel"
        if not (exists active workbook) then error "Microsoft Excel has no active workbook."
        set workbookName to name of active workbook
        set sheetName to name of active sheet
        set rangeAddress to address of selection
        return workbookName & linefeed & sheetName & linefeed & rangeAddress
    end tell
    """
    output = run_osascript(script)
    if not output:
        return {}

    parts = output.splitlines()
    if len(parts) < 3:
        return {}

    return {
        "workbook": parts[0].strip(),
        "sheet": parts[1].strip(),
        "range": parts[2].strip(),
    }


def read_clipboard() -> str:
    text = run_command(["pbpaste"])
    if not text.strip():
        raise SystemExit("Clipboard is empty. Copy a range from Excel first.")
    return text


def read_input(args: argparse.Namespace) -> str:
    if args.input_file:
        text = args.input_file.read()
        if not text.strip():
            raise SystemExit(f"Input file is empty: {args.input_file.name}")
        return text

    if args.stdin:
        text = sys.stdin.read()
        if not text.strip():
            raise SystemExit("Standard input is empty.")
        return text

    return read_clipboard()


def parse_rows(text: str) -> list[list[str]]:
    normalized = text.replace("\r\n", "\n").replace("\r", "\n")
    reader = csv.reader(io.StringIO(normalized), delimiter="\t")
    rows = [[cell.strip() for cell in row] for row in reader]

    while rows and not any(rows[-1]):
        rows.pop()

    if not rows:
        raise SystemExit("Clipboard does not contain a usable table.")

    column_count = max(len(row) for row in rows)
    return [row + [""] * (column_count - len(row)) for row in rows]


def escape_markdown_cell(value: str) -> str:
    return value.replace("\\", "\\\\").replace("|", "\\|").replace("\n", "<br>")


def rows_to_markdown(rows: list[list[str]]) -> str:
    header = rows[0]
    separator = ["---"] * len(header)
    body = rows[1:]

    lines = [
        "| " + " | ".join(escape_markdown_cell(value) for value in header) + " |",
        "| " + " | ".join(separator) + " |",
    ]
    for row in body:
        lines.append("| " + " | ".join(escape_markdown_cell(value) for value in row) + " |")
    return "\n".join(lines)


def rows_to_csv(rows: list[list[str]]) -> str:
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerows(rows)
    return output.getvalue().strip()


def rows_to_tsv(rows: list[list[str]]) -> str:
    return "\n".join("\t".join(row) for row in rows)


@dataclass
class SelectionPayload:
    rows: list[list[str]]
    workbook: str = ""
    sheet: str = ""
    range_address: str = ""

    @property
    def row_count(self) -> int:
        return len(self.rows)

    @property
    def column_count(self) -> int:
        return len(self.rows[0]) if self.rows else 0

    def as_dict(self) -> dict[str, object]:
        return {
            "workbook": self.workbook,
            "sheet": self.sheet,
            "range": self.range_address,
            "row_count": self.row_count,
            "column_count": self.column_count,
            "rows": self.rows,
        }


def format_prompt(payload: SelectionPayload) -> str:
    metadata_lines = []
    if payload.workbook:
        metadata_lines.append(f"Workbook: {payload.workbook}")
    if payload.sheet:
        metadata_lines.append(f"Sheet: {payload.sheet}")
    if payload.range_address:
        metadata_lines.append(f"Range: {payload.range_address}")
    metadata_lines.append(f"Rows: {payload.row_count}")
    metadata_lines.append(f"Columns: {payload.column_count}")

    return "\n".join(
        [
            "Excel selection",
            *metadata_lines,
            "",
            "Table",
            rows_to_markdown(payload.rows),
        ]
    ).strip()


def format_payload(payload: SelectionPayload, style: str) -> str:
    if style == "json":
        return json.dumps(payload.as_dict(), indent=2, ensure_ascii=False)
    if style == "markdown":
        return rows_to_markdown(payload.rows)
    if style == "csv":
        return rows_to_csv(payload.rows)
    if style == "tsv":
        return rows_to_tsv(payload.rows)
    if style == "plain":
        return rows_to_tsv(payload.rows)
    if style == "prompt":
        return format_prompt(payload)
    raise SystemExit(f"Unsupported format: {style}")


def copy_text(text: str) -> None:
    run_command(["pbcopy"], text_input=text)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["current", "copy"], nargs="?", default="current")
    parser.add_argument(
        "--stdin",
        action="store_true",
        help="Read the selection from standard input instead of the clipboard.",
    )
    parser.add_argument(
        "--input-file",
        type=argparse.FileType("r", encoding="utf-8"),
        help="Read the selection from a TSV-like text file instead of the clipboard.",
    )
    parser.add_argument(
        "--format",
        default="json",
        choices=["json", "markdown", "csv", "tsv", "prompt", "plain"],
        help="Output format for the current selection.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    rows = parse_rows(read_input(args))
    metadata = excel_metadata()
    payload = SelectionPayload(
        rows=rows,
        workbook=metadata.get("workbook", ""),
        sheet=metadata.get("sheet", ""),
        range_address=metadata.get("range", ""),
    )
    text = format_payload(payload, args.format)
    if args.command == "copy":
        copy_text(text)
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
