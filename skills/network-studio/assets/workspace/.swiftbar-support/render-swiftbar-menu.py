#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path


MAX_SECTION_DEVICES = 8


def parse_iso(value: str) -> datetime | None:
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None


def human_age(value: str) -> str:
    dt = parse_iso(value)
    if not dt:
        return "unknown"
    seconds = int((datetime.now(timezone.utc).astimezone() - dt).total_seconds())
    if seconds < 60:
        return f"{seconds}s"
    if seconds < 3600:
        return f"{seconds // 60}m"
    return f"{seconds // 3600}h {(seconds % 3600) // 60}m"


def color_for_state(stats: dict[str, int], generated_at: str) -> tuple[str, str]:
    age = human_age(generated_at)
    age_dt = parse_iso(generated_at)
    stale = False
    if age_dt:
        stale = (datetime.now(timezone.utc).astimezone() - age_dt).total_seconds() > 180
    if stale:
        return "#e8a64f", "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
    if stats.get("unknown", 0) or stats.get("new", 0):
        return "#ffd166", "dot.radiowaves.left.and.right"
    if stats.get("visible", 0) == 0:
        return "#ff7d7d", "wifi.slash"
    return "#4fd17c", "dot.radiowaves.left.and.right"


def line(value: str) -> None:
    print(value)


def open_href(path_or_uri: str) -> str:
    return path_or_uri if path_or_uri.startswith("file://") else Path(path_or_uri).as_uri()

def render_device(device: dict, indent: int = 2) -> None:
    script_dir = Path(__file__).resolve().parent
    copy_script = script_dir / "copy-value.sh"
    prefix = "-" * indent
    line(f"{prefix}{device['display_name']} | sfimage={'wifi.router' if device['kind'] == 'router' else 'laptopcomputer' if device['kind'] == 'local' else 'desktopcomputer'}")
    line(f"{prefix}-IP: {device['ip']} | bash='{copy_script}' param1='{device['ip']}' terminal=false refresh=false")
    line(f"{prefix}-Family: {device.get('family_label') or 'Client'}")
    line(f"{prefix}-Vendor: {device.get('vendor_label') or device.get('vendor') or 'Unknown vendor'}")
    line(f"{prefix}-Status: {device['status_label']}")
    watch = device.get("watch_reasons") or []
    line(f"{prefix}-Watchlist: {', '.join(watch) if watch else 'Quiet'}")
    line(f"{prefix}-Open In Network Studio | href='{device['dashboard_link']}'")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: render-swiftbar-menu.py device-state.json", file=sys.stderr)
        return 1

    state_path = Path(sys.argv[1])
    if not state_path.exists():
        line("| color=#e8a64f sfimage=dot.radiowaves.left.and.right")
        line("---")
        line("Network Studio | color=#e8a64f")
        line("Waiting for the first build.")
        return 0

    state = json.loads(state_path.read_text())
    script_dir = Path(__file__).resolve().parent
    open_studio = script_dir / "open-network-studio.sh"
    rescan = script_dir / "manual-rescan.sh"
    stats = state.get("stats", {})
    color, icon = color_for_state(stats, state.get("generated_at", ""))
    line(f"| color={color} sfimage={icon}")
    line("---")

    line("At A Glance | color=#7f95ab")
    line(f"--Visible devices: {stats.get('visible', 0)}")
    line(f"--Watchlist: {stats.get('watch', 0)}")
    line(f"--Unknown devices: {stats.get('unknown', 0)}")
    line(f"--Updated: {human_age(state.get('generated_at', ''))} ago")
    network = state.get("network", {})
    if network.get("local_ip"):
        line(f"--This Mac: {network['local_ip']}")
    if network.get("gateway_ip"):
        line(f"--Router: {network['gateway_ip']}")
    line("---")

    line("Launchpad | color=#7f95ab")
    line(f"--Open Network Studio | bash='{open_studio}' terminal=false refresh=false")
    line(f"--Run Fresh Scan | bash='{rescan}' terminal=false refresh=true")
    line(f"--Edit Friendly Names | bash='/usr/bin/open' param1='{state['paths']['labels']}' terminal=false refresh=false")
    line(f"--Open Logs | bash='/usr/bin/open' param1='{state['paths']['logs_dir']}' terminal=false refresh=false")
    line("---")

    devices = state.get("devices", [])
    key_devices = [device for device in devices if device.get("group") == "key"]
    known_devices = [device for device in devices if device.get("group") == "known"]
    unknown_devices = [device for device in devices if device.get("group") == "unknown"]
    changes = state.get("changes", [])
    watch_cards = state.get("watchlist", {}).get("cards", [])

    line("Watchlist | color=#7f95ab")
    for device in key_devices[:2]:
        render_device(device, indent=2)
    for card in watch_cards:
        line(f"--{card['title']}: {card['count']}")
    for device in [device for device in devices if device.get("status") == "new"][:4]:
        line(f"---{device['display_name']} | href='{device['dashboard_link']}'")
    for device in unknown_devices[:4]:
        line(f"---{device['display_name']} | href='{device['dashboard_link']}'")
    line("---")

    line(f"Trusted Devices ({len(known_devices)}) | sfimage=checkmark.shield color=#7f95ab")
    for device in known_devices[:MAX_SECTION_DEVICES]:
        render_device(device, indent=2)
    if len(known_devices) > MAX_SECTION_DEVICES:
        line(f"--See {len(known_devices) - MAX_SECTION_DEVICES} more in Network Studio | href='{state['paths']['dashboard_uri']}'")
    line("---")

    line(f"Needs Review ({len(unknown_devices)}) | sfimage=questionmark.circle color=#7f95ab")
    for device in unknown_devices[:MAX_SECTION_DEVICES]:
        render_device(device, indent=2)
    if len(unknown_devices) > MAX_SECTION_DEVICES:
        line(f"--See {len(unknown_devices) - MAX_SECTION_DEVICES} more in Network Studio | href='{state['paths']['dashboard_uri']}'")
    line("---")

    line(f"Change Feed ({len(changes)}) | sfimage=timeline.selection color=#7f95ab")
    if not changes:
        line("--No changes captured yet.")
    for change in changes[:8]:
        line(f"--{change['type'].title()}: {change['display_name']} | href='{change['dashboard_link']}'")
        line(f"---{change['ip']} at {change['when']}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
