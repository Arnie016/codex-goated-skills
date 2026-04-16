# Iconography Lab Product Spec

## Target User

Creative directors, brand strategists, content leads, and talent teams shaping a recognizable visual and verbal system around a public figure.

## Inputs

- photo sets, thumbnails, posters, livestream stills, or public press images
- captions, slogans, catchphrases, recurring titles, and community nicknames
- notes about props, wardrobe pieces, gestures, framing, or signature moods
- existing brand decks when the user wants continuity rather than reinvention

## Input To Output Flow

1. Collect the strongest references and separate stable signals from temporary styling.
2. Group the signals into visual and verbal systems.
3. Stress-test whether the system feels ownable and repeatable.
4. Export an identity kit with concrete do and do not guidance.

## Artifact Template

Artifact: `identity-kit`

Required sections:
- Palette and contrast direction
- Props, wardrobe anchors, and object cues
- Silhouette, pose, and framing signatures
- Verbal codes such as catchphrases, tone, and naming patterns
- Do and do not guidance for future content or merch

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional settings/history window.
- Primary actions:
  - `Collect References`
  - `Map Codes`
  - `Build Kit`
  - `Export Guide`
- Popover priority: source state first, artifact preview second, export third.
- Optional window: saved runs, source weighting, export format, and review notes.

## First Run UX

Ask for the public figure, the channels that matter most, and whether the goal is refinement of an existing look or discovery of the strongest existing codes.

## States

### Empty

Show a reference intake panel with example asset types and a note that the best results come from public visuals plus a small set of captions or quotes.

### Loading

Display reference count and a progress note that the system is mapping colors, props, silhouettes, and verbal codes.

### Error

Tell the user whether the failure came from missing visual references, unsupported file links, or a mismatch between the requested output and the provided material.

## Icon Brief

Use an eye-like badge or aperture glyph to signal recognition and visual code extraction. The icon should feel polished, editorial, and slightly analytical.

## Brand Color

`#3E6DFF`

## Layout Notes

- Use stacked cards for color, prop, silhouette, and phrase systems rather than one long prose block.
- Keep the popover visual first, but reserve one short explanation line per cue so it remains practical.
- Use compact swatches and chips instead of oversized brand-board visuals.
