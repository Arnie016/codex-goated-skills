# Diagnostic Order

Use this order to keep debugging focused.

## 1. Confirm The Workspace

- are we in the expected directory
- what project markers exist
- is this actually a repo or just a folder dump

## 2. Confirm The Toolchain

- required language or framework tools exist
- versions are at least plausible
- the user is not blocked by a missing core CLI

## 3. Confirm Project Entry Points

- install command
- build command
- test command
- doctor or setup script if present
- generated catalog freshness when the workspace ships skills and packs
- repo-native runner script if the workspace already has one
- for `project.yml` app workspaces, confirm whether XcodeGen and Xcode are actually ready before assuming the app is broken

## 4. Confirm Secrets Or Auth

- env vars
- login state
- machine-specific access blockers

## 5. Confirm Real Code Failure

Only after the environment looks healthy should you assume the code itself is the issue.
