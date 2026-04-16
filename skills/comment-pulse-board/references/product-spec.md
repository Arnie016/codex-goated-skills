# Comment Pulse Board Product Spec

## Target User

Community managers, social strategists, operators, and talent teams who need a quick read on what a personality-led audience is saying right now.

## Inputs

- comment dumps, replies, quote posts, and community forum snapshots
- support inbox excerpts, FAQ logs, or AMA question lists
- moderation notes about flare-ups, repeat confusion, or repeated praise
- user-provided context about recent launches, controversies, or content pivots

## Input To Output Flow

1. Load the chatter set and note the current versus comparison window.
2. Group repeated topics, questions, praise, confusion, and criticism into stable clusters.
3. Assess which clusters are shifting in intensity or tone.
4. Export a pulse digest with explicit action, watch, and no-action labels.

## Artifact Template

Artifact: `pulse-digest`

Required sections:
- Top obsession clusters and why they matter
- Recurring questions or unresolved confusion
- Sentiment shifts compared with the prior source window
- Backlash or fatigue signals that need human review
- Suggested response priorities for the next content cycle

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional settings/history window.
- Primary actions:
  - `Import Chatter`
  - `Cluster Pulse`
  - `Review Shifts`
  - `Export Digest`
- Popover priority: source state first, artifact preview second, export third.
- Optional window: saved runs, source weighting, export format, and review notes.

## First Run UX

Ask for the main platforms, date window, and whether the user wants a strict comparison against a prior period. Make clear that the tool summarizes patterns, not individual targeting.

## States

### Empty

Show a simple intake panel with sample sources and a note that the strongest results come from one recent window plus one comparison window.

### Loading

Display comment counts, active platforms, and a short progress note about clustering obsession points and sentiment shifts.

### Error

Explain whether the issue came from malformed exports, missing text, or a source type the skill cannot cluster yet.

## Icon Brief

Use a speech bubble with a pulse line to signal live audience movement. The visual should feel like a compact dashboard chip, not a medical interface.

## Brand Color

`#D85A62`

## Layout Notes

- Use a split card layout with rising clusters on top and risk signals below.
- Make comparison deltas compact and readable instead of chart-heavy.
- Reserve warning color for real escalation items so the popover stays calm.
