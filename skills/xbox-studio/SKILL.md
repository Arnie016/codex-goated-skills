---
name: xbox-studio
description: Build, scaffold, troubleshoot, or product-shape a macOS helper workflow for Xbox cloud gaming, Remote Play, controller pairing, captures, and account or console support using official Xbox, Microsoft, Apple, and browser-supported surfaces. Use when Codex needs to turn "control my Xbox stuff" into a realistic menu bar app, browser launcher, shortcut flow, or support workflow without inventing unsupported Xbox APIs.
---

# Xbox Studio

Use this skill when the user wants a Mac app, menu bar utility, launcher, or troubleshooting flow for Xbox tasks.

Default product shape: a lightweight macOS helper that opens the best supported Xbox or Microsoft surface quickly and makes controller setup, cloud gaming, Remote Play, or capture handling easier.

## Quick Start

1. Choose the lane: `menu-bar-app`, `browser-helper`, `controller-setup`, `capture-helper`, or `support-only`.
2. Run `python3 scripts/xbox_brief.py --goal "<user request>"` to normalize the request.
3. Default to a small helper with these actions:
   - `Open Cloud Gaming`
   - `Open Remote Play`
   - `Pair Controller`
   - `Open Xbox Account`
   - `Open Captures`
   - `Quit`
4. Be explicit about capability boundaries:
   - keep Microsoft sign-in inside Microsoft-owned browser or account surfaces
   - do not promise a public Xbox console control API unless current official docs prove one exists
   - on Mac, prefer browser launchers and controller-setup flows; Xbox pages that describe the Xbox mobile app target iOS or Android
5. If a real app scaffold is requested, prefer a lightweight SwiftUI menu bar app first and add richer views only if the user asks.

## Workflow

### Choose The Lane

- `menu-bar-app`: build a persistent Mac launcher that keeps Xbox actions one click away and hands off into official web or account surfaces.
- `browser-helper`: use the user's signed-in browser session to launch cloud gaming, Remote Play, account pages, or support flows.
- `controller-setup`: focus on Bluetooth pairing, firmware guidance, and input troubleshooting on macOS.
- `capture-helper`: organize user-exported or downloaded captures locally and deep link into the official share or account surfaces when needed.
- `support-only`: explain the fastest supported path without building a local helper.

### Build The Brief

Run the brief script first. Useful commands:

```bash
python3 scripts/xbox_brief.py --goal "make a Mac menu bar app to open Xbox cloud gaming and remote play fast"
python3 scripts/xbox_brief.py --goal "help me pair my Xbox controller to my Mac" --lane controller-setup --focus controller
python3 scripts/xbox_brief.py --goal "organize Xbox captures on my Mac and open the official share surface" --lane capture-helper --focus captures
```

The brief should capture:

- primary focus: `cloud-gaming`, `remote-play`, `controller`, `captures`, `account`, or `console-help`
- requested lane and default Mac shell
- required supported surfaces
- trust boundary for sign-in and automation
- fallback path if the preferred action is not directly scriptable

### Capability Boundaries

- Treat Xbox or Microsoft web surfaces, the Xbox console UI, and Apple Bluetooth settings as the source of truth.
- Prefer `xbox.com/play` for cloud gaming and browser-first Remote Play entry.
- When the official Xbox pages describe app-only features such as installs, library management, or chat, remember that those descriptions target the Xbox mobile app on iOS or Android.
- On Mac, build helpers around browser launch, account handoff, local file handling, and controller setup rather than reverse-engineering unsupported endpoints.
- Do not invent direct APIs for console power, install queues, captures, or messages.
- If an action requires a signed-in Microsoft session or console confirmation, say so and optimize time-to-action instead of pretending it is fully automatable.

### Menu Bar App Guidance

- Prefer `MenuBarExtra` or an accessory app with an `NSStatusItem`.
- Keep the main surface action-oriented:
  - open cloud gaming
  - open Remote Play
  - open Xbox account or subscriptions
  - pair or troubleshoot controller
  - open captures folder or official share surface
- Prefer a small popover for status and a settings window for console nicknames, saved links, and capture-folder preferences.
- Treat launch-at-login as optional.
- Always include a clear quit path in the UI.

### Controller Setup Guidance

- Use Apple's Bluetooth pairing flow for supported Xbox controllers on Mac.
- Keep controller firmware updates in Microsoft's documented surfaces.
- If the user asks for remapping, verify the exact supported tool path first rather than inventing a general-purpose Xbox remapping API on macOS.

### Cloud Gaming And Remote Play

- Cloud gaming is a browser-first lane. Use `xbox.com/play`.
- Remote Play can begin from `xbox.com/play` when the user switches to Remote Play and their console has remote features enabled.
- Check subscription, region, and browser constraints before promising availability.
- If browser automation is needed, pair this skill with [$playwright](/Users/arnav/.codex/skills/playwright/SKILL.md).

### Captures And Sharing

- Prefer user-owned local folders or exported media once files are on disk.
- Build helpers that watch, rename, sort, transcode, or surface capture files after export or download.
- For browsing or sharing flows that stay inside Microsoft-owned surfaces, launch or guide the user there instead of simulating a private API.

### Security And Privacy

- Keep Microsoft credentials out of custom storage unless the user explicitly requests that risk and understands the tradeoff.
- Prefer signed-in browser sessions and Microsoft-owned surfaces.
- Never frame account access, device control, or console management as appropriate for systems the user does not own or administer.

### Implementation Preferences

- Start with the smallest reliable flow that meets the request.
- Prefer:
  - browser launcher or deep link
  - menu bar wrapper
  - automation last
- If the user wants a real macOS app scaffold in the local workspace, create a fresh menu bar target rather than overloading an unrelated existing app.

## Required Deliverables

- A short implementation brief with the chosen lane.
- A clear statement of what is directly automatable versus what hands off into official Xbox or Microsoft surfaces.
- A concrete Mac surface:
  - menu bar app
  - browser helper
  - controller setup flow
  - capture helper
  - support steps
- The fastest user path to the actions they actually asked for.

## Resources

- `scripts/xbox_brief.py`: normalizes the user's request into a build brief.
- `references/official-supported-paths.md`: concise guardrails for what Xbox officially documents for browser, mobile, and controller flows, plus what to avoid claiming on macOS.
