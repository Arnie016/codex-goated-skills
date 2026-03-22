# codex-goated-skills

OpenSkills for Codex: a growing collection of reusable OpenAI Codex skills and mini apps.

This repository is meant to stay simple:

- `skills/` contains installable Codex skills
- `apps/` contains larger shareable app projects over time
- each skill is self-contained and can be installed directly from GitHub

## Install A Skill

Inside Codex, run:

```text
$skill-installer install https://github.com/Arnie016/codex-goated-skills/tree/main/skills/network-studio
```

Then restart Codex.

## Available Skills

### `network-studio`

Install or update a macOS local network monitor with:

- a SwiftBar menu bar plugin
- a browser dashboard
- device watchlists
- trusted and unknown device sections
- change feeds for joins, returns, and missing devices

Direct install URL:

```text
https://github.com/Arnie016/codex-goated-skills/tree/main/skills/network-studio
```

Example prompt:

```text
Use $network-studio to install Network Studio in ~/Network Studio and wire SwiftBar at ~/SwiftBarPlugins.
```

## Manual Install

If someone wants to install manually without `$skill-installer`:

```bash
mkdir -p ~/.codex/skills
git clone https://github.com/Arnie016/codex-goated-skills.git
cp -R codex-goated-skills/skills/network-studio ~/.codex/skills/network-studio
```

Then restart Codex.

## Topics And Discovery

Recommended GitHub repo description:

`Open-source skills and mini apps for OpenAI Codex`

Recommended GitHub topics:

- `codex`
- `openai-codex`
- `codex-skills`
- `agent-skills`
- `ai-agents`
- `developer-tools`
- `automation`
- `swiftbar`
- `macos`

## License

This repository is licensed under MIT. Individual skills may also include their own `LICENSE.txt`.
