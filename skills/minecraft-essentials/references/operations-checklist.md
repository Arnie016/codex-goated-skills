# Operations Checklist

Use this before upgrades, migrations, or exposing a local Minecraft server.

## Before Changing Anything

- back up the world
- back up launch scripts
- note current jar and version
- note Java version
- note current join info

## Before Upgrading Server Type

- confirm whether the world version is compatible
- confirm whether plugins or mods must change too
- keep a rollback archive

## Before Public Exposure

- confirm whether this is LAN-only or internet-facing
- explain port forwarding or VPS requirements
- explain whitelist and moderation implications
- explain that a laptop or desktop may sleep or disconnect

## After Changes

- boot the server
- check logs for plugin load failures
- confirm local join
- confirm LAN join if relevant
- confirm backup still exists
