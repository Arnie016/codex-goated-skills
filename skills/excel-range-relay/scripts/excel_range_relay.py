#!/usr/bin/env python3
"""Format copied Excel selections on macOS for prompt and document handoffs."""

from __future__ import annotations

import argparse
import csv
import io
import json
import subprocess
import sys
from dataclasses import dataclass

HEADER_MODE_CHOICES = ("first-row", "generated")


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


def generated_headers(column_count: int) -> list[str]:
    return [f"Column {index + 1}" for index in range(column_count)]


@dataclass
class SelectionPayload:
    rows: list[list[str]]
    header_mode: str = "first-row"
    workbook: str = ""
    sheet: str = ""
    range_address: str = ""

    @property
    def row_count(self) -> int:
        return len(self.rows)

    @property
    def column_count(self) -> int:
        return len(self.rows[0]) if self.rows else 0

    @property
    def header(self) -> list[str]:
        if not self.rows:
            return []
        if self.header_mode == "first-row":
            return self.rows[0]
        return generated_headers(self.column_count)

    @property
    def data_rows(self) -> list[list[str]]:
        if not self.rows:
            return []
        if self.header_mode == "first-row":
            return self.rows[1:]
        return self.rows

    @property
    def data_row_count(self) -> int:
        return len(self.data_rows)

    def records(self) -> list[dict[str, str]]:
        return [dict(zip(self.header, row)) for row in self.data_rows]

    def as_dict(self) -> dict[str, object]:
        return {
            "workbook": self.workbook,
            "sheet": self.sheet,
            "range": self.range_address,
            "header_mode": self.header_mode,
            "header": self.header,
            "row_count": self.row_count,
            "data_row_count": self.data_row_count,
            "column_count": self.column_count,
            "rows": self.rows,
            "data_rows": self.data_rows,
            "records": self.records(),
        }


def format_summary(payload: SelectionPayload) -> str:
    header_mode_label = (
        "First row from the copied selection"
        if payload.header_mode == "first-row"
        else "Generated column names"
    )
    lines = ["Excel selection summary"]
    if payload.workbook:
        lines.append(f"Workbook: {payload.workbook}")
    if payload.sheet:
        lines.append(f"Sheet: {payload.sheet}")
    if payload.range_address:
        lines.append(f"Range: {payload.range_address}")
    lines.extend(
        [
            f"Header mode: {header_mode_label}",
            f"Copied rows: {payload.row_count}",
            f"Data rows: {payload.data_row_count}",
            f"Columns: {payload.column_count}",
        ]
    )
    return "\n".join(lines)


def payload_to_markdown_table(payload: SelectionPayload) -> str:
    return rows_to_markdown([payload.header, *payload.data_rows])


def format_prompt(payload: SelectionPayload) -> str:
    metadata_lines = []
    if payload.workbook:
        metadata_lines.append(f"Workbook: {payload.workbook}")
    if payload.sheet:
        metadata_lines.append(f"Sheet: {payload.sheet}")
    if payload.range_address:
        metadata_lines.append(f"Range: {payload.range_address}")
    metadata_lines.append(
        "Header mode: "
        + (
            "First row from the copied selection"
            if payload.header_mode == "first-row"
            else "Generated column names"
        )
    )
    metadata_lines.append(f"Copied rows: {payload.row_count}")
    metadata_lines.append(f"Data rows: {payload.data_row_count}")
    metadata_lines.append(f"Columns: {payload.column_count}")

    return "\n".join(
        [
            "Excel selection",
            *metadata_lines,
            "",
            "Table",
            payload_to_markdown_table(payload),
        ]
    ).strip()


def format_payload(payload: SelectionPayload, style: str) -> str:
    if style == "json":
        return json.dumps(payload.as_dict(), indent=2, ensure_ascii=False)
    if style == "markdown":
        return payload_to_markdown_table(payload)
    if style == "csv":
        return rows_to_csv([payload.header, *payload.data_rows])
    if style == "tsv":
        return rows_to_tsv([payload.header, *payload.data_rows])
    if style == "plain":
        return rows_to_tsv(payload.rows)
    if style == "prompt":
        return format_prompt(payload)
    if style == "summary":
        return format_summary(payload)
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
        choices=["json", "markdown", "csv", "tsv", "prompt", "plain", "summary"],
        help="Output format for the current selection.",
    )
    parser.add_argument(
        "--header-mode",
        default="first-row",
        choices=list(HEADER_MODE_CHOICES),
        help="Treat the first row as headers, or generate neutral column names for data-only selections.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    rows = parse_rows(read_input(args))
    metadata = excel_metadata()
    payload = SelectionPayload(
        rows=rows,
        header_mode=args.header_mode,
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
