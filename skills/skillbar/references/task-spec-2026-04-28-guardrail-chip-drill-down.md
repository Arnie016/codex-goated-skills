# Task Spec: SkillBar guardrail chip drill-down

## Goal

Turn SkillBar's icon-quality guardrail chips into direct navigation controls so icon issues are actionable instead of passive.

## Scope

- Add a duplicate-focused icon-board filter alongside the existing pinned, installed, and missing-art filters.
- Let the catalog guardrail chips jump into repo-wide missing-art or duplicate views.
- Let the icon-board quality chips jump into the current scoped missing-art or duplicate views without clearing the active scope.
- Keep duplicate-name detection in a testable model helper.

## Non-Goals

- No install or update flow changes.
- No catalog metadata or pack membership changes.
- No broad menu layout rewrite.
