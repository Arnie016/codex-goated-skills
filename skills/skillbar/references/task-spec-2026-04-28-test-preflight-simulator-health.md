## Task Spec: SkillBar test preflight catches simulator drift

- Scope: make `bash scripts/run_skillbar.sh doctor` and `bash scripts/run_skillbar.sh test` surface CoreSimulator/Xcode drift before the full test run begins.
- Why now: install, update, catalog, and audit checks pass, but the test path is confusing because `xcodebuild` reports `CoreSimulator is out of date` while the current preflight still says Xcode is ready.
- Planned change:
  - keep the existing macOS sandbox and `testmanagerd` failure summaries
  - add a fast test-environment probe that inspects the current Xcode/test path for simulator drift
  - report that probe in `doctor`
  - fail `test` early with the same concrete blocker instead of entering a slower, ambiguous `xcodebuild test` path
- Verification:
  - `bash scripts/run_skillbar.sh doctor`
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh test`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
