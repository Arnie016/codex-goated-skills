## Task Spec: SkillBar test preflight adds fix guidance

- Scope: tighten the shared `skills/skillbar/scripts/run_skillbar.sh` runner messaging for test-environment blockers.
- Why now: the runner already detects CoreSimulator drift and related test-runner failures, but `doctor` and `test` still stop at a diagnosis without telling the user the fastest next step.
- Planned change:
  - keep the existing detection logic and failure summaries
  - add compact, case-specific remediation guidance for known test-environment blockers
  - show that guidance in `doctor`
  - reuse the same guidance when `test` exits early
- Validation:
  - `bash scripts/run_skillbar.sh doctor`
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh test`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
