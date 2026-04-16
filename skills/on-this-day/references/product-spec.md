# On This Day Product Spec

## Product Promise

Open one polished surface each day and immediately see a handful of genuinely interesting historical events, births, deaths, and observances tied to that same calendar date.

The experience should feel like a premium macOS desk accessory, not a classroom worksheet or generic news tile wall.

## Target User

- someone who wants a quick daily intellectual spark
- a founder, creator, or operator who likes ritualized daily context
- a user who prefers one reliable "same day in history" destination over manual browsing

## Official Data Source

- primary source: Wikimedia Feed API "On this day"
- endpoint shape: `GET https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/all/{MM}/{DD}`
- the app should rely on the feed categories already provided by Wikimedia:
  - `selected`
  - `events`
  - `births`
  - `deaths`
  - `holidays`

## Primary Inputs

- current date in the user's timezone, defaulting to `Asia/Singapore` for local runs in this workspace
- optional user-picked date
- view type
- story count limit

## Primary Outputs

- a top-level hero summary for the day
- a spotlight card for the strongest current item
- a scrollable list of source-linked historical entries
- a copyable digest the user can drop into notes, messages, or a prompt

## First-Run UX

1. Load today's date in Singapore local time.
2. Show a premium loading state immediately.
3. Fetch the official `all` feed.
4. Default the first view to `selected`.
5. Show the spotlight card and 5-6 timeline cards above the fold.

## Empty, Loading, and Error States

- loading:
  - hero line explains that the official archive is being pulled in
  - category counts remain present but neutral
- cached fallback:
  - if a live request fails and a cached snapshot exists, keep rendering the date with a visible `Cached snapshot` chip
- full error:
  - if both live and cached fetches fail, show a clean explanatory empty state
  - do not fabricate entries
- empty category:
  - if a category is empty, keep the rest of the day profile visible and encourage category switching

## Layout Notes

- desktop-first
- use faux macOS window chrome and rounded glass panels
- layout:
  - hero at top
  - left control rail
  - right timeline surface
- avoid overflowing two-column cards on smaller laptop widths; collapse to one column under tighter screens

## Controls

- `Today`
- `Random Day`
- `Previous`
- `Next`
- date picker
- segmented control for feed category
- range slider for number of entries shown
- `Copy Brief`
- `Refresh`
- `Shuffle` spotlight

## Motion

- subtle ambient drift in the background
- card rise-in on new feed loads
- no broad full-panel spring animations that make controls feel slippery

## Fallback Mechanics

- cache each fetched day payload in local storage keyed by `YYYY-MM-DD`
- persist the last selected date, category, and story limit
- if a live request fails, try the cached payload for the same date before surfacing an error

## Icon Brief

- metaphor: a calendar page with a starburst and a subtle timeline mark
- feel: polished macOS utility icon, warm amber accent, cool dark core

## Brand Color

- `#D88B2C`
