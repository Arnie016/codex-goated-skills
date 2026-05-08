## Task Spec: Setup Row Direct Actions

- Scope: make the active repo path and installs path rows directly actionable without changing catalog parsing or install/update plumbing.
- Problem: Setup already exposes the selected paths, but opening or revealing those locations still requires scanning other parts of the panel instead of acting from the row the user is inspecting.
- Change:
  - add direct `Open` and `Reveal` actions to the repo root row
  - add direct `Open` and `Reveal` actions to the installed skills row
  - remove duplicated reveal buttons from the guardrails block so setup actions stay clustered around the selected paths
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
