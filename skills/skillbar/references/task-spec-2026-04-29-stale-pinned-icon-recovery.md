## Task

Add a direct recovery action when the saved pinned SkillBar icon no longer exists in the active repo catalog.

## Why

- The Icons header can currently surface a stale pinned selection as "Current Unavailable".
- That state explains the problem but still leaves the user in a dead-end path unless they infer that they should manually reset back to the default icon.
- A one-tap recovery keeps the menu-bar icon flow compact and direct.

## Scope

- Detect when a pinned menu-bar snapshot exists but the live catalog entry is gone.
- Expose a dedicated recovery state from the model.
- Replace the disabled "Current Unavailable" shortcut with an active "Use Default" action in the Icons header.
- Add model tests for the stale-pin recovery state and reset behavior.

## Files

- `apps/skillbar/SkillBarApp/Sources/App/SkillBarModel.swift`
- `apps/skillbar/SkillBarApp/Sources/Views/MenuBarView.swift`
- `apps/skillbar/SkillBarApp/Tests/SkillBarModelTests.swift`

## Verification

- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh smoke-install skillbar`
- `bash scripts/run_skillbar.sh smoke-update skillbar`
