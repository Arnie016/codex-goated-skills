## Task Spec: Zero-Available Pack Detected Repo Recovery

- Scope: tighten the fully-broken pack recovery card in SkillBar without changing pack parsing or install/update command wiring.
- Problem: when a pack resolves to zero local skills because the wrong repo clone is selected, the current recovery card only offers generic setup or repo browsing actions even when SkillBar already knows a better detected clone.
- Change:
  - expose a direct pack-recovery shortcut that adopts the preferred detected repo clone
  - show which candidate repo the recovery action will use
  - keep the existing setup and repo inspection actions as fallbacks
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
