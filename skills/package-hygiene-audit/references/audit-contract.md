# Package Hygiene Audit Contract

Use `scripts/package_hygiene_audit.py` when the task needs a deterministic check of a local release folder before shipping.

## Inputs

- `--release-dir PATH`: the main folder that holds the app bundle, archive files, or both
- `--notes-path PATH`: optional file or folder for release notes when they do not live inside the release folder
- `--screenshot-dir PATH`: optional screenshot folder when screenshots are stored elsewhere
- `--expect-app-name NAME`: optional product name that should appear in bundle or archive names
- `--minimum-screenshots N`: required screenshot count for the current packaging lane
- `--require-packaged-archive`: treat missing `.dmg`, `.zip`, `.pkg`, `.tar.gz`, or `.tgz` output as blocking

## Commands

- `doctor`: confirm the release folder exists and show the resolved notes and screenshot search roots
- `audit`: scan the local packaging inputs and emit `markdown`, `prompt`, or `json`

## What the audit checks

- app bundle presence
- packaged archive presence
- release notes presence
- screenshot count
- optional product-name match
- version-token hygiene in archive names
- whether notes or screenshots look older than the newest artifact

## Default output sections

- summary
- blocking issues
- warnings
- discovered artifacts
- next actions

## Guardrails

- This is a file-system audit, not a notarization or App Store Connect integration.
- It should only report what exists locally under the provided paths.
- Missing files should stay explicit. Do not infer that screenshots, notes, or archives exist when they do not.
