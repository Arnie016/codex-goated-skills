---
name: repo-launch
description: Scaffold and polish a GitHub-ready project repository. Use when Codex needs to turn an idea or local project into a clean shareable repo with essentials like a README, license, install steps, contribution basics, and a simple launch-ready structure.
---

# Repo Launch

Use this skill when a project needs to go from loose files or a rough prototype to a clean, public-facing repository.

## Quick Start

1. Inspect the current project shape before adding files or changing structure.
2. Choose a repository mode first: app repo, skill catalog, library, template, or multi-project collection.
3. Create only the minimum repo essentials the project actually needs.
4. Prefer a short, scannable `README.md` with one clear install or usage path.
5. Add a `LICENSE` when the user wants the repo to be shareable.
6. Keep names, commands, and folder structure simple enough for first-time visitors.

## Workflow

### Repository Basics

- Start with the smallest useful set of files: `README.md`, `.gitignore`, `LICENSE`, and project-specific entrypoints.
- Match the repository structure to the project type instead of forcing a template.
- If there is already a strong project layout, improve it rather than replacing it.
- If the repo has more than one top-level product, create a compact index and avoid repeating setup instructions in multiple places.

### Launch Readiness

- Make the repo understandable from the first screen on GitHub.
- Prefer one copy-paste install or run command over long setup prose.
- Surface the main value of the project in one sentence near the top.
- If the repo contains multiple packages or apps, add a compact index instead of long documentation.
- Always leave the user with a visible "start here" path: one command, one folder, or one primary entrypoint.

### Required Deliverables

- A top-level `README.md` that answers:
  - what this is
  - how to run or install it
  - where the main folders are
- A matching `.gitignore` for the project stack.
- A license file when the repo is intended to be shared.
- A small amount of launch polish if needed: badges, examples, or a table index.

### Decision Rules

- If the project is a single app, optimize the README for first-run success.
- If the project is a catalog, optimize the README for browsing and installation by name.
- If the project is a starter or template, make setup steps explicit and short.
- If there is no stable install flow yet, say so clearly instead of faking one.

### Editing Guidance

- Keep generated copy plain and concrete, not hypey.
- Use action-oriented names for scripts, folders, and commands.
- Avoid adding extra docs unless they remove real confusion for contributors or users.
- Do not bury the main install command below long narrative text.
- Avoid skeleton files that look official but add no actual value.

## Resources

- `agents/openai.yaml`: UI metadata and default invocation prompt.
- `assets/`: branded icons for repo listings and skill chips.
- `references/repo-patterns.md`: lightweight patterns for app repos, catalog repos, templates, and libraries.
