## Task Spec: Refresh Busy Guard and Test Sandbox Guidance

- Scope: tighten one common SkillBar action and one verification path without changing catalog parsing, install/update semantics, or Swift app structure.
- Problem:
  - the header refresh button stays clickable while another command is running, which can replace a meaningful in-flight status with a generic refresh state
  - the packaged `test` runner already gets past CoreSimulator preflight, but sandbox-blocked macOS test execution still reads like a generic xcodebuild failure
- Change:
  - disable the main header refresh action while SkillBar is busy
  - make sandbox-blocked `testmanagerd.control` failures explicitly describe that build/test launch reached execution but the sandbox stopped the runner
  - keep existing CLI invocation and repo-health flows unchanged
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh smoke-install skillbar`
  - `bash scripts/run_skillbar.sh smoke-update skillbar`
  - `bash scripts/run_skillbar.sh test`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
