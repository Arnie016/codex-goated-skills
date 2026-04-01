# Trading Archive Product Spec

## Target User

- discretionary traders, macro readers, and market researchers who collect article links faster than they revisit them
- users who want a compact Mac ritual for resurfacing trading reads instead of keeping finance tabs open all day

## Input To Output Flow

1. user pastes one or more RSS or Atom feed URLs
2. the app or helper fetches and parses feed items
3. articles are deduplicated, timestamped, and cached locally
4. the user searches, filters, favorites, or copies a reading queue
5. the system outputs a queue, digest, or source-health summary

## Artifact Templates

### Reading Queue

- title
- source
- published date
- one-line reason to reopen
- article URL

### Source Health Report

- source title
- feed URL
- live or failed status
- article count
- failure or freshness note

## First-Run UX

- empty state explains that the app works with public RSS or Atom feeds only
- settings window opens quickly from the popover
- sample guidance shows one URL per line input
- refresh remains available even before an archive exists

## States

### Empty

- no feeds configured
- explain the expected input and keep the UI calm

### Loading

- show that feeds are being refreshed
- preserve the previous archive when available

### Cached

- show the saved archive with an explicit cached label

### Error

- explain that all feeds failed or no archive could be built
- keep settings and retry actions visible

## Mac UI Notes

- menu bar title should be compact and legible, for example `TA 12`
- popover should stay around 430-450 pt wide and remain scrollable
- use a dark professional finance palette without default purple gradients
- source chips should feel status-aware and clickable
- article rows should prioritize title, source, timestamp, and a clean open action
