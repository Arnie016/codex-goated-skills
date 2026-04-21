# Minefield Menu Bar Product Spec

## Goal

Ship a genuinely playable macOS menu-bar puzzle that captures the quick tension of Minesweeper without turning into a full desktop game launcher.

## Core Loop

1. Open the menu bar popover.
2. Read the board state in one glance.
3. Toggle between reveal and flag modes.
4. Clear the board or hit a mine in under two minutes.
5. Restart instantly for another round.

## v1 Scope

- 8x8 board sized for a menu-bar popover
- 10 mines with first-tap safety
- reveal cascade for empty cells
- flag mode, mine counter, timer, win-loss state
- one-tap reset and a small streak or best-time readout

## Menu Bar Constraints

- Keep the whole game playable inside a compact popover.
- Do not depend on extra windows, login, network state, or background services.
- Favor bold readability over dense chrome.
- Make replay faster than setup.

## Tone

Arcade-clean, slightly neon, and native to macOS rather than retro-for-retro's-sake.

## Follow-on Ideas

- difficulty presets that still fit inside the popover
- daily seed challenge
- other top-bar micro games that share the same shell
