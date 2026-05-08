## Task Spec: Repo-Root SkillBar Runner Wrapper

- Scope: make the repo-root `scripts/run_skillbar.sh` entrypoint the stable way to run SkillBar checks from this checkout.
- Problem: repo automation prompts and AGENTS verification steps reference `bash scripts/run_skillbar.sh ...`, while the durable implementation lives under `skills/skillbar/scripts/run_skillbar.sh`. That mismatch makes routine validation feel less direct and causes avoidable command failures in packaged clones.
- Change:
  - keep the real runner implementation in `skills/skillbar/scripts/run_skillbar.sh`
  - add or preserve a thin repo-root wrapper at `scripts/run_skillbar.sh`
  - update the SkillBar skill docs and project map to point at the wrapper while noting that it delegates to the packaged runner
- Validation:
  - `bash scripts/run_skillbar.sh doctor`
  - `bash scripts/run_skillbar.sh inspect`
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
