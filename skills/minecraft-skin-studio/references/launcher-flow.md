# Launcher Flow

Use this when working with Minecraft Java custom skins on macOS.

## Local Launcher Path

The Java launcher stores custom skin entries at:

`~/Library/Application Support/minecraft/launcher_custom_skins.json`

If that file does not exist yet, it can be created.

## What This Enables

- Add a custom skin to the launcher's local skin library.
- Keep a preview image alongside the skin data.
- Avoid fragile click automation for the launcher UI.

## Practical Limits

- Registering a skin locally makes it available to the launcher, but the user may still need to select or activate it in the launcher UI.
- Prompt-based generation is best treated as draft quality unless the result is visually checked.
- macOS UI scripting needs Accessibility permission, so do not make that the default path.
