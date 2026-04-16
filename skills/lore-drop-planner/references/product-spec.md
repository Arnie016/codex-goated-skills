# Lore Drop Planner Product Spec

## Target User

Content strategists, launch leads, creative directors, and teams running episodic storytelling around a public figure or founder.

## Inputs

- canon maps, campaign notes, or world-building references
- existing content calendar, launch windows, and major dates
- notes on unresolved mysteries, recurring props, or teased payoffs
- constraints around what must stay private, fictional, or undisclosed

## Input To Output Flow

1. Load the canon context and current schedule constraints.
2. Turn open loops into clear arcs with reveal and payoff logic.
3. Stress-test the arc for clarity and fatigue.
4. Export a schedule with review points and reset rules.

## Artifact Template

Artifact: `lore-release-schedule`

Required sections:
- Arc summary and audience promise
- Drop sequence with reveal, teaser, callback, and payoff beats
- Cross-format notes for posts, lives, clips, merch, or events
- Confusion risks and guardrails for clarity
- Review points for when to accelerate, pause, or retire the arc

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional settings/history window.
- Primary actions:
  - `Load Canon`
  - `Sequence Drops`
  - `Review Timeline`
  - `Export Schedule`
- Popover priority: source state first, artifact preview second, export third.
- Optional window: saved runs, source weighting, export format, and review notes.

## First Run UX

Ask for the active canon threads, the campaign or launch window, and whether the user needs a short burst schedule or a longer slow-burn arc.

## States

### Empty

Show a timeline intake state with starter slots for canon threads, callbacks, open loops, and key dates.

### Loading

Display the number of active lore threads and a note that the system is sequencing reveals, callbacks, and payoff beats.

### Error

Tell the user whether the failure came from missing canon context, overloaded timelines, or a request that depends on misleading the audience.

## Icon Brief

Use a calendar card with a small spark or star to imply timed reveals and payoff moments. It should feel precise and editorial, not fantasy-game themed.

## Brand Color

`#5A63D8`

## Layout Notes

- Make the next beat the focal point, with future beats collapsed underneath.
- Use short labels like reveal, callback, and payoff instead of dense timeline prose.
- Keep reset rules visible so the plan does not lock the team into a stale arc.
