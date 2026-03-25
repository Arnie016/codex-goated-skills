# Supported Provider Paths

Use this reference when the request touches product shape, automation scope, or exact wording around what the app can do for Apple or Google device flows.

## Safe Default Framing

- "Find my phone" usually means a faster entry point into Apple Find My or Google Find surfaces.
- "Where exactly is it?" should be phrased as current or last known location unless the provider surface clearly offers nearby or precision guidance.
- "Ring it" is acceptable only when the user is trying to alert their own device or one they are authorized to manage.

## Preferred Integration Order

1. Open Find My or Google Find directly.
2. Use a local Shortcut or AppleScript helper when that route is clearly available and reliable.
3. Use a signed-in browser flow only when the user wants it and accepts browser automation tradeoffs.

## Product Notes

- A menu bar app is a good fit because the user intent is urgent and repeatable.
- Keep wording concrete: `Locate`, `Ring`, `Open Provider`, `Directions`, `Copy Location`.
- If the app cannot retrieve data directly, it should still be useful as a launcher plus stateful helper.

## Precision Language

Prefer wording like:

- "Open the latest available location"
- "Show the phone in its provider app"
- "Ring the phone through the provider flow"
- "Hand off to directions"

Avoid wording like:

- "Track anyone's device"
- "Get exact live GPS coordinates" unless the platform surface explicitly exposes them
- "Silently ping a phone in the background"

## Browser Automation Notes

- Use the user's own browser profile or a clearly separate one.
- Do not scrape or store Apple ID or Google credentials in local config by default.
- Expect the flow to be more brittle than native app handoff.

## App Architecture Hints

- Small SwiftUI menu bar extra
- Optional service layer for shortcuts or shell helpers
- One status card for device state
- One action row for locate and ring
- One settings pane for integration mode and permissions
