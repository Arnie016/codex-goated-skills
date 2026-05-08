# Parasocial Studio Product Spec

## Target User

Talent teams, creator strategists, community leads, and founder-brand operators balancing warmth with clear ethical boundaries.

## Inputs

- the public figure's current audience touchpoints such as comments, lives, newsletters, or community posts
- tone goals around warmth, distance, gratitude, and authority
- audience maturity, moderation needs, and any existing boundary issues
- notes about what acknowledgements or access formats are operationally realistic

## Input To Output Flow

1. Capture the current relationship surface and tone goals.
2. Identify which touchpoints feel sustainable, honest, and healthy.
3. Draft a cadence with explicit boundaries and stop conditions.
4. Export the plan with operational notes and red-flag guidance.

## Artifact Template

Artifact: `relationship-cadence-plan`

Required sections:
- Closeness moments that feel genuine and repeatable
- Touchpoint cadence by format and frequency
- Boundary language and refusal patterns
- Acknowledgement systems that scale without false promises
- Red flags and stop conditions for unhealthy dynamics

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional settings/history window.
- Primary actions:
  - `Set Tone`
  - `Plan Touchpoints`
  - `Review Boundaries`
  - `Export Cadence`
- Popover priority: source state first, artifact preview second, export third.
- Optional window: saved runs, source weighting, export format, and review notes.

## First Run UX

Ask for the audience maturity level, the public figure's natural voice, and any existing pressure points such as over-attachment, boundary crossing, or unrealistic response expectations.

## States

### Empty

Show a tone and boundaries intake view with examples like acknowledgement formats, voice-style updates, and healthy refusal language.

### Loading

Display the chosen tone settings and a note that the system is balancing warmth, scale, and boundary safety.

### Error

Explain whether the request is underspecified or crosses into manipulative or unsafe relationship tactics that the skill will not support.

## Icon Brief

Use two linked circles or orbiting nodes to suggest connection with boundaries. The icon should feel warm but restrained, never romanticized or overly cute.

## Brand Color

`#D66B87`

## Layout Notes

- Make boundary language a first-class part of the UI instead of an appendix.
- Use calm pink and neutral tones sparingly so the product reads as professional, not sentimental.
- Keep each touchpoint row short: purpose, cadence, scale limit, and boundary note.
