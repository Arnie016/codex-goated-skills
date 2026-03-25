# Gain Tracker Product Spec

Visual thesis: a premium progress instrument that feels like a compact trophy case for daily momentum, not a dashboard full of admin cards.

## Target User

Developers, founders, operators, and solo builders who want to measure a real output improvement arc against a historical baseline and a future target, while also seeing a daily reminder that keeps the run emotionally real.

## Inputs

- connected GitHub identity from `gh auth`
- tracked repo list stored under `~/.codex/gain-tracker/config.json`
- repo path plus baseline and current git windows when the user wants commit-backed measurement
- baseline output total and baseline duration
- current output total and current duration
- goal multiplier such as `90x`
- metric definition such as git commits, lines changed, files changed, weighted output score, or active days
- notes on drivers such as GStack, better prompts, team support, or cleaner workflow loops
- optional checkpoints to show how the multiplier is changing over time
- a preference for `scorecard`, `daily-story`, or `both`

## Input To Output Flow

1. Confirm one consistent metric definition across the baseline and current periods.
2. Connect once through GitHub CLI and store the identity plus tracked repos.
3. If a repo is available, pull git stats first and let the user choose `commits`, `lines-changed`, `files-changed`, or `active-days`.
4. For daily mode, calculate today's work, seven-day momentum, thirty-day momentum, and current streak.
5. Normalize broader comparisons into per-day or per-week rates.
6. Calculate the current multiplier and target progress.
7. Export a gain scorecard, a daily reminder story, or both.

## Artifact Template

Artifact: `gain-scorecard`

Artifact: `daily-gain-story`

Required sections:
- Metric definition and comparison rules
- Baseline period versus current period
- Current multiplier and target progress
- Systems driving the gain
- Next checkpoint and confidence notes

Daily story sections:
- Today's work at a glance
- Recent momentum and streak
- What moved in code terms
- Reminder story

## SwiftUI Surface

- Shell: `MenuBarExtra` with an optional history window.
- Primary actions:
  - `Connect`
  - `Today`
  - `Story`
  - `Compare`
  - `Trend`
- Secondary actions:
  - `Export`
  - `Tracked Repos`
  - `Settings`
- Popover priority: connection state first, today's headline stat second, reminder story third, trend strip fourth.
- Optional window: checkpoint history, comparison modes, driver notes, and export list.

## UI Direction

- Avoid generic dashboard cards. The popover should feel like a single crafted instrument panel.
- Lead with a connected-account chip showing avatar, GitHub login, and tracked repo count when available.
- Use a top hero strip with the daily headline such as `8 commits today` or `1,240 lines moved`.
- Put the reminder story in a warm editorial block with tighter copy and a little breathing room, not a chat bubble.
- Use one accent color only: the existing green should feel like signal, not decoration.
- Make the trend area feel like a compact sparkline or momentum rail instead of a full chart wall.
- Use large rounded numbers, quieter labels, and a narrow typographic rhythm so the eye lands on the gains immediately.
- Add one meaningful motion: the top stat should animate in, and the trend rail should reveal from left to right when recalculated.
- Treat repo chips as slim pills or rows, not boxed cards.

## First Run UX

Ask the user to connect GitHub first, then offer to track the current repo or add other repos. After connection, suggest daily story mode by default before asking for any manual totals.

## States

### Empty

Show a strong daily pulse surface with examples such as `0 commits yet`, `3 commits today`, or `14-day streak`, plus one primary action: Connect GitHub.

### Loading

Display today's work, recent trend context, and a short note that the system is refreshing the daily story and gain math.

### Error

Explain whether the issue came from a missing repo, invalid dates, zero-day windows, or an invalid goal multiplier, then preserve the entered numbers for retry.

## Icon Brief

Use a stacked bar plus rising arrow glyph to signal compounding output gains. The large icon should feel like a polished green performance chip, while the small icon stays legible in a menu bar and catalog row.

## Brand Color

`#0F9D58`

## Layout Notes

- Keep the current multiplier pinned near the top in a bold stat row.
- Keep today's headline work stat above the fold next to a compact streak badge.
- Use one comparison rail for `Today`, `7D`, `30D`, and `Goal` instead of a mosaic of tiles.
- Make the export affordance lightweight: Markdown, plain text, or a short snapshot card.
