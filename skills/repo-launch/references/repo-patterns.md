# Repo Patterns

Use these patterns to decide how the repository should feel on first view.

## Single App Repo

Best when the repo mostly exists to run one app or tool.

Top-level README should include:

- one-sentence summary
- install or run command
- environment variables only if required
- screenshot or quick result if useful

## Skill Catalog Repo

Best when the repo contains multiple installable skills or utilities.

Top-level README should include:

- install-all command
- install-one-by-name command
- compact table of skills
- app or extras table only if needed

## Library Or SDK Repo

Best when the repo is meant to be imported into another project.

Top-level README should include:

- package manager install command
- short usage snippet
- supported environment or version note

## Template Repo

Best when users clone or use the repo as a starting point.

Top-level README should include:

- what gets scaffolded
- setup command
- where to customize names or secrets

## Avoid

- multiple competing install paths near the top
- README sections that repeat the same message in different words
- placeholder docs such as generic contribution files unless they are useful
