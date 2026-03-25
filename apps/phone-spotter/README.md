# Phone Spotter

Phone Spotter is a macOS menu bar utility for helping you locate your phone with local pairing, saved clues, and quick provider handoff flows.

## What It Includes

- compact menu bar UI for pairing and locate actions
- local settings and pairing state
- realistic Apple or Google provider handoff patterns
- source snapshot copied from the local `/Users/arnav/Desktop/sora` workspace

## Local Run

```bash
cd apps/phone-spotter
xcodegen generate
xcodebuild -project PhoneSpotter.xcodeproj -scheme PhoneSpotter -destination 'platform=macOS' test
```
