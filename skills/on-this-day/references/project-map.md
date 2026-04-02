# On This Day Web Project Map

Default workspace: use `apps/on-this-day` when working inside this repository.

## Target

- `On This Day`: desktop-first macOS-style web app for source-linked daily history briefs

## Main Files

- `README.md`: local run guidance and product overview
- `app.js`: feed loading, date navigation, caching, digest assembly, and rendering
- `index.html`: app shell, controls, and article cards
- `styles.css`: macOS-style layout, glass panels, motion, and responsive presentation
- `../scripts/fetch_on_this_day.py`: deterministic official Wikimedia feed helper

## Run And Preview Notes

- Use the web app README first:
  `apps/on-this-day/README.md`
- Use the runner script first:
  `bash scripts/run_on_this_day.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_on_this_day.sh --workspace /path/to/apps/on-this-day <command>`
- `fetch` runs the deterministic feed helper and can emit markdown or JSON snapshots.
- `run` starts a local preview server on `http://localhost:4173`, opens the browser, and reuses an existing background server when one is already running. If the port is unavailable, it falls back to opening `index.html` directly.
- `serve` runs the same preview server in the foreground when you want to keep the terminal attached.

## Constraints

- Keep the app desktop-first and Mac-like.
- Preserve explicit live-versus-cached behavior.
- Do not invent historical facts or source links.
- Keep the web app separate from the native `on-this-day-bar` workspace.
