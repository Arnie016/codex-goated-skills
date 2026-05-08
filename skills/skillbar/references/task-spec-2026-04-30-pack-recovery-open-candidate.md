# Task Spec: Pack Recovery Open Candidate

## Goal

Make pack recovery as direct as setup recovery by letting users open the detected repo clone from the pack recovery card before switching SkillBar to it.

## Why

- The Quick Setup surface already exposes both `Open` and `Reveal` for detected repo candidates.
- The pack recovery card currently exposes only `Use Detected Repo` and `Reveal`, which makes pack troubleshooting less direct from the surface that discovered the problem.
- This is a compact UX parity fix that does not change install, update, or repo-selection semantics.

## Scope

- Add a model method for opening the pack-recovery repo candidate in Finder.
- Surface a new `Open Candidate` or `Open Repo` button in the pack recovery card, reusing existing label logic.
- Add focused unit coverage for the label copy so the pack recovery wording stays aligned with current-vs-candidate state.

## Non-Goals

- No pack metadata changes.
- No install/update flow changes.
- No broad setup redesign.
