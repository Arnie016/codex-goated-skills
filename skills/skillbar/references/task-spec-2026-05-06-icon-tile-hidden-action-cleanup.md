# Task Spec: Icon Tile Hidden Action Cleanup

Date: 2026-05-06

## Problem

The icon board still had a hidden double-click gesture on every icon tile that ran install or update. That made a common action invisible and risked accidental command execution from a selection surface.

## Scope

- Keep icon tiles as explicit selection targets.
- Route install, update, reveal, and pin choices through the visible selected-icon detail controls.
- Update hover help so users understand the visible manage flow.
- Avoid changing catalog parsing, install plumbing, or pack behavior.

## Verification

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
