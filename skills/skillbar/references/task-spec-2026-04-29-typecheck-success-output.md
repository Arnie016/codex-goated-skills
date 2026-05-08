## Task Spec: Typecheck Success Output

- Scope: tighten the packaged SkillBar runner so `bash scripts/run_skillbar.sh typecheck` reports a clear success line after the Swift source-only check completes.
- Problem: the current typecheck path exits silently on success, which makes the local validation loop look ambiguous in Codex runs and other automation surfaces.
- Change:
  - keep the existing `swiftc -typecheck` behavior unchanged
  - print a compact success summary with the number of checked Swift source files and the source root path
  - avoid changing build, test, install, or audit semantics
- Validation:
  - `bash scripts/run_skillbar.sh doctor`
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh smoke-install skillbar`
  - `bash scripts/run_skillbar.sh smoke-update skillbar`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
