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
python3 -m http.server 4173
open http://localhost:4173
```

You can also open `index.html` directly, but a tiny local server is the most reliable path for browser fetch behavior.
