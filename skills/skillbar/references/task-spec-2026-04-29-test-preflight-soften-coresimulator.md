## Task Spec: Test Preflight Softens CoreSimulator Failure

- Scope: tighten the packaged SkillBar runner so `test` does not stop early on a CoreSimulator version warning when the macOS unit-test invocation can still run.
- Problem: `bash scripts/run_skillbar.sh test` currently exits during preflight with a CoreSimulator warning, which hides the actual macOS test-runner result in sandboxed sessions and makes the verification path less trustworthy.
- Change:
  - treat the CoreSimulator preflight warning as informational for the `test` command instead of a hard stop
  - keep the direct `xcodebuild test -destination 'platform=macOS'` execution in place so real runner failures still surface through the existing log summarizer
  - update the guidance copy so the warning is described as simulator-related rather than a guaranteed macOS test blocker
- Validation:
  - `bash scripts/run_skillbar.sh doctor`
  - `bash scripts/run_skillbar.sh test`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
