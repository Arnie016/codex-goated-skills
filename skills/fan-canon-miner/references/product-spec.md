# Fan Canon Miner Product Spec

## Target User

Creator strategists, talent managers, social editors, community leads, and founder-brand operators who need a grounded map of what the audience already mythologizes.

## Inputs

- comment exports or copied threads from TikTok, Instagram, YouTube, X, Reddit, Discord, or newsletters
- interview transcripts, Q and A logs, podcast notes, or livestream recaps
- captions, community posts, fan edit descriptions, and meme references
- user-provided notes about breakout moments, props, nicknames, or recurring story beats

## Input To Output Flow

1. Collect the source set, note platform context, and mark the time window.
2. Cluster repeated symbols, phrases, people, props, and moments into canon candidates.
3. Score the candidates by recurrence, emotional pull, and reuse potential.
4. Export a canon map with clear opportunities and explicit low-confidence calls.

## Artifact Template

Artifact: `canon-map`

Required sections:
- Repeated symbols and aesthetic anchors
- Signature lines, nicknames, and fan language
- Canon moments with why they stuck
- Myths, lore threads, and callbacks the audience keeps reviving
- Three practical content opportunities that respect existing canon

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional settings/history window.
- Primary actions:
  - `Add Sources`
  - `Mine Canon`
  - `View Map`
  - `Export Brief`
  - `History`
- Popover priority: source state first, artifact preview second, export third.
- Optional window: saved runs, source weighting, export format, and review notes.

## First Run UX

Ask for the subject name, the relevant time window, and either source links or pasted source material. The first screen should explain that the skill only works from public or user-authorized material.

## States

### Empty

Show a source intake card with examples of useful material such as comments, captions, and interviews, plus one call to action: Add Sources.

### Loading

Display source count, platform breakdown, and a short message that the system is identifying repeated symbols, phrases, and canon moments.

### Error

Explain whether the failure came from missing source context, unusable formatting, or an unsupported link, then preserve the uploaded material for retry.

## Icon Brief

Use a speech-bubble-plus-star glyph to suggest mined fan language turning into durable canon. The large icon should feel like a polished amber notebook chip, while the small icon stays clean and legible in a menu bar surface.

## Brand Color

`#C67A2B`

## Layout Notes

- Lead the popover with a source status pill and the strongest canon cluster preview.
- Use compact grouped rows for symbols, phrases, and myths so the artifact feels scannable.
- Keep export formats lightweight: Markdown, plain text, or a concise brief card.
