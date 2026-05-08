# Task Spec

- Problem: `bash scripts/run_skillbar.sh inspect` no longer shows the full SkillBar surface that current work relies on, which hides the project map, menu bar icon file, and newer test files during quick orientation.
- Goal: make `inspect` list the current high-signal files so the runner stays honest as the app grows.
- Scope: `skills/skillbar/scripts/run_skillbar.sh` only.
- Validation: `bash scripts/run_skillbar.sh inspect`, `bash scripts/run_skillbar.sh doctor`
