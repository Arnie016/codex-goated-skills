# Reader Mode Bridge Cleanup Contract

## Inputs

- `--file <path>` for local `.html`, `.htm`, `.xhtml`, `.md`, `.markdown`, `.txt`, or `.pdf` files
- `--stdin` for piped text
- `--text "<content>"` for inline snippets
- `--clipboard` for macOS clipboard text
- optional `--front-tab` plus `--browser` to attach the current Safari or Chrome-family front-tab title and URL

## Outputs

- `--format plain`
- `--format markdown`
- `--format prompt`
- `--format json`
- `copy` sends the rendered output to `pbcopy` and still prints it to stdout

## Cleanup rules

1. Normalize whitespace and paragraph spacing.
2. Drop common short boilerplate lines such as share prompts, cookie lines, subscribe prompts, and duplicated lines.
3. Derive a title from the explicit flag, the front tab, embedded HTML metadata, or the first heading-like line.
4. Preserve one source label and optional source URL.
5. Trim the cleaned body to `--max-words` when requested and report truncation in `cleanup_notes`.

## Local dependencies

- `pbcopy` and `pbpaste` for clipboard flows on macOS
- `osascript` for `--front-tab`
- `pdftotext` for PDF extraction

## Non-goals

- No network fetching or remote reader APIs
- No summarization or LLM rewriting inside the helper
- No browser automation beyond reading the current front tab metadata
