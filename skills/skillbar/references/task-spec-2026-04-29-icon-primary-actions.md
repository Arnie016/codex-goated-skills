# Task Spec: Icon Primary Actions

## Goal

Wire the existing icon-specific primary actions into the SkillBar icon detail panel so the icon board directly supports the common menu-bar icon flow instead of only exposing generic install/update buttons.

## Scope

- Keep the change inside the existing SkillBar model and icon detail view.
- Reuse the current model helpers for pinning, clearing, and install-plus-pin behavior.
- Add or update unit tests around the action routing.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
