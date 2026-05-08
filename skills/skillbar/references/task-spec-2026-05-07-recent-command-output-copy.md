# Task Spec: Recent Command Output Copy

## Goal

Make SkillBar's recent command output panel easier to use after audit, install, update, or development-loop failures by adding a direct clipboard copy action next to Clear.

## Scope

- Keep the action local-only through the macOS pasteboard.
- Preserve the existing recent-output panel and Clear behavior.
- Avoid changing command execution, persistence, or repo-health plumbing.

## Verification

- `bash scripts/run_skillbar.sh typecheck`
- Existing catalog and smoke checks for the automation run.
