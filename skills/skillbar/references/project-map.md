# SkillBar Project Map

## Workspace

- App workspace: `apps/skillbar`
- Paired skill package: `skills/skillbar`
- CLI dependency: `bin/codex-goated`

## Core Responsibilities

- Read skill metadata from the local repo under `skills/*`
- Read installed state from `~/.codex/skills` or a user-selected destination
- Run `bin/codex-goated install` and `bin/codex-goated update` with explicit repo and destination paths
- Run `bin/codex-goated catalog check` and `bin/codex-goated audit` for repo-health validation
- Expose compact preset bundles that map to existing skills

## Main Files

- `scripts/run_skillbar.sh`
  - repo-root wrapper that delegates to the packaged SkillBar runner under `skills/skillbar/scripts`
- `apps/skillbar/project.yml`
  - XcodeGen spec for the app and unit-test bundle
- `apps/skillbar/SkillBarApp/Sources/App/SkillBarApp.swift`
  - `MenuBarExtra` entrypoint
- `apps/skillbar/SkillBarApp/Sources/App/SkillBarModel.swift`
  - app state, path setup, refresh, install, repo-health, and preset actions
- `apps/skillbar/SkillBarApp/Sources/Models/SkillBarModels.swift`
  - shared catalog, preset, pack, and command models
- `apps/skillbar/SkillBarApp/Sources/Services/SkillCatalogService.swift`
  - repo-root discovery plus skill and pack metadata parsing
- `apps/skillbar/SkillBarApp/Sources/Services/SkillInstallService.swift`
  - deterministic process descriptor and CLI execution
- `apps/skillbar/SkillBarApp/Sources/Views/MenuBarView.swift`
  - compact menu bar UI, setup surface, repo-health actions, pack browsing, and preset confirmation flow
- `apps/skillbar/SkillBarApp/Tests/SkillCatalogServiceTests.swift`
  - parser, command descriptor, and preset coverage

## Validation Path

- `bash scripts/run_skillbar.sh doctor`
  - confirm workspace shape, CLI presence, and Xcode readiness
- `bash scripts/run_skillbar.sh inspect`
  - print the main app files before editing
- `bash scripts/run_skillbar.sh typecheck`
  - run a fast source-only sanity check before a full build
- `bash scripts/run_skillbar.sh smoke-install skillbar`
  - prove one real install path through `bin/codex-goated`
- `bash scripts/run_skillbar.sh smoke-update skillbar`
  - prove the overwrite path through `bin/codex-goated update`
- `bash scripts/run_skillbar.sh catalog-check`
  - confirm the generated catalog index is current
- `bash scripts/run_skillbar.sh audit`
  - run the repo-wide skill and pack integrity audit
- `bash scripts/run_skillbar.sh test`
  - run the unit tests once Xcode is ready

## Guardrails

- Keep SkillBar menu-bar-first and local-first.
- Do not bypass `bin/codex-goated` with parallel install logic.
- Do not turn preset bundles into dynamic marketplace state.
- Do not add secrets or remote sync responsibilities that belong to other tools.
