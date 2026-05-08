## Task Spec: Codex Limit Monitor Clarity Pass

- Scope: improve the Codex limit monitor presentation layer so the primary number always reads as an explicit bucket state instead of an unexplained percentage.
- Problem: the current popover leads with a large percent and a nested ring, but it does not establish enough hierarchy between the 5-hour bucket, the weekly bucket, and the number shown in the menu bar. The result is that values like `81` feel visually disconnected and confusing.
- Change:
  - make the top of the popover explicitly say which bucket is currently driving the menu bar number
  - move the interactive sliders closer to the top so the two limit buckets feel like the main controls, not a buried editor
  - improve iconography and card structure for the 5-hour bucket, weekly bucket, and current menu-bar output
  - preserve the existing data model and the useful “highest used bucket wins” relationship
- Validation:
  - build Codex Limit Monitor from source after the UI pass
