---
name: dark-pdf-studio
description: Convert PDFs and document files into dark-background reading PDFs with a very simple input-to-output workflow. Use when Codex needs to dark-theme a PDF, normalize a doc into PDF first, build or refine a tiny dark-mode export utility, or troubleshoot a dark PDF conversion flow with downloadable output.
---

# Dark PDF Studio

Use this skill when the user wants a simple dark-PDF workflow: one input file, one output file, dark background, downloadable result.

## Quick Start

1. Prefer PDF input for layout fidelity.
2. Run `python3 scripts/dark_pdf.py --input input.pdf --output output-dark.pdf`.
3. Use `--theme graphite`, `--theme midnight`, or `--theme navy` for the background tone.
4. For document inputs such as `.docx` or `.rtf`, let the script normalize them to PDF first if LibreOffice is available.
5. If the user wants a small app, keep the UI to:
   - choose file
   - dark theme toggle
   - export

## Workflow

### Input Rules

- Best input: PDF
- Also supported:
  - `.doc`
  - `.docx`
  - `.rtf`
  - `.odt`
  - `.txt`
  - `.md`
  - `.html`
  - common images
- Prefer converting non-PDF documents into PDF before dark processing so the export contract stays consistent.

### Output Rules

- Default output is a dark-background PDF.
- Keep the surface simple:
  - one input
  - one output
  - one theme choice
- Treat “downloadable” as a local exported file path that can be opened or shared immediately.

### Editing Guidance

- Use `scripts/dark_pdf.py` for the actual conversion path.
- Keep the conversion deterministic and easy to explain.
- If a document backend is missing, fail with a clear dependency message instead of pretending the conversion succeeded.
- Prefer readable high-contrast results over preserving every original page color exactly.

### Validation

- Run `python3 -m py_compile scripts/dark_pdf.py` after edits.
- Run `python3 scripts/dark_pdf.py --help` to confirm CLI shape.
- If the user provides a real file, smoke-test one conversion and confirm the output path exists.

## Resources

- `scripts/dark_pdf.py`: CLI converter for PDF, doc, and image inputs into dark-background PDF output.
- `references/workflow-map.md`: input contract, backend expectations, and output behavior.
