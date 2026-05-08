## SkillBar manifest decode guard

- Treat `skills/*/manifest.json` as the primary metadata source when present.
- Stop silently falling back to legacy metadata when a manifest exists but cannot be decoded.
- Surface a precise catalog error so manifest drift is visible in SkillBar and tests.
