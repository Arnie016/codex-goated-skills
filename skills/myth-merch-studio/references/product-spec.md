# Myth Merch Studio Product Spec

## Target User

Merch leads, creative directors, talent teams, and founder-brand operators translating audience lore into tangible products or drop concepts.

## Inputs

- canon maps, iconography kits, and known audience symbols or phrases
- product constraints such as format, materials, price bands, and minimum order concerns
- drop timing, event hooks, or seasonality notes
- licensing, trademark, or collaborator boundaries that must stay respected

## Input To Output Flow

1. Load the relevant canon and practical product constraints.
2. Map lore elements to product formats that feel earned and manufacturable.
3. Filter out risky, generic, or rights-problematic ideas.
4. Export a merch brief with concept rationale and risk review.

## Artifact Template

Artifact: `merch-brief`

Required sections:
- Merch concepts with audience rationale
- Phrase, symbol, or object mapping for each concept
- Material, format, and packaging notes
- Drop framing, scarcity logic, and no-go ideas
- Rights and risk review before production

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional settings/history window.
- Primary actions:
  - `Load Lore`
  - `Draft Concepts`
  - `Review Drop`
  - `Export Brief`
- Popover priority: source state first, artifact preview second, export third.
- Optional window: saved runs, source weighting, export format, and review notes.

## First Run UX

Ask for the source lore first, then the target product category, price band, and any known licensing or collaborator constraints.

## States

### Empty

Show a merch concept intake with examples like wearable, collectible, packaging-first, and event-only drops.

### Loading

Display the loaded lore inputs and a note that the system is matching symbols and phrases to concept routes and drop logic.

### Error

Explain whether the request lacks source lore, product constraints, or enters rights territory that needs human legal review first.

## Icon Brief

Use a tag-like glyph with a small star to suggest lore becoming product. The icon should feel like premium packaging, not generic shopping.

## Brand Color

`#2E9A5F`

## Layout Notes

- Use compact concept cards with one rationale line so teams can compare options quickly.
- Keep rights and manufacturing notes visible beside each concept rather than at the very end.
- Use green as a stabilizing accent, not a loud retail cue.
