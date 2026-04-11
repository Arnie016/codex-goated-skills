---
name: minecraft-studio
description: Install, launch, troubleshoot, and extend AI-powered Minecraft Paper servers, including the Acacia AI builder plugin, WorldEdit workflows, recurring build jobs, local server packaging, and in-game command guidance.
---

# Minecraft Studio

Use this skill when Codex needs to work on a local Minecraft Paper or Spigot server with AI building features, or when a player needs help understanding what commands to use in-game.

## What this skill is for

- Finding a local Paper server directory
- Launching or restarting a server safely
- Installing or updating `acacia-ai-builder.jar`
- Checking `plugin.yml`, `logs/latest.log`, and listening ports
- Working with WorldEdit, Geyser, Floodgate, ViaVersion, and similar Paper plugins
- Adding or debugging `/aiagent`, `/aiplan`, `/aibuild`, or recurring builder features
- Orienting players on command syntax, region selection, brushes, claims, and safe test commands
- Explaining why a command failed and what exact command to try next
- Packaging the Minecraft workflows as a Codex-friendly local plugin

## Default workflow

1. Detect candidate Paper server folders with [detect_minecraft_server.sh](../../scripts/detect_minecraft_server.sh).
2. Confirm the live server directory from `paper-*.jar`, `plugins/`, `world/`, and active Java listeners.
3. Build or copy the AI plugin jar into `<server>/plugins/`.
4. Restart the Paper service or launch script.
5. Verify:
   - `logs/latest.log`
   - `lsof -nP -iTCP:25565 -sTCP:LISTEN`
   - `lsof -nP -iUDP:19132`
   - plugin version from `plugin.yml`
6. Give the user in-game commands to test.
7. If the user is playing in-game, act as a command guide:
   - identify whether the message comes from WorldEdit, GriefPrevention, Essentials, Citizens, or the AI builder
   - explain the error in plain language
   - give 1-3 exact commands to try next
   - steer them toward safe commands before destructive ones

## In-Game Guide Workflow

When the user is actively experimenting on a server:

1. Read the error text or screenshot literally before assuming the cause.
2. Separate these cases clearly:
   - missing argument or bad syntax
   - no region selected
   - no claim exists
   - no NPC selected
   - AI builder planning/runtime failure
3. Reply with short, copyable commands first.
4. Prefer direct recovery steps such as `//pos1`, `//pos2`, `//set stone`, `/ignoreclaims`, `/aiplan ...`.
5. Warn before suggesting commands that can delete claims, overwrite regions, or affect all players.

## Good Command Packs To Offer

- WorldEdit basics:
  - `//wand`
  - `//pos1`
  - `//pos2`
  - `//set stone`
  - `//replace sand smooth_sandstone`
  - `//undo`
- AI builder basics:
  - `/aiplan futuristic observatory`
  - `/aiplan medieval tower`
  - `/aibuild confirm`
  - `/aibuild now small sandstone outpost`
- Claims/admin basics:
  - `/ignoreclaims`
  - `/claimslist <player>`
  - `/deleteclaim`
  - `/deleteallclaims <player>`

## What Not To Suggest Casually

- Global destructive commands without a warning
- Claim deletion commands when chat already says the block is unclaimed
- WorldEdit commands without a pattern argument
- Region-based edits before confirming the user has set `pos1` and `pos2`

## Useful checks

```bash
tail -n 120 logs/latest.log
lsof -nP -iTCP:25565 -sTCP:LISTEN
lsof -nP -iUDP:19132
unzip -p plugins/acacia-ai-builder.jar plugin.yml
```

## Notes

- Prefer the real live server folder over stale copies in iCloud or Desktop mirrors.
- If AI requests fail with 429 or 503, add retries or delayed mission rescheduling instead of treating them as permanent failures.
- For coordinate-sensitive building, prefer exact anchors or saved points over vague natural-language placement.
- When users share Minecraft screenshots, treat the visible chat text as the primary debugging signal.
- For new or confused players, prefer tiny command sequences over long explanations.
- When packaging a reusable Codex plugin, keep the server-side Paper plugin and the Codex-side local plugin clearly separated.
