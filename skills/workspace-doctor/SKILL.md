---
name: workspace-doctor
description: Diagnose local workspace readiness and common setup problems. Use when Codex needs to check project health, missing tools, auth gaps, environment mismatches, broken install steps, or other practical blockers that stop a user from building or running something.
---

# Workspace Doctor

Use this skill when the fastest path forward is to inspect the machine, the workspace, and the project setup before making deeper changes.

## Quick Start

1. Reproduce the problem with the smallest safe command that reveals the issue.
2. Check the local environment before blaming the code.
3. Explain blockers in plain language and prefer direct fixes over abstract advice.
4. Distinguish between missing tools, auth problems, dependency issues, and actual code errors.
5. Use the local diagnostic script first when a quick workspace inventory would help.

## Workflow

### Diagnose First

- Inspect the current workspace layout, package manager files, and toolchain markers.
- Check versions, missing CLIs, missing secrets, and obvious environment mismatches.
- Prefer targeted commands that confirm one hypothesis at a time.
- Start with `bash scripts/workspace_doctor.sh` when you want a fast machine and repo inventory.

### Fix Carefully

- Apply the smallest useful fix first.
- If a blocker is machine-specific, say so clearly.
- If the project has an existing script for doctor, build, test, or setup, use that before inventing a new flow.
- Separate "cannot run on this machine yet" from "code is actually broken."

### Required Deliverables

- A ranked diagnosis of the likely blocker.
- The exact command or change needed to unblock the next step.
- A note about whether the issue is machine, environment, dependency, or code related.

### Common Checks

- repo root markers such as `.git`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `project.yml`
- available CLIs such as `git`, `node`, `npm`, `pnpm`, `python3`, `pip`, `uv`, `cargo`, `go`, `docker`, `xcodebuild`
- auth-sensitive CLIs only when relevant, such as `gh`
- project scripts such as `test`, `build`, `dev`, `doctor`, or custom setup commands

### Editing Guidance

- Keep troubleshooting output concrete and ranked by likely cause.
- Avoid flooding the user with every possible issue if one root blocker explains the failure.
- Leave the workspace in a more runnable state than you found it.

## Resources

- `agents/openai.yaml`: UI metadata and default invocation prompt.
- `assets/`: branded icons for repo listings and skill chips.
- `scripts/workspace_doctor.sh`: quick inventory of common workspace markers and local tools.
- `references/diagnostic-order.md`: preferred order for narrowing environment and setup issues.
