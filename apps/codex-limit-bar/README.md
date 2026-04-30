# CodexLimitBar

A small macOS menu bar app for tracking the Codex rate-limit percentages shown in the Codex app.

The menu item shows only the highest used percentage across the Codex buckets.
The badge color is blue for healthy, amber for watch, and red for tight.

It starts with the values from the screenshot, converted from remaining to used:

- 5-hour window: 21% used, refreshes in 04:42
- Weekly: 13% used, refreshes 5 May

On launch, the app asks the Codex app-server for live account rate limits and refreshes every 60 seconds. The refresh button in the popover also runs the same live update.

The dropdown shows:

- Used so far
- The relationship between the 5-hour and weekly buckets
- Which bucket is currently limiting Codex
- Remaining, used, and reset timing for each bucket
- Manual controls and paste parsing

## Build

```sh
./scripts/build-app.sh
```

The packaged app is created at:

```text
build/CodexLimitBar.app
```

## Run

```sh
open build/CodexLimitBar.app
```

The app uses `UserDefaults`, so edits persist across launches.
