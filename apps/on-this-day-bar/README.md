# On This Day Bar

On This Day Bar is a native macOS menu bar app that turns the official Wikimedia On This Day feed into a compact daily ritual.

## What It Includes

- SwiftUI `MenuBarExtra` app with a native popover
- live Wikimedia fetch with cached fallback per day
- curated categories for `Selected`, `Events`, `Births`, `Deaths`, and `Holidays`
- one-click actions for `Today`, previous, next, random day, copy brief, and open lead article
- a small settings window for default category and story depth

## Local Run

```bash
cd apps/on-this-day-bar
xcodegen generate
xcodebuild -project OnThisDayBar.xcodeproj -scheme OnThisDayBar -destination 'platform=macOS' test
```
