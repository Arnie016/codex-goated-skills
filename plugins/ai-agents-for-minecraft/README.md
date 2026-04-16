# AI Agents for Minecraft

Local Codex plugin scaffold for working on AI-powered Minecraft Paper servers and helping players use them once they are in-game.

Version: `0.2.0`

Included:

- a Codex plugin manifest
- a Minecraft Studio skill for Paper server + AI builder workflows
- built-in guidance for WorldEdit, AI builder, claim/admin, and command-error recovery
- a server detection script
- a simple Paper server start helper

This plugin is meant to do two jobs:

- operate the Paper server stack
- act like an in-game guide that explains command errors, suggests safe commands to try next, and helps players learn tools like WorldEdit and the Acacia AI builder

Suggested local usage:

```bash
cd /Users/arnav/Desktop/codex-goated-skills
./plugins/ai-agents-for-minecraft/install-local-plugin.sh
./plugins/ai-agents-for-minecraft/scripts/detect_minecraft_server.sh "$HOME"
./plugins/ai-agents-for-minecraft/scripts/start_paper_server.sh /path/to/server
```

The installer script links the plugin into `~/.agents/plugins/plugins` and mirrors it into
`~/.codex/plugins/cache/arnav-local` so it shows up with Arnav's other local plugins.

GitHub source:

- [plugins/ai-agents-for-minecraft](https://github.com/Arnie016/codex-goated-skills/tree/main/plugins/ai-agents-for-minecraft)
