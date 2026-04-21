# Impeccable CLI Quick Reference

Use this file when the user needs the exact command shape, operating notes, or a reminder of what the deterministic scan can and cannot cover.

## Core commands

```bash
npm i -g impeccable
npx impeccable detect src/
npx impeccable detect --json src/
npx impeccable detect --fast src/
npx impeccable detect https://example.com
npx impeccable live
npx impeccable live --port=5199
```

## AI harness install

```bash
npx impeccable skills help
npx impeccable skills install
npx impeccable skills update
npx impeccable skills check
```

Use this lane when the user wants Impeccable's own command skills installed into an AI harness rather than only the CLI binary.

## What the detector is good at

- deterministic anti-pattern scans across HTML, CSS, JSX, TSX, Vue, and Svelte
- local folder audits before code review or before shipping
- machine-readable JSON output for CI or other tooling
- quick first-pass scans with `--fast`
- live overlay debugging through `live`

## Important operating notes

- `detect` is the main command surface for the deterministic CLI workflow.
- `--json` is the right default when the findings need to feed another tool.
- `--fast` is a regex-only shortcut. It is useful for speed, but it is not the final word.
- A live URL target may need browser automation support through Puppeteer-backed execution.
- Exit code `0` means no findings. Exit code `2` means findings were detected.
- `live` starts a local server for the overlay workflow. The current docs describe a local URL flow such as `http://localhost:5199/?url=<target>`.
- The overlay is for in-place inspection; it is not a substitute for mapping the final fix back to source files.

## Where to look next

- If the user wants the full rule catalog, check `https://impeccable.style/anti-patterns/`.
- If the user wants exact package metadata, run `npm view impeccable version description bin repository homepage --json`.
