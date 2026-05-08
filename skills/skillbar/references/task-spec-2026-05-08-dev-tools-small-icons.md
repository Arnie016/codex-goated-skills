# Task Spec: Developer tools small icon readability

## Scope

Replace text-heavy generated small-icon artwork for `branch-brief-bar` and `repo-ops-lens` with compact vector marks that remain legible in SkillBar rows, icon tiles, pack views, and fallback catalog surfaces.

## Product Reason

Both skills are owned by the SkillBar And Catalog Platform team and currently surface 512px icons containing full names, category labels, and "Generated Mac skill" captions. Those labels collapse into noise at menu-bar and catalog row sizes, making the two developer utilities look generic despite having useful, distinct workflows.

## Constraints

- Preserve existing skill IDs, manifests, pack membership, large preview artwork, and install/update behavior.
- Do not create a new skill or duplicate the nearby developer-tool workflows.
- Keep the icon pass local-first and metadata-only: no app source, signing files, generated release artifacts, or network behavior.
- Verify SVG validity, catalog freshness, repo audit, SkillBar typecheck, and install/update smoke paths after regeneration.
