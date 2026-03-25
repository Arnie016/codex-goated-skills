# Official Supported Paths

Use this reference before claiming a direct Xbox capability on macOS.

## Current Official Anchors

- Xbox on Mobile: Xbox documents cloud gaming at `xbox.com/play` and Remote Play at `xbox.com/remoteplay`, and notes that Remote Play can be started from `xbox.com/play` when the console has remote features enabled.
  Source: https://www.xbox.com/en-US/xbox-on-mobile/
- Xbox on Mobile also frames features such as library management, remote installs, and chat inside the Xbox mobile app experience on iOS and Android.
  Source: https://www.xbox.com/en-US/xbox-on-mobile/
- Apple documents pairing supported Xbox wireless controllers with Mac through Bluetooth settings.
  Source: https://support.apple.com/en-euro/111101

## Build Recommendations

### Good Mac Targets

- Browser launcher for `xbox.com/play`
- Menu bar helper that opens cloud gaming, Remote Play, account pages, support pages, and local capture folders
- Controller pairing or troubleshooting assistant for macOS
- Local capture organizer that works on exported or downloaded files
- Support workflow that gets the user to the official Xbox or Microsoft surface quickly

### Claims To Avoid

- A general public Xbox console-control API for macOS
- Silent console power control, install-queue control, or message access without official docs
- Direct capture-library automation against undocumented Microsoft endpoints
- Any credential handling flow that replaces Microsoft's own sign-in pages unless the user explicitly asks for that risk

## Practical Capability Matrix

| User goal | Preferred Mac surface | Notes |
| --- | --- | --- |
| Cloud gaming | `xbox.com/play` in browser | Check subscription, browser, and region requirements |
| Remote Play | `xbox.com/play` Remote Play entry | Console must have remote features enabled |
| Pair controller | macOS Bluetooth settings | Use Apple pairing steps and Microsoft firmware guidance |
| Manage captures | Local folder helper plus official share surface | Safe to automate after export or download |
| Account or billing | `account.microsoft.com`, `account.xbox.com`, or `xbox.com` | Keep auth in browser |

## Suggested Menu Actions

- Open Cloud Gaming
- Open Remote Play
- Pair Controller
- Open Xbox Account
- Open Captures Folder
- Open Support
