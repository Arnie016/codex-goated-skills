## Task Spec: Stream SkillBar xcodebuild output live

- Scope: improve the shared SkillBar runner used by repo-root and packaged validation commands.
- Problem: `build` and `test` buffer `xcodebuild` output into a temp log and only print it after success, which makes long local runs and automations look stalled.
- Change:
  - stream `xcodebuild` stdout and stderr live through the shared logging helper
  - keep the existing failure-summary logic and temp-log fallback for blocked or failed runs
  - avoid changing SkillBar app code, catalog plumbing, or install/update behavior
- Validation:
  - `bash scripts/run_skillbar.sh doctor`
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
