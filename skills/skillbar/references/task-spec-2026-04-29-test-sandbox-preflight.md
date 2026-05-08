## Task Spec: Test Runner Sandbox Preflight

- Scope: tighten the packaged SkillBar runner so `bash scripts/run_skillbar.sh test` fails early and clearly inside Codex's seatbelt sandbox instead of falling through to a noisy `xcodebuild` runner crash.
- Problem: current preflight only probes Xcode destinations, so sandboxed sessions still launch `xcodebuild test` and then fail on `testmanagerd.control`, which obscures the real limitation and slows the local validation loop.
- Change:
  - detect the Codex seatbelt sandbox from the environment before the macOS test invocation
  - report a direct, actionable message that points users to `typecheck` plus smoke checks in constrained sessions
  - preserve an explicit override for cases where a raw test attempt is still desired
- Validation:
  - `bash scripts/run_skillbar.sh doctor`
  - `bash scripts/run_skillbar.sh test`
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh smoke-install skillbar`
  - `bash scripts/run_skillbar.sh smoke-update skillbar`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
