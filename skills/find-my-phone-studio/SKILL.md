---
name: find-my-phone-studio
description: Build, scaffold, troubleshoot, or product-shape a macOS menu bar app or helper workflow for finding a phone, opening its current location, and triggering a ring through Apple- or Google-supported surfaces. Use when Codex needs to turn "find my phone" into a realistic Mac utility, shortcut flow, browser flow, or automation for iPhone or Android without inventing unsupported tracking APIs.
---

# Find My Phone Studio

Use this skill when the user wants a Mac app, menu bar icon, or helper flow to locate their phone and ring it.

Default product shape: an always-available macOS menu bar utility that helps the user jump into the best available Apple or Google action quickly.

## Quick Start

1. Choose the lane: `menu-bar-app`, `shortcut-helper`, `browser-helper`, or `support-only`.
2. Run `python3 scripts/find_my_phone_brief.py --goal "<user request>"` to normalize the request.
3. Default to a menu bar extra with these actions:
   - `Locate Phone`
   - `Ring Phone`
   - `Open Provider`
   - `Copy last known location`
   - `Quit`
4. Be explicit about capability boundaries:
   - do not promise a public Find My control API unless the current Apple docs prove one exists
   - do not claim "exact" coordinates beyond what Apple's own surface provides
   - keep Apple ID credentials in Apple-owned surfaces when possible
5. If a real app scaffold is requested, prefer a lightweight SwiftUI menu bar app first and add richer views only if the user asks.

## Workflow

### Choose The Lane

- `menu-bar-app`: build a persistent Mac menu bar app that opens supported Apple or Google surfaces, runs approved local helpers, and keeps "find" actions one click away.
- `shortcut-helper`: use Shortcuts or AppleScript glue when the user wants quick local automation and is comfortable with Apple-managed prompts or permissions.
- `browser-helper`: use browser automation only when the user explicitly wants the iCloud web flow and accepts sign-in in their own browser session.
- `support-only`: explain the most reliable user path without building a local app.

### Build The Brief

Run the brief script first. Useful commands:

```bash
python3 scripts/find_my_phone_brief.py --goal "make a Mac menu bar app to find and ring my iPhone"
python3 scripts/find_my_phone_brief.py --goal "open my phone's location fast from the menu bar" --surface menu-bar-app --device iPhone
python3 scripts/find_my_phone_brief.py --goal "ring my phone from icloud web" --surface browser-helper --action ring
```

The brief should capture:

- device type and likely Apple surface
- primary action: `locate`, `ring`, `directions`, or `nearby`
- requested shell: menu bar app, popover, settings window, or no app shell
- trust boundary for sign-in and automation
- fallback path if the preferred action is not scriptable

### Capability Boundaries

- Treat Apple and Google apps, system services, and signed-in browser flows as the source of truth.
- Do not invent a general third-party Find My or Google Find API for arbitrary phone control.
- If the user says "exactly where it is," translate that into:
  - current or last known map location when available
  - directions handoff
  - nearby or precision-style guidance only if Apple's surface explicitly provides it on that device
- If ringing requires interaction in an Apple-owned UI, say so and build the helper around getting there faster.

### Menu Bar App Guidance

- Prefer `MenuBarExtra` or an accessory app with an `NSStatusItem`.
- Keep the main surface action-oriented:
  - latest device status
  - open location
  - ring device
  - hand off to directions
- Prefer a small popover for status and a settings window for account, automation, and fallback options.
- Treat launch-at-login as optional.
- Always include a clear quit path in the UI.
- Show the current integration mode clearly:
  - Apple app handoff
  - Google web handoff
  - Shortcuts helper
  - signed-in browser helper

### Security And Privacy

- Keep Apple ID and Google credentials out of custom storage unless the user explicitly requests and accepts that risk.
- Prefer opening the Find My app, Google Find web flow, or the user's signed-in browser session instead of asking Codex to handle secrets.
- If automation touches browser state, use a profile the user controls and explain what is persisted.
- Never present stalking or covert-tracking behavior as acceptable. This skill is only for the user's own devices or devices they are authorized to manage.

### Implementation Preferences

- Start with the smallest reliable flow that meets the request.
- Prefer:
  - deep links or app handoff
  - Shortcuts or AppleScript glue
  - browser automation last
- If browser control is needed, pair this skill with [$playwright](/Users/arnav/.codex/skills/playwright/SKILL.md).
- If the user wants a real macOS app scaffold in the local workspace, create a fresh menu bar target rather than overloading an unrelated existing app.

## Required Deliverables

- A short implementation brief with the chosen lane.
- Clear statement of what is and is not directly automatable.
- A concrete Mac surface:
  - menu bar app
  - shortcut
  - browser helper
  - support steps
- The fastest user path to:
  - see phone location
  - ring the phone
  - hand off to directions when possible

## Resources

- `scripts/find_my_phone_brief.py`: normalizes the user's request into an implementation brief.
- `references/apple-supported-paths.md`: guidance on supported surfaces, trust boundaries, and phrasing around location precision.
