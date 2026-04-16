# Inner Circle Director Product Spec

## Target User

Community operators, membership leads, fan-club managers, and founder-brand teams building access structures that need to feel fair and sustainable.

## Inputs

- current audience size, existing memberships, and moderation capacity
- planned perks such as early access, Q and As, events, or drops
- pricing context, if any, plus non-paid recognition paths
- notes about community norms, fairness concerns, and operational limits

## Input To Output Flow

1. Capture the current audience structure, perks, and constraints.
2. Draft tiers and access logic with fairness and maintenance in mind.
3. Stress-test the model for social harm, confusion, and cost.
4. Export a membership framework with review and sunset rules.

## Artifact Template

Artifact: `membership-framework`

Required sections:
- Tier structure with purpose and entry logic
- Perks, access rules, and recognition signals
- Operational limits and moderation implications
- Fairness notes, non-paid pathways, and downgrade paths
- Pilot framework and review checkpoints

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional settings/history window.
- Primary actions:
  - `Set Tiers`
  - `Design Access`
  - `Review Perks`
  - `Export Framework`
- Popover priority: source state first, artifact preview second, export third.
- Optional window: saved runs, source weighting, export format, and review notes.

## First Run UX

Ask whether the membership model includes paid access, invite-only layers, or recognition-only tiers, then ask what moderation and support capacity is realistic.

## States

### Empty

Show a tier-planning view with sample perk types, fairness reminders, and one prominent action: Set Tiers.

### Loading

Display tier count and a progress note that the system is balancing access value, fairness, and operational cost.

### Error

Tell the user whether the request lacks enough operational detail or depends on manipulative or exclusionary mechanics the skill will not support.

## Icon Brief

Use concentric circles with a central star to imply structured belonging and recognition. The icon should feel premium but not gaudy.

## Brand Color

`#BF9640`

## Layout Notes

- Use one row per tier with purpose, access logic, and risk note visible at a glance.
- Keep fairness and downgrade paths close to the perk definitions.
- Use gold accents sparingly so the product feels premium without becoming flashy.
