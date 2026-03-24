# Dark PDF Studio Workflow Map

## Goal

Take one input file and produce one downloadable dark-background PDF.

## Input Contract

- Primary supported input: PDF
- Additional input types:
  - document files: `.doc`, `.docx`, `.rtf`, `.odt`, `.txt`, `.md`, `.html`, `.htm`
  - common raster images including `.png`, `.jpg`, `.webp`, `.gif`, `.heic`

## Conversion Path

1. Detect the input type.
2. If the input is already a PDF, process it directly.
3. If the input is a document, extract readable text first and normalize it into an intermediate PDF.
4. Rasterize each page.
5. Remap luminance to a dark theme.
6. Reassemble the pages into a final dark PDF.

## Backend Expectations

- PDF rendering path expects Python with:
  - `PyMuPDF`
  - `Pillow`
- Document normalization prefers:
  - macOS `textutil`
  - `soffice` / LibreOffice as fallback
- If required backends are missing, fail clearly and say which dependency is needed.

## Output Contract

- Output file is always a PDF.
- The output should:
  - use a dark background
  - keep readable light foreground content
  - preserve page order
  - write to an explicit local output path

## UI Contract

If a small app is built around this flow, keep it minimal and compact:

- file picker or drop zone
- theme picker
- export button
- open/reveal output only after export exists
