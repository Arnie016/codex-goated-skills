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
- For a quick local preview, run:
  `cd apps/on-this-day && python3 -m http.server 4173`
- Open `http://localhost:4173` after starting the server.
- Use the helper script when you need a deterministic feed snapshot or markdown digest:
  `python3 scripts/fetch_on_this_day.py --date YYYY-MM-DD --type selected --limit 5`

## Constraints

- Keep the app desktop-first and Mac-like.
- Preserve explicit live-versus-cached behavior.
- Do not invent historical facts or source links.
- Keep the web app separate from the native `on-this-day-bar` workspace.
