## Task Spec: Pack Browse Available Members

- Scope: tighten the broken-pack browse path without changing install/update command wiring or catalog parsing.
- Problem: when a pack has unresolved skill references, SkillBar still tracks the full declared member list during pack focus and reports that inflated count back to the user even though only the resolved local members can actually appear in Discover.
- Change:
  - derive focused pack members from the resolved local catalog entries instead of the raw declared pack list
  - update pack-focus status copy so broken packs report available members and missing references accurately
  - make the broken-pack fallback button label reflect whether there are available members to browse or only metadata to review
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
