# On This Day

On This Day is a polished macOS-style web app for opening a daily historical briefing, browsing notable events for any date, and jumping straight into the relevant Wikipedia pages.

It uses the official Wikimedia Feed API endpoint for "On this day":

- `https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/all/{MM}/{DD}`

## What It Includes

- desktop-first macOS presentation with window chrome, glass panels, and animated timeline cards
- fast day navigation with `Today`, previous, next, and random-day controls
- curated `Selected`, `Events`, `Births`, `Deaths`, and `Holidays` views
- local caching so the app can fall back to the last successful snapshot for a date if the live request fails
- digest copy action for quick sharing or note capture

## Local Run

```bash
cd apps/on-this-day
bash ../../skills/on-this-day/scripts/run_on_this_day.sh run
```

Use `bash ../../skills/on-this-day/scripts/run_on_this_day.sh fetch --date YYYY-MM-DD --type selected --limit 5`
when you want a deterministic Wikimedia snapshot, or `serve` if you want the preview server to stay attached to the terminal. If the runner cannot bind the local preview port, it falls back to opening `index.html` directly.
