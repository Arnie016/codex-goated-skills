# Gain Tracker Product Spec

## Target User

Developers, founders, operators, and solo builders who want to measure a real output improvement arc against a historical baseline and a future target.

## Inputs

- repo path plus baseline and current git windows when the user wants commit-backed measurement
- baseline output total and baseline duration
- current output total and current duration
- goal multiplier such as `90x`
- metric definition such as git commits, lines changed, files changed, weighted output score, or active days
- notes on drivers such as GStack, better prompts, team support, or cleaner workflow loops
- optional checkpoints to show how the multiplier is changing over time

## Input To Output Flow

1. Confirm one consistent metric definition across the baseline and current periods.
2. If a repo is available, pull git stats first and let the user choose `commits`, `lines-changed`, `files-changed`, or `active-days`.
3. Normalize both periods into per-day or per-week rates.
4. Calculate the current multiplier and target progress.
5. Export a gain scorecard with the math, the narrative, and the next checkpoint.

## Artifact Template

Artifact: `gain-scorecard`

Required sections:
- Metric definition and comparison rules
- Baseline period versus current period
- Current multiplier and target progress
- Systems driving the gain
- Next checkpoint and confidence notes

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional history window.
- Primary actions:
  - `Set Baseline`
  - `Log Current Output`
  - `Recalculate Gain`
  - `View Scorecard`
  - `Export Snapshot`
- Popover priority: current multiplier first, baseline/current math second, narrative notes third.
- Optional window: checkpoint history, driver notes, and export list.

## First Run UX

Ask for the metric definition, the baseline and current windows, and the target multiplier. If the user points at a repo, offer a git-backed mode before asking them to type totals manually.

## States

### Empty

Show a simple baseline card with examples such as 2013 commit totals, last-80-days commit totals, and a target like `90x`, plus one primary action: Set Baseline.

### Loading

Display the baseline rate, current rate, and a short note that the system is recalculating the multiplier and goal progress.

### Error

Explain whether the issue came from missing totals, zero-day windows, or an invalid goal multiplier, then preserve the entered numbers for retry.

## Icon Brief

Use a stacked bar plus rising arrow glyph to signal compounding output gains. The large icon should feel like a polished green performance chip, while the small icon stays legible in a menu bar and catalog row.

## Brand Color

`#0F9D58`

## Layout Notes

- Keep the current multiplier pinned near the top in a bold stat row.
- Use compact baseline and current cards so the comparison feels immediate.
- Make the export affordance lightweight: Markdown, plain text, or a short snapshot card.
