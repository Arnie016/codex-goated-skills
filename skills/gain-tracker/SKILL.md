---
name: gain-tracker
description: Track output gains against a historical baseline and a target multiplier, then turn the numbers into a gain scorecard. Use when Codex needs to measure current pace, compare it to an older baseline like 2013, credit the systems driving the lift such as GStack, and show progress toward a goal like 90x.
---

# Gain Tracker

Use this skill when the user wants to quantify an improvement arc instead of just describing it.

Default product shape: a compact macOS `MenuBarExtra` utility with baseline capture, current-period logging, checkpoint history, and exportable scorecards.

## Quick Start

1. Define one stable output metric before comparing time periods.
2. Capture the baseline total and the number of days in that baseline period.
3. Capture the current total, the current time window, and the target multiplier.
4. Run `python3 scripts/gain_math.py` for the apples-to-apples math.
5. Produce a `gain-scorecard` with both the numbers and the explanation of what is driving the lift.

## Accepted Inputs

- a baseline period such as 2013 output totals and the number of days those totals cover
- a current period such as the last 30, 80, or 90 days of output and the number of days in that window
- a target multiplier such as `10x`, `25x`, or `90x`
- the metric definition, such as files shipped, merged PRs, lines changed, features delivered, or a weighted output score
- notes on what changed, such as GStack, tooling upgrades, workflow changes, or team support
- optional checkpoints over time so the gain curve can be tracked, not just a single before and after

## Output Artifact

Primary artifact: `gain-scorecard`

Default sections:
- Metric definition and comparison rules
- Baseline period versus current period
- Current multiplier, goal progress, and pace delta
- Systems driving the gain, such as GStack or workflow changes
- Next checkpoint, confidence notes, and what to keep stable

## Workflow

### Normalize The Comparison

- Use one metric definition across both time windows.
- Convert totals into daily or weekly rates before computing a multiplier.
- Flag missing context when the baseline and current periods are not actually comparable.

### Calculate The Gain

- Start with the helper script when the user has numeric totals and day counts.
- Report current multiplier, rate delta, target progress, and remaining gap to the goal.
- Keep the math visible enough that the user can trust the result.

### Build The Artifact

- Turn the math into a short scorecard, not just a raw number dump.
- Credit the systems and habits that appear to be responsible for the lift.
- Call out if the gain seems real but the metric is still too noisy to treat as a hard KPI.

### Mac Product Shape

- Prefer `MenuBarExtra` with these primary actions:
  - `Set Baseline`
  - `Log Current Output`
  - `Recalculate Gain`
  - `View Scorecard`
  - `Export Snapshot`
- Keep the popover between 320 pt and 380 pt wide with the current multiplier visible above the fold.
- Use an optional history window for checkpoints, notes, and exported scorecards.

### Safety Boundaries

- Do not treat output as a proxy for human worth.
- Avoid advice that pushes unsafe schedules, burnout, or deceptive metric inflation.
- Do not fabricate historical baselines or overstate causality from a single tool change.
- If the metric definition changed over time, say so clearly before presenting the multiplier as settled.

## Example Prompts

- `Use $gain-tracker to compare my coding output from 2013 to my last 80 days, calculate my current multiplier, and show progress toward a 90x goal.`
- `Use $gain-tracker to turn these baseline and current output totals into a gain scorecard, and note that GStack is the main system behind the lift.`

## Resources

- `scripts/gain_math.py`: deterministic multiplier, pace, and goal-progress calculator.
- `references/product-spec.md`: menu bar product shape, artifact template, first-run UX, and icon direction.
