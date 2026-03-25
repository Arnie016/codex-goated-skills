# Ritual Engine Product Spec

## Target User

Community designers, creator strategists, brand leads, and operators who want repeatable formats that deepen participation without overloading the audience.

## Inputs

- the creator or founder's current publishing cadence and recurring event windows
- existing community habits, slang, traditions, or participation spikes
- launch milestones, tour dates, product events, or recurring weekly beats
- moderation capacity and constraints around frequency, tone, and audience age

## Input To Output Flow

1. Map current cadence, audience habits, and moderation limits.
2. Draft ritual ideas that align with the existing audience culture.
3. Stress-test each ritual for sustainability and safety.
4. Export a ritual calendar with pilot guidance and stop conditions.

## Artifact Template

Artifact: `ritual-calendar`

Required sections:
- Core recurring rituals with names and intent
- Participation loops for comments, submissions, remixes, or live moments
- Cadence calendar by weekly, monthly, or event-driven rhythm
- Moderation and fatigue safeguards
- Pilot plan for testing rituals before scaling them

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional settings/history window.
- Primary actions:
  - `Set Cadence`
  - `Draft Rituals`
  - `View Calendar`
  - `Export Plan`
- Popover priority: source state first, artifact preview second, export third.
- Optional window: saved runs, source weighting, export format, and review notes.

## First Run UX

Ask for the current publishing rhythm, the community's preferred interaction style, and any hard limits on frequency, labor, or tone.

## States

### Empty

Show a cadence intake panel with examples like weekly prompts, live callbacks, submission rituals, and event-day traditions.

### Loading

Display the chosen cadence and a short progress note that the system is drafting repeatable rituals and participation loops.

### Error

Explain whether the request lacks enough cadence context, moderation capacity, or community detail to create a safe ritual plan.

## Icon Brief

Use a looping motion with a small spark to suggest repeatable energy without turning the icon into a busy cycle diagram. It should feel warm, deliberate, and grounded.

## Brand Color

`#C96A34`

## Layout Notes

- Make cadence the visual anchor so rituals feel scheduled, not chaotic.
- Show guardrails beside each ritual instead of burying them in a later section.
- Keep the popover focused on the next three ritual beats rather than the whole calendar at once.
