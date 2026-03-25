# Flight Scout

Flight Scout is a macOS menu bar app for route watching, live fare signals, booking deeplinks, and travel-risk scoring.

## What It Includes

- compact menu bar popover with route filters for `All`, `Cheapest`, `Safest`, `Fastest`, and `Trending`
- board window for route details, saved picks, and structured risk breakdowns
- live public fare signal fetching with provider deeplinks
- official advisory, weather, and multi-source headline-based risk scoring
- source snapshot copied from the local `/Users/arnav/Desktop/sora` workspace

## Local Run

```bash
cd apps/flight-scout
xcodegen generate
xcodebuild -project FlightScout.xcodeproj -scheme FlightScout -destination 'platform=macOS' test
```
