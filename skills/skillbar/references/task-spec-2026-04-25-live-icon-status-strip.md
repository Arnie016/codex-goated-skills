## Task Spec: Live Icon Status Strip

- Scope: tighten the Icons header so the currently live menu bar icon and any pinned-only state are obvious before opening the detail card.
- Why now: SkillBar already exposes live-icon actions, but the header still buries the active icon inside a generic chip and mixes `Reveal Pinned` with `Show Live Icon` style copy.
- Planned change:
  - keep pin, install, update, and snapshot behavior unchanged
  - promote the current live icon into a clearer header row with its install state visible at a glance
  - normalize hidden-live-icon actions to `Show Live Icon` across the icon surface
  - make the pinned filter title read like a single live-icon view instead of a generic multi-icon grid
- Verification:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh smoke-install skillbar`
  - `bash scripts/run_skillbar.sh smoke-update skillbar`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
