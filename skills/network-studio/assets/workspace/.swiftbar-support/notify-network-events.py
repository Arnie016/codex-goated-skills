#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


MAX_NOTIFICATIONS = 3
MAX_TRACKED_EVENTS = 200


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text())
    except Exception:
        return {}


def notify(title: str, body: str) -> None:
    script = f'display notification "{body.replace(chr(34), chr(39))}" with title "{title.replace(chr(34), chr(39))}"'
    try:
        subprocess.run(["osascript", "-e", script], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: notify-network-events.py device-state.json alert-state.json", file=sys.stderr)
        return 1

    state_path = Path(sys.argv[1])
    alert_path = Path(sys.argv[2])
    if not state_path.exists():
        return 0

    state = load_json(state_path)
    alert_state = load_json(alert_path)
    sent = set(alert_state.get("sent_events", []))
    devices = {device["id"]: device for device in state.get("devices", [])}
    latest_scan = str(state.get("latest_scan", ""))
    eligible_changes = [
        change for change in state.get("changes", [])
        if str(change.get("timestamp", "")) == latest_scan
    ]

    if not sent and not alert_path.exists():
        seeded = [f"{change['timestamp']}|{change['type']}|{change['mac']}" for change in eligible_changes][-MAX_TRACKED_EVENTS:]
        alert_path.write_text(json.dumps({"sent_events": seeded}, indent=2) + "\n")
        return 0

    notifications = 0
    new_sent: list[str] = []

    for change in eligible_changes:
      event_id = f"{change['timestamp']}|{change['type']}|{change['mac']}"
      if event_id in sent:
          continue

      device = devices.get(change["mac"])
      is_unknown = bool(device and not device.get("known", True))
      is_key = bool(device and device.get("kind") in {"local", "router"})
      title = ""
      body = ""

      if change["type"] in {"joined", "returned"} and is_unknown:
          title = "Unknown device detected"
          body = f"{change['display_name']} at {change['ip']}"
      elif change["type"] == "missing" and is_key:
          title = "Key device missing"
          body = f"{change['display_name']} was not seen on the latest scan"

      if not title:
          continue

      notify(title, body)
      new_sent.append(event_id)
      notifications += 1
      if notifications >= MAX_NOTIFICATIONS:
          break

    sent.update(new_sent)
    trimmed = list(sorted(sent))[-MAX_TRACKED_EVENTS:]
    alert_path.write_text(json.dumps({"sent_events": trimmed}, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
