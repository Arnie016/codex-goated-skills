# Clip to Canon Finder Product Spec

## Target User

Short-form editors, social teams, creator managers, and founder-brand operators who need to know which moments deserve repeat exposure.

## Inputs

- video links, rough timestamps, or short-form exports from Reels, Shorts, or TikTok
- transcripts, subtitle files, or manual clip notes
- comment samples that show which line or reaction fans keep repeating
- editor notes about current formats, cut length, and reuse constraints

## Input To Output Flow

1. Load clip references, transcripts, and comment signal into one queue.
2. Score moments for replay value, quotability, and canon fit.
3. Filter out context-fragile or risky clips.
4. Export a shortlist with reuse ideas and cut guidance.

## Artifact Template

Artifact: `clip-shortlist`

Required sections:
- Shortlisted moments with timestamps or identifiable cut points
- Why each moment sticks: line, look, reaction, or dynamic
- Fandom reuse angle for edits, memes, callbacks, or compilation posts
- Cut guidance for short-form packaging and thumbnail framing
- Moments to skip because the signal is weak, mean-spirited, or misleading

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional settings/history window.
- Primary actions:
  - `Add Clips`
  - `Score Moments`
  - `Review Shortlist`
  - `Export Angles`
- Popover priority: source state first, artifact preview second, export third.
- Optional window: saved runs, source weighting, export format, and review notes.

## First Run UX

Ask for clip links or transcript snippets first, then ask whether the user wants meme potential, lore value, or broad reach weighted more heavily.

## States

### Empty

Show a drag-and-drop or paste state for clip URLs, timestamps, and transcripts, plus one sentence explaining what makes a moment score well.

### Loading

Display clip count, transcript coverage, and a progress note that the system is scoring moments for replay value and fandom reuse.

### Error

Tell the user whether the issue came from inaccessible clip links, missing timestamps, or transcripts that do not align with the supplied videos.

## Icon Brief

Use a play button inside a locator ring to suggest finding the exact moment that can graduate into canon. The icon should feel sharp and editorial, not entertainment-gimmicky.

## Brand Color

`#1A9B8C`

## Layout Notes

- Use one strong preview row per shortlisted clip with timestamp, signal score, and one reuse note.
- Keep the scoring explanation readable in plain language rather than abstract numbers alone.
- Always show the 'skip' rationale when a clip is risky or weak so editorial teams can trust the tool.
