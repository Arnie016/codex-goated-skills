# Task Spec: Local Icon Action Gating

Date: 2026-05-07

## Goal

Keep SkillBar's local menu-bar icon actions available whenever they can safely run without the CLI.

## Scope

- Let `Use Default` and `Pin to Bar` depend on busy state, not repo readiness.
- Keep install and update actions gated by both busy state and valid repo selection.
- Add focused unit coverage for icon action gating.

## Non-Goals

- Do not change install, update, pack, or catalog parsing behavior.
- Do not redesign the icon board layout.
