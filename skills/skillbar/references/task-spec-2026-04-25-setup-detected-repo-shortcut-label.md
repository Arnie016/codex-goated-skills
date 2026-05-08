## Task Spec: Setup Detected Repo Shortcut Label

- Scope: tighten the Setup repo row so the detected-clone fallback reads like a direct action instead of a generic state label.
- Why now: SkillBar already identifies the strongest alternate local clone, but the setup surface still asks users to interpret `Use Detected` instead of naming the repo it will switch to.
- Planned change:
  - keep repo discovery, normalization, and switching behavior unchanged
  - update the Setup repo-row shortcut to use the detected clone's last path component in the button label
  - keep the broader detected-repo switcher below for full-path browsing and fallback selection
- Verification:
  - `bash skills/skillbar/scripts/run_skillbar.sh typecheck`
  - `bash skills/skillbar/scripts/run_skillbar.sh doctor`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
