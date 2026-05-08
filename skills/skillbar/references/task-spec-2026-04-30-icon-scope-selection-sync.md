# Task Spec: Icon Scope Selection Sync

## Problem

SkillBar's icon board preserves the last selected icon tile until search text changes or the full catalog reloads. When the visible icon scope changes because of pack focus or scope reset, the detail panel can keep pointing at a stale selection that is no longer in the current icon list.

## Scope

- Drive icon selection sync from the scoped icon ID list instead of only search text and catalog reloads.
- Preserve the current selection when it still exists in the visible icon scope.
- Fall back to the first visible icon when the current selection drops out of scope, and clear the selection when no icons remain.
- Add a focused regression test for the selection helper.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
