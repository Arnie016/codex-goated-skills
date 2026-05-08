# ClipboardLinkBar

A local macOS menu bar app for recent clipboard links and text. It watches the pasteboard, keeps a short local history, and gives each item a compact context view.

Network research is explicit: the app only fetches a page title or metadata after you select a URL item and press Research.

## Build

```sh
./scripts/build-app.sh
```

The packaged app is created at:

```text
build/ClipboardLinkBar.app
```

## Run

```sh
open build/ClipboardLinkBar.app
```
