# Reputation Heatmap Product Spec

## Target User

PR leads, talent teams, founders, operators, and community managers who need calm, defensible risk mapping around public narrative shifts.

## Inputs

- press coverage, community chatter, rumor summaries, and brand concern lists
- notes about what is confirmed, unconfirmed, private, or already addressed
- community moderation reports or escalation logs
- existing communication principles, legal constraints, or no-comment boundaries

## Input To Output Flow

1. Load signals with explicit verification labels and communication boundaries.
2. Score each signal for severity, confidence, and amplification risk.
3. Choose response modes and escalation owners.
4. Export a playbook with clear do, do not, and review rules.

## Artifact Template

Artifact: `response-playbook`

Required sections:
- Heatmap of low, medium, and high-risk signals
- Confirmed versus unconfirmed narrative map
- Response modes: address, clarify, monitor, or do not amplify
- Escalation thresholds and owners
- No-response rules and red lines for privacy or safety

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional settings/history window.
- Primary actions:
  - `Add Signals`
  - `Map Risk`
  - `Review Thresholds`
  - `Export Playbook`
- Popover priority: source state first, artifact preview second, export third.
- Optional window: saved runs, source weighting, export format, and review notes.

## First Run UX

Ask for the signal list, what is confirmed versus unconfirmed, and any hard legal or privacy boundaries before scoring risk.

## States

### Empty

Show a risk intake view with example signal types and a reminder that the skill will not help amplify unverified rumors.

### Loading

Display signal count and a note that the system is separating mystique, rumor, and confirmed brand risk.

### Error

Explain whether the request is missing verification context or asks the skill to amplify, retaliate against, or operationalize harmful speculation.

## Icon Brief

Use a heatmap tile cluster with a shield-like outline to signal calm risk mapping. The look should feel like an operations tool, not a crisis siren.

## Brand Color

`#D26B4E`

## Layout Notes

- Use concise risk rows with confidence and response mode visible in one line.
- Make 'do not amplify' a prominent state, not a footnote.
- Keep warning colors controlled so the UI still reads as calm and professional.
