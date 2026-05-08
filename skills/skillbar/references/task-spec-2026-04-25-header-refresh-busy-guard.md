## Task Spec: Header Refresh Busy Guard

- Scope: make the top-level refresh affordance reflect SkillBar's serialized command model while installs, updates, audits, or checks are running.
- Why now: the header refresh button still looks available during active commands even though SkillBar intentionally blocks overlapping work, which makes the state feel inconsistent and invites confusing status resets.
- Planned change:
  - keep internal refresh behavior after successful commands unchanged
  - disable the header refresh button while a command is active or when no valid repo is selected
  - update the hover copy so the reason is obvious from the menu bar surface
- Verification:
  - `bash skills/skillbar/scripts/run_skillbar.sh typecheck`
  - `bash skills/skillbar/scripts/run_skillbar.sh test`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
