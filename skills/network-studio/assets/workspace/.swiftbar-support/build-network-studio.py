#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import re
import socket
import subprocess
import sys
import urllib.error
import urllib.request
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path
from string import Template


MAX_VENDOR_LOOKUPS = 4
MAX_PORT_SCAN_TARGETS = 3
PING_TARGET_LIMIT = 24
PING_WORKERS = 8
PORT_CACHE_TTL_SECONDS = 2 * 60 * 60
PRESENCE_SAMPLE_LIMIT = 12


def now_iso() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")


def parse_iso(value: str) -> datetime:
    return datetime.fromisoformat(value)


def humanize_ts(ts: str | None) -> str:
    if not ts:
        return "Unknown"
    try:
        dt = parse_iso(ts)
    except ValueError:
        return ts
    return dt.strftime("%b %d, %H:%M")


def normalize_mac(value: str) -> str:
    if not value:
        return ""
    pieces = [piece.zfill(2) for piece in value.strip().split(":") if piece]
    if len(pieces) != 6:
        return value.strip().upper()
    return ":".join(piece.upper() for piece in pieces)


def absolute_path(path: Path) -> Path:
    expanded = path.expanduser()
    if expanded.is_absolute():
        return expanded.resolve()
    return (Path.cwd() / expanded).resolve()


def is_private_mac(mac: str) -> bool:
    if not mac or mac.count(":") != 5:
        return False
    try:
        return bool(int(mac.split(":")[0], 16) & 0x02)
    except ValueError:
        return False


def short_hostname(hostname: str) -> str:
    if not hostname:
        return ""
    return hostname.split(".")[0]


def compact_vendor_name(vendor: str) -> str:
    value = vendor.strip() or "Unknown vendor"
    replacements = {
        "Apple, Inc.": "Apple",
        "Microsoft Corporation": "Microsoft",
        "HUAWEI TECHNOLOGIES CO.,LTD": "Huawei",
        "Private / randomized": "Private client",
        "Unknown vendor": "Unknown vendor",
    }
    value = replacements.get(value, value)
    value = re.sub(r"\b(CO\.?,?\s*LTD|INC\.?|CORPORATION|TECHNOLOGIES|TECHNOLOGY)\b", "", value, flags=re.IGNORECASE)
    value = re.sub(r"\s+", " ", value).strip(" ,.-")
    return value[:36] if value else "Unknown vendor"


def shell_output(cmd: list[str]) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""


def detect_network() -> tuple[str, str, str]:
    iface = ""
    gateway_ip = ""

    route_output = shell_output(["route", "-n", "get", "default"])
    for line in route_output.splitlines():
        if "interface:" in line:
            iface = line.split("interface:", 1)[1].strip()
        elif "gateway:" in line:
            gateway_ip = line.split("gateway:", 1)[1].strip()

    local_ip = shell_output(["ipconfig", "getifaddr", iface]) if iface else ""
    return iface, local_ip, gateway_ip


def load_csv_rows(path: Path, has_header: bool = False) -> list[dict[str, str]]:
    if not path.exists():
        return []

    rows: list[dict[str, str]] = []
    with path.open(newline="") as handle:
        reader = csv.reader(handle)
        header_skipped = not has_header
        for row in reader:
            if not row:
                continue
            if not header_skipped:
                header_skipped = True
                if row and row[0] == "timestamp":
                    continue
            while len(row) < 5:
                row.append("")
            rows.append(
                {
                    "timestamp": row[0],
                    "ip": row[1],
                    "mac": normalize_mac(row[2]),
                    "iface": row[3],
                    "hostname": row[4],
                }
            )
    return rows


def load_previous_state(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text())
    except Exception:
        return {}


def ensure_labels_file(path: Path, local_mac: str, gateway_mac: str) -> dict:
    data: dict[str, object] = {"devices": {}}
    if path.exists():
        try:
            loaded = json.loads(path.read_text())
            if isinstance(loaded, dict) and isinstance(loaded.get("devices"), dict):
                data = loaded
        except Exception:
            pass

    devices = data.setdefault("devices", {})
    if not isinstance(devices, dict):
        devices = {}
        data["devices"] = devices

    changed = not path.exists()

    if local_mac and local_mac not in devices:
        devices[local_mac] = {
            "label": "This Mac",
            "trusted": True,
            "pinned": True,
            "notes": "Local workstation",
        }
        changed = True
    if gateway_mac and gateway_mac not in devices:
        devices[gateway_mac] = {
            "label": "Router",
            "trusted": True,
            "pinned": True,
            "notes": "LAN gateway",
        }
        changed = True

    if changed:
        path.write_text(json.dumps(data, indent=2) + "\n")
    return data


def load_vendor_cache(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    try:
        raw = json.loads(path.read_text())
        return {str(key): str(value) for key, value in raw.items()}
    except Exception:
        return {}


def save_vendor_cache(path: Path, cache: dict[str, str]) -> None:
    path.write_text(json.dumps(cache, indent=2, sort_keys=True) + "\n")


def fetch_vendor(prefix: str, mac: str) -> str:
    request = urllib.request.Request(
        f"https://api.macvendors.com/{mac}",
        headers={"User-Agent": "network-monitor-studio/1.0"},
    )
    try:
        with urllib.request.urlopen(request, timeout=0.8) as response:
            vendor = response.read().decode("utf-8", errors="replace").strip()
            return vendor[:80] if vendor else "Unknown vendor"
    except (urllib.error.URLError, TimeoutError, OSError):
        return "Unknown vendor"


def enrich_vendors(rows: list[dict[str, str]], cache: dict[str, str]) -> dict[str, str]:
    resolved: dict[str, str] = {}
    pending: list[tuple[str, str]] = []

    for row in rows:
        mac = row["mac"]
        if not mac:
            continue
        prefix = ":".join(mac.split(":")[:3])
        if is_private_mac(mac):
            resolved[mac] = "Private / randomized"
            continue
        if prefix in cache:
            resolved[mac] = cache[prefix]
            continue
        if prefix not in {item[0] for item in pending} and len(pending) < MAX_VENDOR_LOOKUPS:
            pending.append((prefix, mac))

    for prefix, mac in pending:
        cache[prefix] = fetch_vendor(prefix, mac)

    for row in rows:
        mac = row["mac"]
        if not mac:
            continue
        prefix = ":".join(mac.split(":")[:3])
        if mac in resolved:
            continue
        resolved[mac] = cache.get(prefix, "Unknown vendor")

    return resolved


def resolve_reverse_dns(ip: str, fallback: str) -> str:
    if fallback:
        return fallback
    try:
        socket.setdefaulttimeout(0.4)
        host, _, _ = socket.gethostbyaddr(ip)
        return host
    except Exception:
        return ""


def load_history_index(rows: list[dict[str, str]]) -> tuple[dict[str, dict[str, object]], list[tuple[str, dict[str, dict[str, str]]]]]:
    per_mac: dict[str, dict[str, object]] = defaultdict(
        lambda: {"timestamps": set(), "first_seen": "", "last_seen": "", "last_row": {}}
    )
    snapshots: dict[str, dict[str, dict[str, str]]] = {}

    for row in rows:
        mac = row["mac"] or normalize_mac(row["ip"])
        ts = row["timestamp"]
        if ts not in snapshots:
            snapshots[ts] = {}
        snapshots[ts][mac] = row

        info = per_mac[mac]
        info["timestamps"].add(ts)
        if not info["first_seen"] or ts < str(info["first_seen"]):
            info["first_seen"] = ts
        if not info["last_seen"] or ts > str(info["last_seen"]):
            info["last_seen"] = ts
        info["last_row"] = row

    ordered_snapshots = sorted(snapshots.items(), key=lambda item: item[0])
    return per_mac, ordered_snapshots


def build_timeline(ordered_snapshots: list[tuple[str, dict[str, dict[str, str]]]]) -> list[dict[str, str]]:
    timeline: list[dict[str, str]] = []
    seen_before: set[str] = set()
    previous: set[str] = set()

    for ts, snapshot in ordered_snapshots:
        current = set(snapshot)
        joined = current - previous
        missing = previous - current

        for mac in sorted(joined):
            event_type = "returned" if mac in seen_before else "joined"
            row = snapshot[mac]
            timeline.append(
                {
                    "timestamp": ts,
                    "type": event_type,
                    "mac": mac,
                    "ip": row["ip"],
                    "hostname": row["hostname"],
                }
            )

        for mac in sorted(missing):
            row = ordered_snapshots[ordered_snapshots.index((ts, snapshot)) - 1][1][mac]
            timeline.append(
                {
                    "timestamp": ts,
                    "type": "missing",
                    "mac": mac,
                    "ip": row["ip"],
                    "hostname": row["hostname"],
                }
            )

        seen_before |= current
        previous = current

    return timeline[-14:]


def build_presence_samples(
    ordered_snapshots: list[tuple[str, dict[str, dict[str, str]]]]
) -> dict[str, list[dict[str, object]]]:
    recent_snapshots = ordered_snapshots[-PRESENCE_SAMPLE_LIMIT:]
    if not recent_snapshots:
        return {}

    macs: set[str] = set()
    for _, snapshot in recent_snapshots:
        macs.update(snapshot.keys())

    samples: dict[str, list[dict[str, object]]] = {mac: [] for mac in macs}
    for ts, snapshot in recent_snapshots:
        present = set(snapshot.keys())
        for mac in macs:
            samples[mac].append({"timestamp": ts, "online": mac in present})
    return samples


def ping_latency(ip: str) -> float | None:
    try:
        completed = subprocess.run(
            ["ping", "-c", "1", "-W", "1000", ip],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
        )
    except Exception:
        return None

    match = re.search(r"time[=<]([\d.]+)\s*ms", completed.stdout)
    if not match:
        return None
    try:
        return round(float(match.group(1)), 2)
    except ValueError:
        return None


def collect_latencies(devices: list[dict[str, object]]) -> dict[str, float | None]:
    ordered = sorted(
        devices,
        key=lambda device: (
            0 if device["kind"] in {"local", "router"} else 1,
            0 if device["status"] in {"new", "returned"} else 1,
            0 if not device["known"] else 1,
            device["ip"],
        ),
    )
    targets = ordered[:PING_TARGET_LIMIT]
    latencies: dict[str, float | None] = {}

    with ThreadPoolExecutor(max_workers=PING_WORKERS) as pool:
        future_map = {pool.submit(ping_latency, str(device["ip"])): str(device["id"]) for device in targets}
        for future in as_completed(future_map):
            latencies[future_map[future]] = future.result()

    return latencies


def parse_ports(stdout: str) -> list[dict[str, object]]:
    ports: list[dict[str, object]] = []
    for line in stdout.splitlines():
        match = re.match(r"^(\d+)/(tcp|udp)\s+open\s+(\S+)", line.strip())
        if not match:
            continue
        ports.append(
            {
                "port": int(match.group(1)),
                "protocol": match.group(2),
                "service": match.group(3),
            }
        )
    return ports


def run_port_scan(ip: str) -> list[dict[str, object]]:
    if not shell_output(["sh", "-c", "command -v nmap"]):
        return []
    try:
        completed = subprocess.run(
            ["nmap", "-Pn", "--top-ports", "10", "--host-timeout", "1800ms", "-T4", ip],
            capture_output=True,
            text=True,
            timeout=6,
            check=False,
        )
    except Exception:
        return []
    return parse_ports(completed.stdout)


def device_uri(dashboard_path: Path, device_id: str) -> str:
    return f"{absolute_path(dashboard_path).as_uri()}#device={device_id}"


def build_display_name(kind: str, label: str, hostname: str, ip: str, vendor: str) -> str:
    if label:
        return label
    if kind == "local":
        return "This Mac"
    if kind == "router":
        return "Router"
    short = short_hostname(hostname)
    if short:
        return short
    vendor_hint = compact_vendor_name(vendor)
    if vendor_hint and vendor_hint not in {"Private client", "Unknown vendor"}:
        return f"{vendor_hint} .{ip.split('.')[-1]}"
    return f"Device .{ip.split('.')[-1]}"


def build_visibility(kind: str) -> str:
    if kind == "local":
        return "Full view of this Mac's own traffic, DNS, and ports."
    if kind == "router":
        return "Gateway device. Deeper client analytics usually live here."
    return "Presence, latency, hostname, and optional quick ports only from this Mac."


def infer_family(kind: str, label: str, hostname: str, vendor: str, notes: str) -> str:
    if kind == "local":
        return "Workstation"
    if kind == "router":
        return "Router / gateway"

    text = " ".join(part for part in [label, hostname, vendor, notes] if part).lower()
    if any(token in text for token in ["iphone", "ipad", "android", "pixel", "samsung", "xiaomi", "oppo", "phone", "tablet"]):
        return "Phone / tablet"
    if any(token in text for token in ["playstation", "ps5", "xbox", "switch", "nintendo", "steam deck", "console"]):
        return "Game console"
    if any(token in text for token in ["tv", "roku", "chromecast", "bravia", "appletv", "apple tv", "shield tv", "stream"]):
        return "TV / streaming"
    if any(token in text for token in ["printer", "epson", "canon", "brother", "hp print"]):
        return "Printer"
    if any(token in text for token in ["camera", "ring", "nest cam", "doorbell", "reolink", "hikvision"]):
        return "Camera / security"
    if any(token in text for token in ["ubiquiti", "tp-link", "asus", "netgear", "access point", "mesh", "satellite", "switch"]):
        return "Network gear"
    if any(token in text for token in ["apple", "microsoft", "lenovo", "dell", "acer", "asus", "macbook", "laptop", "desktop", "pc", "imac"]):
        return "Computer"
    if vendor == "Private / randomized":
        return "Private client"
    if vendor == "Unknown vendor":
        return "Unidentified client"
    return "General client"


def build_watch_reasons(device: dict[str, object]) -> list[str]:
    reasons: list[str] = []
    kind = str(device.get("kind", "client"))
    if not bool(device.get("known")):
        reasons.append("Needs review")
    if str(device.get("status")) in {"new", "returned"}:
        reasons.append("Recently changed")
    latency = device.get("latency_ms")
    if isinstance(latency, (int, float)) and latency >= 100:
        reasons.append("Slow reply")
    if kind not in {"local", "router"} and device.get("ports"):
        reasons.append("Open ports")
    return reasons


def build_html(state: dict, labels_path: Path, logs_dir: Path) -> str:
    state_json = json.dumps(state).replace("</", "<\\/")
    template = Template(
        """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Network Studio</title>
  <style>
    :root {
      --bg: #08131d;
      --panel: rgba(13, 29, 43, 0.86);
      --panel-strong: rgba(15, 35, 52, 0.96);
      --border: rgba(140, 174, 198, 0.16);
      --text: #ecf3fa;
      --muted: #8aa1b5;
      --accent: #4fd17c;
      --accent-2: #53b6ff;
      --warn: #ffcc6b;
      --danger: #ff7d7d;
      --shadow: 0 26px 50px rgba(0, 0, 0, 0.3);
      --radius: 24px;
    }

    * { box-sizing: border-box; }

    html, body {
      margin: 0;
      min-height: 100%;
      background:
        radial-gradient(circle at 15% 10%, rgba(83, 182, 255, 0.18), transparent 22%),
        radial-gradient(circle at 85% 12%, rgba(79, 209, 124, 0.14), transparent 18%),
        radial-gradient(circle at 52% 88%, rgba(130, 102, 255, 0.12), transparent 18%),
        linear-gradient(180deg, #06111a 0%, #07141e 45%, #08131d 100%);
      color: var(--text);
      font-family: ui-rounded, "SF Pro Rounded", "Avenir Next", -apple-system, BlinkMacSystemFont, sans-serif;
    }

    body {
      padding: 28px 20px 56px;
    }

    .shell {
      max-width: 1400px;
      margin: 0 auto;
      display: grid;
      gap: 18px;
    }

    .panel {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      backdrop-filter: blur(18px);
    }

    .hero {
      display: grid;
      grid-template-columns: 1.15fr 0.85fr;
      gap: 18px;
    }

    .hero-main {
      padding: 28px;
      position: relative;
      overflow: hidden;
    }

    .hero-main::after {
      content: "";
      position: absolute;
      inset: auto -50px -60px auto;
      width: 180px;
      height: 180px;
      border-radius: 50%;
      background: radial-gradient(circle, rgba(79, 209, 124, 0.18), transparent 65%);
      filter: blur(4px);
    }

    .eyebrow {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      padding: 8px 12px;
      border-radius: 999px;
      font-size: 12px;
      letter-spacing: 0.14em;
      text-transform: uppercase;
      background: rgba(79, 209, 124, 0.1);
      color: var(--accent);
      font-weight: 700;
    }

    .beacon {
      width: 10px;
      height: 10px;
      border-radius: 50%;
      background: var(--accent);
      box-shadow: 0 0 0 rgba(79, 209, 124, 0.6);
      animation: pulse 2s infinite;
    }

    @keyframes pulse {
      0% { box-shadow: 0 0 0 0 rgba(79, 209, 124, 0.5); }
      70% { box-shadow: 0 0 0 18px rgba(79, 209, 124, 0); }
      100% { box-shadow: 0 0 0 0 rgba(79, 209, 124, 0); }
    }

    h1 {
      margin: 18px 0 12px;
      font-size: clamp(36px, 5vw, 66px);
      line-height: 0.92;
      letter-spacing: -0.04em;
    }

    .sub {
      margin: 0;
      max-width: 58ch;
      color: var(--muted);
      font-size: 17px;
      line-height: 1.55;
    }

    .stats {
      margin-top: 24px;
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 14px;
    }

    .stat {
      background: var(--panel-strong);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 16px 18px;
      transform: translateY(12px);
      opacity: 0;
      animation: rise 0.6s ease forwards;
    }

    .stat:nth-child(2) { animation-delay: 0.06s; }
    .stat:nth-child(3) { animation-delay: 0.12s; }
    .stat:nth-child(4) { animation-delay: 0.18s; }

    @keyframes rise {
      from { transform: translateY(18px); opacity: 0; }
      to { transform: translateY(0); opacity: 1; }
    }

    .stat span {
      display: block;
      color: var(--muted);
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    .stat strong {
      display: block;
      margin-top: 10px;
      font-size: 30px;
      line-height: 1.05;
    }

    .hero-side {
      padding: 24px;
      display: grid;
      gap: 14px;
      align-content: start;
    }

    .side-block {
      background: var(--panel-strong);
      border: 1px solid var(--border);
      border-radius: 22px;
      padding: 18px;
    }

    .side-title {
      color: var(--muted);
      font-size: 12px;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      margin-bottom: 10px;
    }

    .side-value {
      font-size: 18px;
      line-height: 1.45;
      word-break: break-word;
    }

    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 18px;
    }

    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      padding: 11px 14px;
      border-radius: 999px;
      text-decoration: none;
      border: 1px solid var(--border);
      color: var(--text);
      background: rgba(255, 255, 255, 0.04);
      transition: transform 0.18s ease, border-color 0.18s ease, background 0.18s ease;
      font-size: 14px;
      cursor: pointer;
    }

    .btn:hover {
      transform: translateY(-1px);
      border-color: rgba(83, 182, 255, 0.4);
      background: rgba(83, 182, 255, 0.08);
    }

    .toolbar {
      padding: 18px 20px;
      display: grid;
      grid-template-columns: 1fr auto;
      gap: 14px;
      align-items: center;
    }

    .search {
      width: 100%;
      border: 1px solid var(--border);
      background: rgba(255, 255, 255, 0.04);
      color: var(--text);
      border-radius: 16px;
      padding: 14px 16px;
      font-size: 15px;
      outline: none;
    }

    .chip-row {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      justify-content: flex-end;
    }

    .chip {
      border-radius: 999px;
      border: 1px solid var(--border);
      padding: 10px 13px;
      background: rgba(255, 255, 255, 0.04);
      color: var(--muted);
      font-size: 13px;
      cursor: pointer;
      transition: background 0.18s ease, color 0.18s ease, border-color 0.18s ease;
    }

    .chip.active {
      background: rgba(83, 182, 255, 0.1);
      color: var(--text);
      border-color: rgba(83, 182, 255, 0.35);
    }

    .watch-board {
      padding: 22px;
    }

    .watch-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 14px;
    }

    .watch-card {
      border: 1px solid var(--border);
      border-radius: 22px;
      background: var(--panel-strong);
      padding: 18px;
      display: grid;
      gap: 10px;
      cursor: pointer;
      transition: transform 0.18s ease, border-color 0.18s ease, background 0.18s ease;
    }

    .watch-card:hover, .watch-card.is-active {
      transform: translateY(-2px);
      border-color: rgba(79, 209, 124, 0.34);
      background: rgba(17, 39, 58, 0.95);
    }

    .watch-card.is-empty {
      opacity: 0.72;
    }

    .watch-count {
      font-size: 32px;
      line-height: 1;
      font-weight: 800;
      letter-spacing: -0.04em;
    }

    .watch-title {
      font-size: 15px;
      font-weight: 700;
    }

    .watch-detail {
      color: var(--muted);
      font-size: 13px;
      line-height: 1.45;
    }

    .pulse-board {
      padding: 22px;
    }

    .pulse-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 14px;
    }

    .pulse-card {
      border: 1px solid var(--border);
      border-radius: 22px;
      background: var(--panel-strong);
      padding: 18px;
      display: grid;
      gap: 10px;
    }

    .pulse-label {
      color: var(--muted);
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    .pulse-value {
      font-size: 26px;
      line-height: 1.05;
      font-weight: 800;
      letter-spacing: -0.03em;
      overflow-wrap: anywhere;
    }

    .pulse-meta {
      color: var(--muted);
      font-size: 13px;
      line-height: 1.5;
    }

    .pulse-inline {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      flex-wrap: wrap;
    }

    .mini-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      border-radius: 999px;
      border: 1px solid var(--border);
      background: rgba(255, 255, 255, 0.04);
      color: var(--text);
      padding: 8px 11px;
      cursor: pointer;
      font-size: 12px;
      transition: background 0.18s ease, border-color 0.18s ease;
    }

    .mini-btn:hover {
      background: rgba(83, 182, 255, 0.08);
      border-color: rgba(83, 182, 255, 0.35);
    }

    .stack-list {
      display: grid;
      gap: 12px;
    }

    .stack-row {
      display: grid;
      gap: 8px;
    }

    .stack-label {
      color: var(--muted);
      font-size: 12px;
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }

    .stack-chip-row {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .stack-chip {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 7px 10px;
      border-radius: 999px;
      border: 1px solid var(--border);
      background: rgba(255, 255, 255, 0.04);
      color: var(--text);
      font-size: 12px;
    }

    .studio-grid {
      display: grid;
      grid-template-columns: 1.25fr 0.75fr;
      gap: 18px;
    }

    .topology {
      padding: 22px;
      overflow: hidden;
    }

    .section-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      margin-bottom: 12px;
    }

    .section-head h2 {
      margin: 0;
      font-size: 22px;
    }

    .section-head p {
      margin: 0;
      color: var(--muted);
      font-size: 14px;
    }

    .topology-canvas {
      position: relative;
      min-height: 440px;
      border-radius: 24px;
      background:
        radial-gradient(circle at center, rgba(79, 209, 124, 0.08), transparent 22%),
        radial-gradient(circle at center, rgba(83, 182, 255, 0.08), transparent 44%),
        linear-gradient(180deg, rgba(6, 17, 26, 0.92), rgba(9, 21, 33, 0.96));
      border: 1px solid var(--border);
      overflow: hidden;
    }

    .ring, .flow-ring {
      position: absolute;
      inset: 50%;
      border-radius: 50%;
      border: 1px dashed rgba(138, 161, 181, 0.14);
      transform: translate(-50%, -50%);
      pointer-events: none;
    }

    .ring.outer { width: 78%; height: 78%; }
    .ring.inner { width: 54%; height: 54%; }
    .flow-ring {
      width: 32%;
      height: 32%;
      border-style: solid;
      border-color: rgba(79, 209, 124, 0.16);
      animation: breathe 6s ease-in-out infinite;
    }

    @keyframes breathe {
      0%, 100% { transform: translate(-50%, -50%) scale(0.97); }
      50% { transform: translate(-50%, -50%) scale(1.04); }
    }

    .topology-svg {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
    }

    .topology-svg line {
      stroke: rgba(83, 182, 255, 0.22);
      stroke-width: 1.5;
      stroke-dasharray: 8 8;
      animation: dash 16s linear infinite;
    }

    .topology-svg line.is-selected {
      stroke: rgba(79, 209, 124, 0.95);
      stroke-width: 2.6;
    }

    @keyframes dash {
      from { stroke-dashoffset: 0; }
      to { stroke-dashoffset: -160; }
    }

    .node {
      position: absolute;
      min-width: 110px;
      transform: translate(-50%, -50%);
      padding: 12px 14px;
      border-radius: 18px;
      background: rgba(8, 20, 31, 0.88);
      border: 1px solid rgba(138, 161, 181, 0.16);
      box-shadow: var(--shadow);
      backdrop-filter: blur(14px);
      transition: transform 0.18s ease, border-color 0.18s ease, box-shadow 0.18s ease;
      cursor: pointer;
    }

    .node:hover, .node.is-selected {
      transform: translate(-50%, -50%) scale(1.04);
      border-color: rgba(79, 209, 124, 0.45);
      box-shadow: 0 18px 34px rgba(0, 0, 0, 0.32);
    }

    .node .name {
      font-weight: 700;
      font-size: 14px;
      margin-bottom: 4px;
    }

    .node .meta {
      color: var(--muted);
      font-size: 12px;
    }

    .node.key {
      background: rgba(10, 26, 40, 0.95);
    }

    .node.unknown {
      border-color: rgba(255, 204, 107, 0.28);
    }

    .spotlight {
      padding: 22px;
    }

    .spotlight-track {
      display: grid;
      grid-auto-flow: column;
      grid-auto-columns: minmax(260px, 320px);
      gap: 14px;
      overflow-x: auto;
      padding-bottom: 4px;
      scroll-snap-type: x proximity;
    }

    .spotlight-card {
      scroll-snap-align: start;
      background: var(--panel-strong);
      border: 1px solid var(--border);
      border-radius: 22px;
      padding: 18px;
      min-height: 180px;
      display: grid;
      align-content: start;
      gap: 10px;
      transition: transform 0.18s ease, border-color 0.18s ease;
      cursor: pointer;
    }

    .spotlight-card:hover, .spotlight-card.is-selected {
      transform: translateY(-3px);
      border-color: rgba(83, 182, 255, 0.38);
    }

    .label-row {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 7px 10px;
      border-radius: 999px;
      border: 1px solid var(--border);
      background: rgba(255, 255, 255, 0.04);
      color: var(--muted);
      font-size: 12px;
    }

    .flow-grid, .change-grid, .device-sections {
      display: grid;
      gap: 18px;
    }

    .flow-grid {
      grid-template-columns: repeat(3, minmax(0, 1fr));
    }

    .flow-card, .change-card, .detail-card {
      padding: 22px;
    }

    .flow-card .icon {
      width: 42px;
      height: 42px;
      border-radius: 14px;
      display: grid;
      place-items: center;
      margin-bottom: 14px;
      background: rgba(83, 182, 255, 0.12);
      color: var(--accent-2);
      font-weight: 700;
    }

    .flow-card p, .change-card p, .detail-card p {
      color: var(--muted);
      line-height: 1.55;
      margin-bottom: 0;
    }

    .change-grid {
      grid-template-columns: 1fr 1fr;
    }

    .timeline {
      display: grid;
      gap: 12px;
      margin-top: 16px;
    }

    .timeline-row {
      display: grid;
      grid-template-columns: auto 1fr auto;
      gap: 12px;
      align-items: center;
      padding: 12px 14px;
      border-radius: 16px;
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(138, 161, 181, 0.08);
    }

    .badge {
      border-radius: 999px;
      padding: 6px 9px;
      font-size: 11px;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      border: 1px solid var(--border);
      background: rgba(255, 255, 255, 0.05);
      color: var(--muted);
    }

    .badge.joined { color: var(--accent); border-color: rgba(79, 209, 124, 0.25); }
    .badge.returned { color: var(--accent-2); border-color: rgba(83, 182, 255, 0.25); }
    .badge.missing { color: var(--warn); border-color: rgba(255, 204, 107, 0.25); }

    .detail-grid {
      display: grid;
      grid-template-columns: 1.15fr 0.85fr;
      gap: 18px;
    }

    .section-stack {
      display: grid;
      gap: 18px;
    }

    .device-section {
      padding: 22px;
    }

    .device-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
      gap: 14px;
      margin-top: 18px;
    }

    .device-card {
      position: relative;
      padding: 18px;
      border-radius: 22px;
      background: var(--panel-strong);
      border: 1px solid var(--border);
      transition: transform 0.18s ease, border-color 0.18s ease, background 0.18s ease;
      cursor: pointer;
      transform: translateY(18px);
      opacity: 0;
      animation: rise 0.55s ease forwards;
    }

    .device-card:hover, .device-card.is-selected {
      transform: translateY(-2px);
      border-color: rgba(83, 182, 255, 0.38);
      background: rgba(17, 39, 58, 0.95);
    }

    .device-card h3 {
      margin: 14px 0 10px;
      font-size: 21px;
      line-height: 1.06;
    }

    .device-card p {
      margin: 0;
      color: var(--muted);
      line-height: 1.45;
      font-size: 14px;
    }

    .device-meta {
      margin-top: 16px;
      display: grid;
      gap: 8px;
    }

    .meta-row {
      display: flex;
      justify-content: space-between;
      gap: 14px;
      color: var(--muted);
      font-size: 13px;
      border-top: 1px solid rgba(138, 161, 181, 0.08);
      padding-top: 8px;
    }

    .meta-row strong {
      color: var(--text);
      font-weight: 600;
      text-align: right;
      max-width: 62%;
      overflow-wrap: anywhere;
    }

    .device-card.key {
      grid-column: span 2;
    }

    .alert-row {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 12px 14px;
      border-radius: 16px;
      background: rgba(255, 204, 107, 0.08);
      border: 1px solid rgba(255, 204, 107, 0.16);
      color: var(--warn);
      margin-top: 14px;
    }

    .detail-card {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 24px;
      box-shadow: var(--shadow);
    }

    .detail-card h3 {
      margin: 16px 0 10px;
      font-size: 26px;
    }

    .detail-list {
      display: grid;
      gap: 10px;
      margin-top: 18px;
    }

    .detail-item {
      display: flex;
      justify-content: space-between;
      gap: 14px;
      padding-top: 10px;
      border-top: 1px solid rgba(138, 161, 181, 0.1);
    }

    .detail-item span {
      color: var(--muted);
      font-size: 13px;
      text-transform: uppercase;
      letter-spacing: 0.06em;
    }

    .detail-item strong {
      text-align: right;
      max-width: 65%;
      overflow-wrap: anywhere;
    }

    .ports {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 12px;
    }

    .port-pill {
      border-radius: 999px;
      padding: 7px 10px;
      background: rgba(79, 209, 124, 0.08);
      border: 1px solid rgba(79, 209, 124, 0.16);
      color: var(--text);
      font-size: 12px;
    }

    .empty-state {
      padding: 16px;
      border-radius: 18px;
      border: 1px dashed var(--border);
      color: var(--muted);
      text-align: center;
    }

    .activity-strip {
      display: grid;
      gap: 10px;
      margin-top: 18px;
    }

    .presence-bar {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(12px, 1fr));
      gap: 6px;
    }

    .presence-dot {
      height: 12px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(138, 161, 181, 0.08);
    }

    .presence-dot.online {
      background: rgba(79, 209, 124, 0.75);
      border-color: rgba(79, 209, 124, 0.25);
    }

    .presence-dot.offline {
      background: rgba(255, 125, 125, 0.22);
      border-color: rgba(255, 125, 125, 0.18);
    }

    .event-list {
      display: grid;
      gap: 10px;
    }

    .event-row {
      display: grid;
      grid-template-columns: auto 1fr auto;
      gap: 10px;
      align-items: center;
      padding: 10px 12px;
      border-radius: 14px;
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(138, 161, 181, 0.08);
    }

    @media (max-width: 1100px) {
      .hero,
      .studio-grid,
      .detail-grid,
      .change-grid {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 820px) {
      body { padding: 20px 14px 44px; }
      .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
      .flow-grid { grid-template-columns: 1fr; }
      .device-card.key { grid-column: span 1; }
      .toolbar { grid-template-columns: 1fr; }
      .chip-row { justify-content: flex-start; }
      .spotlight-track { grid-auto-columns: minmax(220px, 82vw); }
    }
  </style>
</head>
<body>
  <main class="shell">
    <section class="hero">
      <div class="panel hero-main">
        <div class="eyebrow"><span class="beacon"></span>Network Studio</div>
        <h1>Understand your LAN without pretending to see everything.</h1>
        <p class="sub">This Mac can discover who is present, highlight the devices that deserve attention, run lightweight diagnostics, and show exactly where Wi-Fi client visibility stops.</p>
        <div id="stats" class="stats"></div>
        <div class="actions">
          <a class="btn" href="$dashboard_uri">Refresh Studio</a>
          <a class="btn" href="$labels_uri">Edit Device Labels</a>
          <a class="btn" href="$logs_uri">Open Logs</a>
        </div>
      </div>
      <aside class="hero-side">
        <div class="side-block">
          <div class="side-title">Control Room</div>
          <div class="side-value" id="control-room"></div>
        </div>
        <div class="side-block">
          <div class="side-title">Heads-Up</div>
          <div class="side-value" id="headsup"></div>
        </div>
        <div class="side-block">
          <div class="side-title">Network Makeup</div>
          <div class="side-value" id="composition"></div>
        </div>
        <div class="side-block">
          <div class="side-title">Generated</div>
          <div class="side-value">$generated_at</div>
        </div>
      </aside>
    </section>

    <section class="panel toolbar">
      <input class="search" id="search" type="search" placeholder="Search by device name, hostname, IP, vendor, or MAC">
      <div class="chip-row" id="filters"></div>
    </section>

    <section class="panel watch-board">
      <div class="section-head">
        <div>
          <h2>Watch Deck</h2>
          <p>The short list of devices and signals that deserve your attention first.</p>
        </div>
      </div>
      <div class="watch-grid" id="watch-grid"></div>
    </section>

    <section class="panel pulse-board">
      <div class="section-head">
        <div>
          <h2>Live Pulse</h2>
          <p>Auto-refresh, quick health, and the dominant patterns in the current scan.</p>
        </div>
      </div>
      <div class="pulse-grid" id="pulse-grid"></div>
    </section>

    <section class="panel spotlight">
      <div class="section-head">
        <div>
          <h2>Focus Strip</h2>
          <p>The key devices, surprises, and watchlist entries worth clicking into first.</p>
        </div>
      </div>
      <div class="spotlight-track" id="spotlight-track"></div>
    </section>

    <section class="studio-grid">
      <div class="panel topology">
        <div class="section-head">
          <div>
            <h2>Network Map</h2>
            <p>Router at the center, this Mac pinned nearby, and visible devices arranged by trust and change state.</p>
          </div>
        </div>
        <div class="topology-canvas" id="topology-canvas">
          <div class="ring outer"></div>
          <div class="ring inner"></div>
          <div class="flow-ring"></div>
          <svg class="topology-svg" id="topology-svg"></svg>
        </div>
      </div>

      <div class="section-stack">
        <section class="panel detail-card">
          <div class="section-head">
            <div>
              <h2>Device Inspector</h2>
              <p>Hover or click a node or card to inspect it here.</p>
            </div>
          </div>
          <div id="selected-device"></div>
        </section>

        <section class="panel detail-card">
          <div class="section-head">
            <div>
              <h2>Visibility Guide</h2>
              <p>What this Mac can actually observe on a switched Wi-Fi network.</p>
            </div>
          </div>
          <div class="flow-grid">
            <article class="flow-card">
              <div class="icon">1</div>
              <strong>Your own traffic</strong>
              <p>This Mac can see its own DNS, local apps, direct pings, and its own open-port diagnostics in detail.</p>
            </article>
            <article class="flow-card">
              <div class="icon">2</div>
              <strong>LAN presence</strong>
              <p>It can discover other devices by ARP, names, change history, and quick probes like ping or selected ports.</p>
            </article>
            <article class="flow-card">
              <div class="icon">3</div>
              <strong>Not directly visible</strong>
              <p>It cannot fully inspect private traffic between two other Wi-Fi devices unless this Mac becomes the gateway, proxy, or packet mirror target.</p>
            </article>
          </div>
        </section>
      </div>
    </section>

    <section class="detail-grid">
      <div class="section-stack">
        <section class="panel change-card">
          <div class="section-head">
            <div>
              <h2>Change Feed</h2>
              <p>Short timeline of devices joining, missing, and returning.</p>
            </div>
          </div>
          <div class="timeline" id="timeline"></div>
        </section>

        <section class="panel change-card">
          <div class="section-head">
            <div>
              <h2>Deeper Visibility Paths</h2>
              <p>Ways to go deeper without pretending the current vantage point sees everything.</p>
            </div>
          </div>
          <div class="timeline">
            <div class="timeline-row"><span class="badge returned">Router</span><div>Use router telemetry or UniFi/Omada style client analytics for real per-device traffic volume.</div><div>Best</div></div>
            <div class="timeline-row"><span class="badge joined">Mirror</span><div>Mirror traffic from a managed switch or access point into this Mac for much deeper inspection.</div><div>Advanced</div></div>
            <div class="timeline-row"><span class="badge missing">Gateway</span><div>Make this Mac the DNS server, proxy, or gateway only if you want a much heavier lab setup.</div><div>Lab mode</div></div>
          </div>
        </section>
      </div>

      <section class="panel device-section">
        <div class="section-head">
          <div>
            <h2>Device Atlas</h2>
            <p>Cards grouped into key, known, and unknown devices. Search and filters above affect this view.</p>
          </div>
        </div>
        <div id="unknown-alert"></div>
        <div class="device-sections" id="device-sections"></div>
      </section>
    </section>
  </main>

  <script id="studio-data" type="application/json">$state_json</script>
  <script>
    const state = JSON.parse(document.getElementById("studio-data").textContent);
    const searchInput = document.getElementById("search");
    const filtersRoot = document.getElementById("filters");
    const statsRoot = document.getElementById("stats");
    const controlRoomRoot = document.getElementById("control-room");
    const headsupRoot = document.getElementById("headsup");
    const compositionRoot = document.getElementById("composition");
    const watchGridRoot = document.getElementById("watch-grid");
    const pulseGridRoot = document.getElementById("pulse-grid");
    const spotlightRoot = document.getElementById("spotlight-track");
    const topologyCanvas = document.getElementById("topology-canvas");
    const topologySvg = document.getElementById("topology-svg");
    const selectedRoot = document.getElementById("selected-device");
    const timelineRoot = document.getElementById("timeline");
    const sectionsRoot = document.getElementById("device-sections");
    const unknownAlertRoot = document.getElementById("unknown-alert");

    const FILTERS = [
      { id: "all", label: "Everything" },
      { id: "key", label: "Key devices" },
      { id: "known", label: "Trusted / familiar" },
      { id: "unknown", label: "Needs review" },
      { id: "watch", label: "Watchlist" },
      { id: "changed", label: "Recently changed" },
      { id: "ports", label: "Open ports" },
      { id: "slow", label: "Slow replies" }
    ];

    let activeFilter = "all";
    let selectedId = (window.location.hash || "").replace("#device=", "");
    let autoRefreshSeconds = Number(state.insights?.auto_refresh_seconds || 30);
    let refreshCountdown = autoRefreshSeconds;
    let autoRefreshEnabled = localStorage.getItem("networkStudioAutoRefresh") !== "off";

    function escapeHtml(value) {
      return String(value || "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");
    }

    function humanLatency(value) {
      return value == null ? "No reply yet" : `${value} ms`;
    }

    function buildStats() {
      const cards = [
        ["Visible devices", state.stats.visible],
        ["Watchlist", state.stats.watch],
        ["Unknown devices", state.stats.unknown],
        ["Recent movement", state.stats.recent_changes]
      ];
      statsRoot.innerHTML = cards.map(([label, value]) => `
        <article class="stat">
          <span>${label}</span>
          <strong>${value}</strong>
        </article>
      `).join("");
    }

    function buildHeaderBits() {
      controlRoomRoot.innerHTML = `
        <strong>This Mac</strong><br>${escapeHtml(state.network.local_ip || "Unknown")}<br><br>
        <strong>Router</strong><br>${escapeHtml(state.network.gateway_ip || "Unknown")}<br><br>
        <strong>Interface</strong><br>${escapeHtml(state.network.iface || "Unknown")}<br><br>
        <strong>Latest scan</strong><br>${escapeHtml(state.latest_scan || "Unknown")}
      `;

      const summary = [];
      if (state.stats.new > 0) summary.push(`${state.stats.new} new`);
      if (state.stats.unknown > 0) summary.push(`${state.stats.unknown} unknown`);
      if (state.stats.slow > 0) summary.push(`${state.stats.slow} slow replies`);
      if (state.stats.ports > 0) summary.push(`${state.stats.ports} with ports`);
      if (state.stats.missing > 0) summary.push(`${state.stats.missing} missing from last scan`);
      if (!summary.length) summary.push("No surprises right now");
      headsupRoot.textContent = summary.join(" • ");
    }

    function buildComposition() {
      const familyChips = (state.composition?.families || [])
        .map((item) => `<span class="stack-chip">${escapeHtml(item.label)} • ${escapeHtml(item.count)}</span>`)
        .join("");
      const vendorChips = (state.composition?.vendors || [])
        .map((item) => `<span class="stack-chip">${escapeHtml(item.label)} • ${escapeHtml(item.count)}</span>`)
        .join("");

      compositionRoot.innerHTML = `
        <div class="stack-list">
          <div class="stack-row">
            <div class="stack-label">Families</div>
            <div class="stack-chip-row">${familyChips || `<span class="stack-chip">No family data yet</span>`}</div>
          </div>
          <div class="stack-row">
            <div class="stack-label">Vendors</div>
            <div class="stack-chip-row">${vendorChips || `<span class="stack-chip">No vendor data yet</span>`}</div>
          </div>
        </div>
      `;
    }

    function buildFilters() {
      filtersRoot.innerHTML = FILTERS.map((filter) => `
        <button class="chip ${filter.id === activeFilter ? "active" : ""}" data-filter="${filter.id}">${filter.label}</button>
      `).join("");
      filtersRoot.querySelectorAll(".chip").forEach((chip) => {
        chip.addEventListener("click", () => {
          activeFilter = chip.dataset.filter;
          render();
        });
      });
    }

    function matchesFilter(device) {
      if (activeFilter === "all") return true;
      if (activeFilter === "key") return device.group === "key";
      if (activeFilter === "known") return device.group === "known";
      if (activeFilter === "unknown") return device.group === "unknown";
      if (activeFilter === "watch") return (device.watch_reasons || []).length > 0;
      if (activeFilter === "changed") return ["new", "returned"].includes(device.status);
      if (activeFilter === "ports") return (device.ports || []).length > 0;
      if (activeFilter === "slow") return device.latency_ms != null && device.latency_ms >= 100;
      return true;
    }

    function matchesSearch(device) {
      const query = searchInput.value.trim().toLowerCase();
      if (!query) return true;
      const haystack = [
        device.display_name,
        device.hostname,
        device.ip,
        device.vendor,
        device.mac,
        device.label
      ].join(" ").toLowerCase();
      return haystack.includes(query);
    }

    function visibleDevices() {
      return state.devices.filter((device) => matchesFilter(device) && matchesSearch(device));
    }

    function ensureSelection(devices) {
      if (!devices.length) {
        selectedId = "";
        return;
      }
      if (selectedId && devices.some((device) => device.id === selectedId)) {
        return;
      }
      selectedId = devices[0].id;
    }

    function setSelection(deviceId) {
      selectedId = deviceId;
      if (deviceId) {
        history.replaceState(null, "", `#device=${deviceId}`);
      } else {
        history.replaceState(null, "", location.pathname);
      }
      renderSelected();
      renderTopology();
      renderSpotlight();
      renderDeviceSections();
    }

    function renderWatchGrid() {
      const cards = state.watchlist?.cards || [];
      if (!cards.length) {
        watchGridRoot.innerHTML = `<div class="empty-state">No watchlist data yet.</div>`;
        return;
      }

      watchGridRoot.innerHTML = cards.map((card) => `
        <button type="button" class="watch-card ${activeFilter === card.filter ? "is-active" : ""} ${card.count ? "" : "is-empty"}" data-filter="${card.filter}">
          <div class="watch-count">${escapeHtml(card.count)}</div>
          <div class="watch-title">${escapeHtml(card.title)}</div>
          <div class="watch-detail">${escapeHtml(card.detail)}</div>
        </button>
      `).join("");

      watchGridRoot.querySelectorAll("[data-filter]").forEach((card) => {
        card.addEventListener("click", () => {
          activeFilter = card.dataset.filter || "all";
          render();
        });
      });
    }

    function renderPulseGrid() {
      const cards = state.insights?.health_cards || [];
      const refreshCard = `
        <article class="pulse-card">
          <div class="pulse-label">Auto-refresh</div>
          <div class="pulse-value">${autoRefreshEnabled ? `On • ${refreshCountdown}s` : "Paused"}</div>
          <div class="pulse-meta">Reload the studio automatically so the map stays current while you watch it.</div>
          <div class="pulse-inline">
            <button type="button" class="mini-btn" id="toggle-refresh">${autoRefreshEnabled ? "Pause" : "Resume"}</button>
            <button type="button" class="mini-btn" id="refresh-now">Reload now</button>
          </div>
        </article>
      `;

      pulseGridRoot.innerHTML = refreshCard + cards.map((card) => `
        <article class="pulse-card">
          <div class="pulse-label">${escapeHtml(card.title)}</div>
          <div class="pulse-value">${escapeHtml(card.value)}</div>
          <div class="pulse-meta">${escapeHtml(card.detail)}</div>
        </article>
      `).join("");

      const toggleButton = document.getElementById("toggle-refresh");
      const refreshNowButton = document.getElementById("refresh-now");
      if (toggleButton) {
        toggleButton.addEventListener("click", () => {
          autoRefreshEnabled = !autoRefreshEnabled;
          localStorage.setItem("networkStudioAutoRefresh", autoRefreshEnabled ? "on" : "off");
          refreshCountdown = autoRefreshSeconds;
          renderPulseGrid();
        });
      }
      if (refreshNowButton) {
        refreshNowButton.addEventListener("click", () => window.location.reload());
      }
    }

    function renderSpotlight() {
      const devices = visibleDevices();
      const spotlightDevices = devices
        .filter((device) => device.group === "key" || ["new", "returned"].includes(device.status) || !device.known)
        .slice(0, 10);

      if (!spotlightDevices.length) {
        spotlightRoot.innerHTML = `<div class="empty-state">No highlighted devices for the current filter.</div>`;
        return;
      }

      spotlightRoot.innerHTML = spotlightDevices.map((device) => `
        <article class="spotlight-card ${device.id === selectedId ? "is-selected" : ""}" data-device="${device.id}">
          <div class="label-row">
            <span class="pill">${escapeHtml(device.kind_label)}</span>
            <span class="pill">${escapeHtml(device.status_label)}</span>
            <span class="pill">${escapeHtml(device.family_label)}</span>
            <span class="pill">${escapeHtml(device.vendor_label || device.vendor || "Unknown vendor")}</span>
          </div>
          <h3>${escapeHtml(device.display_name)}</h3>
          <p>${escapeHtml(device.ip)} • ${escapeHtml(device.visibility_short)}</p>
          <div class="device-meta">
            <div class="meta-row"><span>Latency</span><strong>${escapeHtml(humanLatency(device.latency_ms))}</strong></div>
            <div class="meta-row"><span>First seen</span><strong>${escapeHtml(device.first_seen_human)}</strong></div>
            <div class="meta-row"><span>Watchlist</span><strong>${escapeHtml((device.watch_reasons || []).length ? device.watch_reasons.join(", ") : "Quiet")}</strong></div>
            <div class="meta-row"><span>Open ports</span><strong>${escapeHtml((device.ports || []).length ? device.ports.map((port) => port.port).join(", ") : "None cached")}</strong></div>
          </div>
        </article>
      `).join("");

      spotlightRoot.querySelectorAll("[data-device]").forEach((card) => {
        card.addEventListener("click", () => setSelection(card.dataset.device));
      });
    }

    function layoutDevices(devices) {
      const router = devices.find((device) => device.kind === "router");
      const local = devices.find((device) => device.kind === "local");
      const others = devices.filter((device) => !["router", "local"].includes(device.kind));

      const width = topologyCanvas.clientWidth;
      const height = topologyCanvas.clientHeight;
      const center = { x: width / 2, y: height / 2 };
      const coords = new Map();

      if (router) coords.set(router.id, { x: center.x, y: center.y });
      if (local) coords.set(local.id, { x: center.x - width * 0.18, y: center.y + height * 0.12 });

      const known = others.filter((device) => device.group === "known");
      const unknown = others.filter((device) => device.group === "unknown");
      const fresh = others.filter((device) => ["new", "returned"].includes(device.status) && device.group !== "unknown");

      function placeRing(group, radius, startAngle) {
        if (!group.length) return;
        group.forEach((device, index) => {
          const angle = startAngle + (Math.PI * 2 * index) / group.length;
          coords.set(device.id, {
            x: center.x + Math.cos(angle) * radius,
            y: center.y + Math.sin(angle) * radius
          });
        });
      }

      placeRing(known.filter((device) => !fresh.includes(device)), Math.min(width, height) * 0.24, -Math.PI / 2);
      placeRing(unknown, Math.min(width, height) * 0.36, -Math.PI / 3);
      placeRing(fresh, Math.min(width, height) * 0.3, Math.PI / 4);

      return coords;
    }

    function renderTopology() {
      const devices = visibleDevices();
      ensureSelection(devices);
      const coords = layoutDevices(devices);
      topologySvg.innerHTML = "";
      topologyCanvas.querySelectorAll(".node").forEach((node) => node.remove());

      const router = devices.find((device) => device.kind === "router");
      const routerPos = router ? coords.get(router.id) : null;

      devices.forEach((device) => {
        const pos = coords.get(device.id);
        if (!pos) return;

        if (routerPos && device.id !== router?.id) {
          const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
          line.setAttribute("x1", routerPos.x);
          line.setAttribute("y1", routerPos.y);
          line.setAttribute("x2", pos.x);
          line.setAttribute("y2", pos.y);
          if (device.id === selectedId) line.classList.add("is-selected");
          topologySvg.appendChild(line);
        }

        const node = document.createElement("button");
        node.type = "button";
        node.className = `node ${device.group} ${device.id === selectedId ? "is-selected" : ""}`;
        node.style.left = `${pos.x}px`;
        node.style.top = `${pos.y}px`;
        node.dataset.device = device.id;
        node.innerHTML = `
          <div class="name">${escapeHtml(device.display_name)}</div>
          <div class="meta">${escapeHtml(device.ip)} • ${escapeHtml(device.status_label)}</div>
        `;
        node.addEventListener("mouseenter", () => setSelection(device.id));
        node.addEventListener("click", () => setSelection(device.id));
        topologyCanvas.appendChild(node);
      });
    }

    function renderTimeline() {
      if (!state.changes.length) {
        timelineRoot.innerHTML = `<div class="empty-state">No change timeline yet. Run a few rescans to build one.</div>`;
        return;
      }
      timelineRoot.innerHTML = state.changes.map((change) => `
        <div class="timeline-row">
          <span class="badge ${change.type}">${escapeHtml(change.type)}</span>
          <div>
            <strong>${escapeHtml(change.display_name)}</strong><br>
            <span style="color: var(--muted)">${escapeHtml(change.ip)} • ${escapeHtml(change.vendor || "Unknown vendor")}</span>
          </div>
          <div style="color: var(--muted); font-size: 13px">${escapeHtml(change.when)}</div>
        </div>
      `).join("");
    }

    function sectionTitle(title, subtitle) {
      return `
        <div class="section-head">
          <div>
            <h2>${title}</h2>
            <p>${subtitle}</p>
          </div>
        </div>
      `;
    }

    function renderDeviceSections() {
      const devices = visibleDevices();
      ensureSelection(devices);

      const groups = [
        {
          key: "key",
          title: "Key Devices",
          subtitle: "Router and this Mac stay front-and-center.",
          items: devices.filter((device) => device.group === "key")
        },
        {
          key: "known",
          title: "Known Devices",
          subtitle: "Trusted, labeled, or repeatedly-seen devices.",
          items: devices.filter((device) => device.group === "known")
        },
        {
          key: "unknown",
          title: "Needs Review",
          subtitle: "Visible clients that still need a name, trust decision, or closer look.",
          items: devices.filter((device) => device.group === "unknown")
        }
      ].filter((group) => group.items.length);

      if (!groups.length) {
        sectionsRoot.innerHTML = `<div class="empty-state">Nothing matches the current search/filter.</div>`;
        return;
      }

      sectionsRoot.innerHTML = groups.map((group) => `
        <section class="panel device-section">
          ${sectionTitle(group.title, group.subtitle)}
          <div class="device-grid">
            ${group.items.map((device, index) => `
              <article class="device-card ${device.group === "key" ? "key" : ""} ${device.id === selectedId ? "is-selected" : ""}" data-device="${device.id}" style="animation-delay:${Math.min(index * 0.03, 0.24)}s">
                <div class="label-row">
                  <span class="pill">${escapeHtml(device.kind_label)}</span>
                  <span class="pill">${escapeHtml(device.status_label)}</span>
                  <span class="pill">${escapeHtml(device.family_label)}</span>
                  <span class="pill">${escapeHtml(device.vendor_label || device.vendor || "Unknown vendor")}</span>
                </div>
                <h3>${escapeHtml(device.display_name)}</h3>
                <p>${escapeHtml(device.ip)} • ${escapeHtml(device.visibility_short)}</p>
                <div class="device-meta">
                  <div class="meta-row"><span>Latency</span><strong>${escapeHtml(humanLatency(device.latency_ms))}</strong></div>
                  <div class="meta-row"><span>First seen</span><strong>${escapeHtml(device.first_seen_human)}</strong></div>
                  <div class="meta-row"><span>Last seen</span><strong>${escapeHtml(device.last_seen_human)}</strong></div>
                  <div class="meta-row"><span>Watchlist</span><strong>${escapeHtml((device.watch_reasons || []).length ? device.watch_reasons.join(", ") : "Quiet")}</strong></div>
                  <div class="meta-row"><span>Open ports</span><strong>${escapeHtml((device.ports || []).length ? device.ports.map((port) => `${port.port}/${port.service}`).join(", ") : "None cached")}</strong></div>
                </div>
              </article>
            `).join("")}
          </div>
        </section>
      `).join("");

      sectionsRoot.querySelectorAll("[data-device]").forEach((card) => {
        card.addEventListener("click", () => setSelection(card.dataset.device));
      });
    }

    function renderSelected() {
      const device = state.devices.find((item) => item.id === selectedId) || state.devices[0];
      if (!device) {
        selectedRoot.innerHTML = `<div class="empty-state">No devices are visible yet.</div>`;
        return;
      }
      selectedId = device.id;
      selectedRoot.innerHTML = `
        <div class="label-row">
          <span class="pill">${escapeHtml(device.kind_label)}</span>
          <span class="pill">${escapeHtml(device.status_label)}</span>
          <span class="pill">${escapeHtml(device.family_label)}</span>
          <span class="pill">${escapeHtml(device.vendor_label || device.vendor || "Unknown vendor")}</span>
        </div>
        <h3>${escapeHtml(device.display_name)}</h3>
        <p>${escapeHtml(device.visibility_long)}</p>
        <div class="detail-list">
          <div class="detail-item"><span>IP</span><strong>${escapeHtml(device.ip)}</strong></div>
          <div class="detail-item"><span>MAC</span><strong>${escapeHtml(device.mac)}</strong></div>
          <div class="detail-item"><span>Hostname</span><strong>${escapeHtml(device.hostname || "None")}</strong></div>
          <div class="detail-item"><span>Family</span><strong>${escapeHtml(device.family_label)}</strong></div>
          <div class="detail-item"><span>Latency</span><strong>${escapeHtml(humanLatency(device.latency_ms))}</strong></div>
          <div class="detail-item"><span>Seen</span><strong>${escapeHtml(String(device.seen_count))} scans</strong></div>
          <div class="detail-item"><span>First seen</span><strong>${escapeHtml(device.first_seen_human)}</strong></div>
          <div class="detail-item"><span>Last seen</span><strong>${escapeHtml(device.last_seen_human)}</strong></div>
          <div class="detail-item"><span>Watchlist</span><strong>${escapeHtml((device.watch_reasons || []).length ? device.watch_reasons.join(", ") : "Quiet")}</strong></div>
          <div class="detail-item"><span>Ports checked</span><strong>${escapeHtml(device.ports_checked_human || "No cached scan")}</strong></div>
          <div class="detail-item"><span>Trust</span><strong>${escapeHtml(device.known ? "Known" : "Unknown")}</strong></div>
          <div class="detail-item"><span>Notes</span><strong>${escapeHtml(device.notes || "None")}</strong></div>
        </div>
        <div class="activity-strip">
          <div>
            <div class="pulse-label">Recent scan presence</div>
            <div class="pulse-meta">${escapeHtml(device.presence_summary || "No recent history")}</div>
            <div class="presence-bar">
              ${(device.presence_samples || []).length
                ? device.presence_samples.map((sample) => `<span class="presence-dot ${sample.online ? "online" : "offline"}" title="${escapeHtml(sample.timestamp)}"></span>`).join("")
                : `<span class="pulse-meta">No presence samples yet</span>`}
            </div>
          </div>
          <div>
            <div class="pulse-label">Recent activity</div>
            <div class="event-list">
              ${(device.recent_events || []).length
                ? device.recent_events.map((event) => `
                    <div class="event-row">
                      <span class="badge ${escapeHtml(event.type)}">${escapeHtml(event.type)}</span>
                      <div>${escapeHtml(device.display_name)}</div>
                      <div style="color: var(--muted); font-size: 12px">${escapeHtml(event.when)}</div>
                    </div>
                  `).join("")
                : `<div class="empty-state">No recent join/missing events for this device.</div>`}
            </div>
          </div>
        </div>
        <div class="ports">
          ${(device.ports || []).length
            ? device.ports.map((port) => `<span class="port-pill">${escapeHtml(`${port.port}/${port.protocol} • ${port.service}`)}</span>`).join("")
            : `<span class="port-pill">No quick port scan cached</span>`}
        </div>
        <div class="actions" style="margin-top:18px">
          <a class="btn" href="http://${escapeHtml(device.ip)}">Open http://${escapeHtml(device.ip)}</a>
          <a class="btn" href="$labels_uri">Edit labels</a>
        </div>
      `;
    }

    function renderUnknownAlert() {
      if (!state.stats.unknown) {
        unknownAlertRoot.innerHTML = "";
        return;
      }
      unknownAlertRoot.innerHTML = `
        <div class="alert-row">
          <strong>${state.stats.unknown} unknown device${state.stats.unknown === 1 ? "" : "s"} visible.</strong>
          <span>Give them names in the labels file and mark the ones you trust to shrink the watchlist.</span>
        </div>
      `;
    }

    function render() {
      buildFilters();
      renderWatchGrid();
      renderPulseGrid();
      renderSpotlight();
      renderTopology();
      renderTimeline();
      renderDeviceSections();
      renderSelected();
      renderUnknownAlert();
    }

    buildStats();
    buildHeaderBits();
    buildComposition();
    buildFilters();
    render();

    searchInput.addEventListener("input", render);
    window.addEventListener("hashchange", () => {
      selectedId = (window.location.hash || "").replace("#device=", "");
      render();
    });
    window.setInterval(() => {
      if (!autoRefreshEnabled) return;
      refreshCountdown -= 1;
      if (refreshCountdown <= 0) {
        window.location.reload();
        return;
      }
      renderPulseGrid();
    }, 1000);
    window.addEventListener("resize", renderTopology);
  </script>
</body>
</html>
"""
    )
    return template.safe_substitute(
        state_json=state_json,
        labels_uri=labels_path.as_uri(),
        logs_uri=logs_dir.as_uri(),
        dashboard_uri=state["paths"]["dashboard_uri"],
        generated_at=state["generated_at"],
    )


def main() -> int:
    if len(sys.argv) != 8:
        print(
            "usage: build-network-studio.py latest.csv previous.csv history.csv labels.json vendor-cache.json state.json dashboard.html",
            file=sys.stderr,
        )
        return 1

    latest_path = absolute_path(Path(sys.argv[1]))
    previous_path = absolute_path(Path(sys.argv[2]))
    history_path = absolute_path(Path(sys.argv[3]))
    labels_path = absolute_path(Path(sys.argv[4]))
    vendor_cache_path = absolute_path(Path(sys.argv[5]))
    state_path = absolute_path(Path(sys.argv[6]))
    dashboard_path = absolute_path(Path(sys.argv[7])) if len(sys.argv) > 7 else state_path.with_name("network-dashboard.html")

    state_path.parent.mkdir(parents=True, exist_ok=True)
    dashboard_path.parent.mkdir(parents=True, exist_ok=True)

    iface, local_ip, gateway_ip = detect_network()
    latest_rows = load_csv_rows(latest_path)
    previous_rows = load_csv_rows(previous_path)
    history_rows = load_csv_rows(history_path, has_header=True)
    previous_state = load_previous_state(state_path)

    latest_by_id = {row["mac"] or normalize_mac(row["ip"]): row for row in latest_rows}
    previous_by_id = {row["mac"] or normalize_mac(row["ip"]): row for row in previous_rows}

    local_row = next((row for row in latest_rows if row["ip"] == local_ip), {})
    gateway_row = next((row for row in latest_rows if row["ip"] == gateway_ip), {})
    local_mac = normalize_mac(local_row.get("mac", ""))
    gateway_mac = normalize_mac(gateway_row.get("mac", ""))

    labels = ensure_labels_file(labels_path, local_mac, gateway_mac)
    label_devices = labels.get("devices", {})
    vendor_cache = load_vendor_cache(vendor_cache_path)
    vendors = enrich_vendors(latest_rows + previous_rows, vendor_cache)
    save_vendor_cache(vendor_cache_path, vendor_cache)

    history_index, ordered_snapshots = load_history_index(history_rows)
    timeline = build_timeline(ordered_snapshots)
    presence_samples = build_presence_samples(ordered_snapshots)
    latest_timeline_lookup = {event["mac"]: event for event in timeline if event["timestamp"] == latest_rows[0]["timestamp"]} if latest_rows else {}
    events_by_mac: dict[str, list[dict[str, str]]] = defaultdict(list)
    for event in reversed(timeline):
        events_by_mac[event["mac"]].append(
            {
                "type": event["type"],
                "timestamp": event["timestamp"],
                "when": humanize_ts(event["timestamp"]),
                "ip": event["ip"],
            }
        )

    previous_state_devices = {
        str(device.get("id")): device
        for device in previous_state.get("devices", []) + previous_state.get("missing_devices", [])
    }

    devices: list[dict[str, object]] = []
    missing_devices: list[dict[str, object]] = []

    for device_id, row in latest_by_id.items():
        labels_entry = label_devices.get(device_id, {}) or label_devices.get(row["ip"], {})
        hostname = resolve_reverse_dns(row["ip"], row["hostname"])
        vendor = vendors.get(device_id, "Unknown vendor")
        kind = "client"
        if device_id == local_mac and local_mac:
            kind = "local"
        elif device_id == gateway_mac and gateway_mac:
            kind = "router"

        history_info = history_index.get(device_id, {})
        seen_count = len(history_info.get("timestamps", set()))
        first_seen = str(history_info.get("first_seen", row["timestamp"]))
        last_seen = str(history_info.get("last_seen", row["timestamp"]))
        label = str(labels_entry.get("label", "")).strip()
        pinned = bool(labels_entry.get("pinned", False))
        trusted = bool(labels_entry.get("trusted", False))
        notes = str(labels_entry.get("notes", ""))
        status = "online"
        if device_id not in previous_by_id:
            event = latest_timeline_lookup.get(device_id)
            status = "returned" if event and event["type"] == "returned" else "new"

        stable_vendor = vendor not in {"Private / randomized", "Unknown vendor"}
        known = kind in {"local", "router"} or trusted or pinned or bool(label) or (seen_count >= 5 and stable_vendor)
        group = "key" if kind in {"local", "router"} else ("known" if known else "unknown")
        family_label = infer_family(kind, label, hostname, vendor, notes)

        devices.append(
            {
                "id": device_id,
                "ip": row["ip"],
                "ip_tail": row["ip"].split(".")[-1],
                "mac": device_id,
                "hostname": hostname,
                "label": label,
                "display_name": build_display_name(kind, label, hostname, row["ip"], vendor),
                "vendor": vendor,
                "vendor_label": compact_vendor_name(vendor),
                "iface": row["iface"],
                "kind": kind,
                "kind_label": {"local": "This Mac", "router": "Router", "client": "Client"}[kind],
                "family_label": family_label,
                "known": known,
                "trusted": trusted,
                "pinned": pinned,
                "status": status,
                "status_label": {"online": "Stable", "new": "New", "returned": "Returned"}[status],
                "first_seen": first_seen,
                "last_seen": last_seen,
                "first_seen_human": humanize_ts(first_seen),
                "last_seen_human": humanize_ts(last_seen),
                "seen_count": seen_count or 1,
                "group": group,
                "visibility_short": {"local": "Own traffic", "router": "Gateway view", "client": "Presence only"}[kind],
                "visibility_long": build_visibility(kind),
                "open_url": f"http://{row['ip']}",
                "notes": notes,
                "latency_ms": None,
                "ports": [],
                "watch_reasons": [],
                "recent_events": events_by_mac.get(device_id, [])[:6],
                "presence_samples": presence_samples.get(device_id, []),
                "dashboard_link": device_uri(dashboard_path, device_id),
            }
        )

    for device_id, row in previous_by_id.items():
        if device_id in latest_by_id:
            continue
        labels_entry = label_devices.get(device_id, {}) or label_devices.get(row["ip"], {})
        history_info = history_index.get(device_id, {})
        label = str(labels_entry.get("label", "")).strip()
        hostname = resolve_reverse_dns(row["ip"], row["hostname"])
        kind = "router" if device_id == gateway_mac else "client"
        if device_id == local_mac:
            kind = "local"
        vendor = vendors.get(device_id, "Unknown vendor")
        stable_vendor = vendor not in {"Private / randomized", "Unknown vendor"}
        known = kind in {"local", "router"} or bool(labels_entry.get("trusted")) or bool(label) or (len(history_info.get("timestamps", set())) >= 5 and stable_vendor)
        notes = str(labels_entry.get("notes", ""))
        missing_devices.append(
            {
                "id": device_id,
                "ip": row["ip"],
                "mac": device_id,
                "display_name": build_display_name(kind, label, hostname, row["ip"], vendor),
                "vendor": vendor,
                "vendor_label": compact_vendor_name(vendor),
                "kind": kind,
                "family_label": infer_family(kind, label, hostname, vendor, notes),
                "known": known,
                "status": "missing",
                "status_label": "Missing",
                "last_seen": str(history_info.get("last_seen", row["timestamp"])),
                "last_seen_human": humanize_ts(str(history_info.get("last_seen", row["timestamp"]))),
                "notes": notes,
                "watch_reasons": ["Missing from the latest scan"] + ([] if known else ["Needs review"]),
                "recent_events": events_by_mac.get(device_id, [])[:6],
                "presence_samples": presence_samples.get(device_id, []),
            }
        )

    devices.sort(key=lambda device: (0 if device["group"] == "key" else 1 if device["group"] == "known" else 2, tuple(int(part) for part in str(device["ip"]).split("."))))
    missing_devices.sort(key=lambda device: tuple(int(part) for part in str(device["ip"]).split(".")))

    latencies = collect_latencies(devices)
    for device in devices:
        device["latency_ms"] = latencies.get(str(device["id"]))

    port_candidates: list[dict[str, object]] = []
    for device in devices:
        if device["kind"] in {"local", "router"} or not device["known"] or device["status"] in {"new", "returned"}:
            port_candidates.append(device)
    port_candidates = port_candidates[:MAX_PORT_SCAN_TARGETS]

    generated_at = now_iso()
    def cached_ports_for(device: dict[str, object]) -> tuple[bool, list[dict[str, object]], str | None]:
        old = previous_state_devices.get(str(device["id"]), {})
        old_checked = old.get("ports_checked_at")
        cached_ports = old.get("ports")
        if old_checked:
            try:
                age = parse_iso(generated_at).timestamp() - parse_iso(str(old_checked)).timestamp()
            except ValueError:
                age = PORT_CACHE_TTL_SECONDS + 1
        else:
            age = PORT_CACHE_TTL_SECONDS + 1

        if cached_ports and age < PORT_CACHE_TTL_SECONDS and device["status"] == "online":
            return True, cached_ports, old_checked
        return False, [], None

    pending_scans: list[dict[str, object]] = []
    for device in port_candidates:
        cached, ports, checked_at = cached_ports_for(device)
        if cached:
            device["ports"] = ports
            device["ports_checked_at"] = checked_at
        else:
            pending_scans.append(device)

    if pending_scans:
        with ThreadPoolExecutor(max_workers=min(3, len(pending_scans))) as pool:
            future_map = {pool.submit(run_port_scan, str(device["ip"])): device for device in pending_scans}
            for future in as_completed(future_map):
                device = future_map[future]
                device["ports"] = future.result()
                device["ports_checked_at"] = generated_at

    for device in devices:
        checked_at = str(device.get("ports_checked_at", "")).strip()
        device["ports_checked_human"] = humanize_ts(checked_at) if checked_at else "No cached scan"
        device["watch_reasons"] = build_watch_reasons(device)
        device["attention_score"] = len(device["watch_reasons"]) + (2 if not device["known"] else 0)
        samples = device.get("presence_samples", [])
        online_samples = sum(1 for sample in samples if sample.get("online"))
        device["presence_summary"] = (
            f"{online_samples}/{len(samples)} recent scans"
            if samples else "No recent history"
        )

    for device in missing_devices:
        samples = device.get("presence_samples", [])
        online_samples = sum(1 for sample in samples if sample.get("online"))
        device["presence_summary"] = (
            f"{online_samples}/{len(samples)} recent scans"
            if samples else "No recent history"
        )

    change_devices = {device["id"]: device for device in devices}
    change_lookup = []
    for event in reversed(timeline):
        source = change_devices.get(event["mac"]) or next((item for item in missing_devices if item["id"] == event["mac"]), None)
        display_name = source["display_name"] if source else (short_hostname(event["hostname"]) or event["ip"])
        change_lookup.append(
            {
                "timestamp": event["timestamp"],
                "when": humanize_ts(event["timestamp"]),
                "type": event["type"],
                "ip": event["ip"],
                "mac": event["mac"],
                "display_name": display_name,
                "vendor": source["vendor"] if source else "",
                "dashboard_link": device_uri(dashboard_path, event["mac"]),
            }
        )

    known_devices = [device for device in devices if device["group"] in {"key", "known"}]
    unknown_devices = [device for device in devices if device["group"] == "unknown"]
    new_devices = [device for device in devices if device["status"] == "new"]
    returned_devices = [device for device in devices if device["status"] == "returned"]
    watch_devices = [device for device in devices if device["watch_reasons"]]
    slow_devices = [
        device for device in devices
        if isinstance(device.get("latency_ms"), (int, float)) and float(device["latency_ms"]) >= 100
    ]
    open_port_devices = [device for device in devices if device["ports"]]
    no_reply_devices = [device for device in devices if device.get("latency_ms") is None]
    family_counts = Counter(str(device["family_label"]) for device in devices)
    vendor_counts = Counter(
        str(device["vendor_label"])
        for device in devices
        if str(device["vendor_label"]) not in {"Unknown vendor", "Private client"}
    )
    watch_cards = [
        {
            "id": "unknown",
            "title": "Needs review",
            "count": len(unknown_devices),
            "detail": "Visible right now but not yet trusted or named.",
            "filter": "unknown",
        },
        {
            "id": "watch",
            "title": "Watchlist",
            "count": len(watch_devices),
            "detail": "Unknown, recently changed, slow, or showing ports.",
            "filter": "watch",
        },
        {
            "id": "ports",
            "title": "Open ports",
            "count": len(open_port_devices),
            "detail": "Quick cached port probes worth a closer look.",
            "filter": "ports",
        },
        {
            "id": "slow",
            "title": "Slow replies",
            "count": len(slow_devices),
            "detail": "Latest ping was 100 ms or slower.",
            "filter": "slow",
        },
        {
            "id": "changed",
            "title": "Recent movement",
            "count": len(new_devices) + len(returned_devices) + len(missing_devices),
            "detail": "Joined, returned, or missing on recent scans.",
            "filter": "changed",
        },
    ]
    top_family = family_counts.most_common(1)[0] if family_counts else ("Unknown", 0)
    top_vendor = vendor_counts.most_common(1)[0] if vendor_counts else ("Unknown vendor", 0)
    health_cards = [
        {
            "title": "Responding",
            "value": len(devices) - len(no_reply_devices),
            "detail": "Devices that answered the latest ping pass.",
        },
        {
            "title": "No reply",
            "value": len(no_reply_devices),
            "detail": "Visible on LAN but did not answer the latest ping pass.",
        },
        {
            "title": "Top family",
            "value": top_family[0],
            "detail": f"{top_family[1]} device{'s' if top_family[1] != 1 else ''}",
        },
        {
            "title": "Top vendor",
            "value": top_vendor[0],
            "detail": f"{top_vendor[1]} device{'s' if top_vendor[1] != 1 else ''}",
        },
    ]

    state = {
        "generated_at": generated_at,
        "latest_scan": latest_rows[0]["timestamp"] if latest_rows else "",
        "network": {
            "iface": iface,
            "local_ip": local_ip,
            "gateway_ip": gateway_ip,
        },
        "stats": {
            "visible": len(devices),
            "known": len(known_devices),
            "unknown": len(unknown_devices),
            "new": len(new_devices),
            "returned": len(returned_devices),
            "missing": len(missing_devices),
            "watch": len(watch_devices),
            "slow": len(slow_devices),
            "ports": len(open_port_devices),
            "recent_changes": len(change_lookup[:8]),
        },
        "highlights": {
            "new_devices": [device["display_name"] for device in new_devices[:5]],
            "unknown_devices": [device["display_name"] for device in unknown_devices[:5]],
            "watch_devices": [device["display_name"] for device in sorted(watch_devices, key=lambda item: (-int(item["attention_score"]), item["ip"]))[:5]],
        },
        "watchlist": {
            "cards": watch_cards,
            "slow_devices": [device["display_name"] for device in slow_devices[:5]],
            "open_port_devices": [device["display_name"] for device in open_port_devices[:5]],
        },
        "insights": {
            "health_cards": health_cards,
            "auto_refresh_seconds": 30,
            "responsive": len(devices) - len(no_reply_devices),
            "no_reply": len(no_reply_devices),
        },
        "composition": {
            "families": [
                {"label": label, "count": count}
                for label, count in family_counts.most_common(6)
            ],
            "vendors": [
                {"label": label, "count": count}
                for label, count in vendor_counts.most_common(6)
            ],
        },
        "paths": {
            "labels": str(labels_path),
            "logs_dir": str(history_path.parent),
            "state": str(state_path),
            "dashboard": str(dashboard_path),
            "dashboard_uri": dashboard_path.resolve().as_uri(),
        },
        "devices": devices,
        "missing_devices": missing_devices,
        "changes": change_lookup[:10],
    }

    state_path.write_text(json.dumps(state, indent=2) + "\n")
    dashboard_path.write_text(build_html(state, labels_path, history_path.parent))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
