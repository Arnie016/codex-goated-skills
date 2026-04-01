# Trading Archive Bar

Trading Archive Bar is a native macOS menu bar app for browsing an archive of trading articles from RSS and Atom feeds without keeping a dozen finance tabs open.

## What It Includes

- SwiftUI `MenuBarExtra` app with a compact research popover
- RSS and Atom feed ingest with a saved archive cache
- search, favorites, and time-window filters for resurfacing older ideas fast
- one-click actions for refresh, copy reading queue, open article, and open feed settings
- a small settings window for feed URLs and archive depth

## Local Run

```bash
cd apps/trading-archive-bar
xcodegen generate
xcodebuild -project TradingArchiveBar.xcodeproj -scheme TradingArchiveBar -destination 'platform=macOS' test
```
