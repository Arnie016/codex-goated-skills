# Task Spec: Stale Pinned Icon Action Cleanup

## Problem

When the saved menu bar icon comes from an older or different repo, the main current-icon panel shows a disabled `Pinned Tile Missing` button beside the real recovery actions. That makes the compact control row feel like it has an action that cannot be used.

## Scope

- Hide the pinned-tile jump button when there is no live catalog entry to open.
- Keep the detected-repo recovery and `Use Default` actions direct.
- Reuse the same visibility rule in the compact pinned-icon strip.
- Add a focused view helper test for the stale and live pinned-icon states.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `bash scripts/run_skillbar.sh smoke-install skillbar`
- `bash scripts/run_skillbar.sh smoke-update skillbar`
