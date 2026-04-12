# Controller Symptom Matrix

## Contents

- Bluetooth off
- Bluetooth permission needed
- Bluetooth resetting or unknown
- No controller detected
- Non-Xbox controller detected
- Xbox controller connected
- Remote Play not ready

## Bluetooth Off

- Symptom: the Mac reports Bluetooth is off.
- App copy: `Bluetooth is off`
- Primary action: `Open Bluetooth Settings`
- Secondary actions:
  - `Open Apple Pairing Guide`
  - `Refresh Checks`
- Notes: do not imply the app can power Bluetooth on by itself.

## Bluetooth Permission Needed

- Symptom: macOS has not granted Bluetooth access to the app.
- App copy: `Bluetooth permission needed`
- Primary action: `Open Bluetooth Settings`
- Secondary actions:
  - `Open Apple Pairing Guide`
  - `Refresh Checks`
- Notes: explain that controller discovery inside the app depends on local permission.

## Bluetooth Resetting Or Unknown

- Symptom: the local Bluetooth stack is still settling or unreadable.
- App copy: `Checking Bluetooth`
- Primary action: `Refresh Checks`
- Secondary actions:
  - `Open Apple Pairing Guide`
  - `Open Xbox Controller Help`
- Notes: this is a temporary local-state issue, not an Xbox account issue.

## No Controller Detected

- Symptom: Bluetooth is ready but `GameController` sees no active controllers.
- App copy: `No controller detected`
- Primary action: `Open Bluetooth Settings`
- Secondary actions:
  - `Open Apple Pairing Guide`
  - `Open Xbox Controller Help`
- Notes: keep the guidance on pairing and local readiness, not unsupported console APIs.

## Non-Xbox Controller Detected

- Symptom: a game controller is connected, but it does not look like Xbox-family hardware.
- App copy: `A controller is connected, but it does not look like Xbox hardware`
- Primary action: `Open Apple Pairing Guide`
- Secondary actions:
  - `Open Bluetooth Settings`
  - `Open Xbox Controller Help`
- Notes: do not mark this as failure; frame it as a compatibility or hardware-family check.

## Xbox Controller Connected

- Symptom: an Xbox-family controller is visible through `GameController`.
- App copy: `Xbox controller connected`
- Primary action: `Refresh Checks`
- Secondary actions:
  - `Open Xbox Controller Help`
  - `Open Bluetooth Settings`
- Notes: this is the strongest state. Cloud Gaming and Remote Play buttons can stay visible as secondary next steps.

## Remote Play Not Ready

- Symptom: the user wants Remote Play but the surface is unavailable or not yet configured.
- App copy: `Remote Play may still need console setup`
- Primary action: `Open Remote Play`
- Secondary actions:
  - `Open Xbox Support`
  - `Open Cloud Gaming`
- Notes: explain that Remote Play depends on console-side remote-feature setup and a signed-in Microsoft session.
