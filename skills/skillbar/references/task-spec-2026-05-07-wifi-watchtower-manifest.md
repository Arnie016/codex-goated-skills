# Task Spec: WiFi Watchtower Manifest

## Context

`wifi-watchtower` is a surfaced macOS Icon Bars skill with existing small and large SVG assets, OpenAI interface metadata, pack membership, and a native app workspace. Its generated catalog entry was still relying on fallback metadata and had an empty `system_symbol`, so SkillBar could not surface richer detail copy or a meaningful symbol fallback.

## Scope

- Add `skills/wifi-watchtower/manifest.json`.
- Preserve the existing skill boundary: native WiFi Watchtower app in `apps/wifi-watchtower`, not the portable Network Studio workspace or SwiftBar plugin.
- Rebuild and audit the generated catalog.

## Team Fit

- Primary team: macOS System And Device Utilities.
- Closest adjacent skill: `network-studio`.
- Material difference: `wifi-watchtower` owns the native MenuBarExtra trust-grade app and dashboard; `network-studio` owns the portable LAN monitor workspace and optional SwiftBar plugin.

## Validation

- Run `jq empty skills/wifi-watchtower/manifest.json`.
- Run the required catalog commands: `python scripts/build_skill_market_index.py`, `python scripts/skill_market_loop.py sync`, and `python scripts/skill_market_loop.py audit`.
- Run SkillBar metadata checks: `bash scripts/run_skillbar.sh catalog-check` and `bash scripts/run_skillbar.sh audit`.
