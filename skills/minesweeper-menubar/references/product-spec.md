# Minesweeper Menu Bar Product Spec

## Goal

Ship a Swift macOS menu-bar icon app that lets the user play Minesweeper inside a compact popover.

## Core Loop

1. Click the menu bar icon.
2. Read the board immediately.
3. Reveal or flag cells without opening extra windows.
4. Win or lose a quick round.
5. Restart instantly from the same popover.

## v1 Scope

- SwiftUI `MenuBarExtra` app shell
- 8x8 board with 10 mines
- first-click safety
- reveal mode and flag mode
- timer, mine counter, win-loss messaging
- quick reset and small local stats

## Constraints

- Keep the app menu-bar first.
- Keep the board fully playable in the popover.
- Do not add network services, accounts, or extra setup.
- Make the icon and UI feel like a polished Mac micro game.

## Follow-on Ideas

- difficulty presets
- daily seeded boards
- a shared micro-game shell for other menu bar arcade ideas
