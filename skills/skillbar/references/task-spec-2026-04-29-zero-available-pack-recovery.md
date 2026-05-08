## Task Spec: Zero-Available Pack Recovery

- Scope: tighten the fully-broken pack recovery path in SkillBar without changing catalog parsing or install/update command wiring.
- Problem: when a pack resolves to zero local skills, the current `Review Pack` action pushes users into an empty Discover view that reads like a generic empty state instead of a pack-specific recovery flow.
- Change:
  - keep zero-available broken packs anchored in the Packs section when users choose `Review Pack`
  - add an inline recovery panel on those pack cards with direct setup and repo actions
  - reuse pack-derived copy so the warning stays specific about missing local members
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
