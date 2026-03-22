#!/usr/bin/env python3
from __future__ import annotations

import csv
import html
import sys
from pathlib import Path


def load_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []

    rows: list[dict[str, str]] = []
    with path.open(newline="") as fh:
        reader = csv.reader(fh)
        for row in reader:
            if not row:
                continue
            while len(row) < 5:
                row.append("")
            timestamp, ip, mac, iface, hostname = row[:5]
            rows.append(
                {
                    "timestamp": timestamp,
                    "ip": ip,
                    "mac": mac,
                    "iface": iface,
                    "hostname": hostname,
                }
            )
    return rows


def load_ip_set(path: Path) -> set[str]:
    return {row["ip"] for row in load_rows(path)}


def sort_key(row: dict[str, str], local_ip: str, gateway_ip: str):
    ip = row["ip"]
    if ip == local_ip:
        priority = 0
    elif ip == gateway_ip:
        priority = 1
    else:
        priority = 2

    try:
        ip_parts = tuple(int(part) for part in ip.split("."))
    except ValueError:
        ip_parts = (999, 999, 999, 999)
    return (priority, ip_parts)


def classify(row: dict[str, str], local_ip: str, gateway_ip: str) -> tuple[str, str]:
    if row["ip"] == local_ip:
        return ("This Mac", "key")
    if row["ip"] == gateway_ip:
        return ("Router", "key")
    return (row["hostname"] or row["ip"], "client")


def card(row: dict[str, str], local_ip: str, gateway_ip: str) -> str:
    label, kind = classify(row, local_ip, gateway_ip)
    badge = "Key device" if kind == "key" else "Client"
    ip = html.escape(row["ip"])
    mac = html.escape(row["mac"])
    iface = html.escape(row["iface"])
    label = html.escape(label)
    hostname = html.escape(row["hostname"])
    hostname_line = (
        f"<div class='meta'><span>Hostname</span><strong>{hostname}</strong></div>"
        if hostname and hostname != row["ip"]
        else ""
    )
    return f"""
    <article class="card {kind}">
      <div class="card-top">
        <div>
          <div class="badge">{badge}</div>
          <h3>{label}</h3>
        </div>
        <div class="ip-chip">{ip}</div>
      </div>
      <div class="meta-grid">
        <div class="meta"><span>MAC</span><strong>{mac}</strong></div>
        <div class="meta"><span>Interface</span><strong>{iface}</strong></div>
        {hostname_line}
      </div>
    </article>
    """


def main() -> int:
    if len(sys.argv) != 6:
        print("usage: render-dashboard.py latest.csv previous.csv local_ip gateway_ip output.html", file=sys.stderr)
        return 1

    latest_path = Path(sys.argv[1])
    previous_path = Path(sys.argv[2])
    local_ip = sys.argv[3]
    gateway_ip = sys.argv[4]
    output_path = Path(sys.argv[5])

    rows = load_rows(latest_path)
    previous_ips = load_ip_set(previous_path)
    current_ips = {row["ip"] for row in rows}
    new_ips = sorted(current_ips - previous_ips, key=lambda ip: tuple(int(p) for p in ip.split(".")))
    missing_ips = sorted(previous_ips - current_ips, key=lambda ip: tuple(int(p) for p in ip.split(".")))

    rows.sort(key=lambda row: sort_key(row, local_ip, gateway_ip))
    cards = "".join(card(row, local_ip, gateway_ip) for row in rows)

    latest_scan = rows[0]["timestamp"] if rows else "No data yet"
    html_doc = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Network Dashboard</title>
  <style>
    :root {{
      --bg: #07131f;
      --panel: rgba(18, 37, 55, 0.9);
      --panel-2: rgba(10, 25, 39, 0.92);
      --text: #e8f0f7;
      --muted: #8fa4b7;
      --accent: #41d17d;
      --accent-2: #45b7ff;
      --border: rgba(143, 164, 183, 0.18);
      --shadow: 0 20px 40px rgba(0, 0, 0, 0.35);
    }}

    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      min-height: 100vh;
      font-family: ui-rounded, "SF Pro Rounded", "SF Pro Display", -apple-system, BlinkMacSystemFont, sans-serif;
      background:
        radial-gradient(circle at top left, rgba(69, 183, 255, 0.18), transparent 28%),
        radial-gradient(circle at bottom right, rgba(65, 209, 125, 0.15), transparent 24%),
        linear-gradient(180deg, #0a1726 0%, #06101a 100%);
      color: var(--text);
    }}

    .shell {{
      max-width: 1200px;
      margin: 0 auto;
      padding: 32px 20px 56px;
    }}

    .hero {{
      display: grid;
      grid-template-columns: 1.3fr 0.7fr;
      gap: 18px;
      margin-bottom: 18px;
    }}

    .panel {{
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 24px;
      box-shadow: var(--shadow);
      backdrop-filter: blur(18px);
    }}

    .hero-main {{
      padding: 26px;
    }}

    .eyebrow {{
      color: var(--accent);
      letter-spacing: 0.12em;
      text-transform: uppercase;
      font-size: 12px;
      font-weight: 700;
      margin-bottom: 12px;
    }}

    h1 {{
      margin: 0 0 12px;
      font-size: clamp(30px, 4vw, 54px);
      line-height: 0.95;
    }}

    .sub {{
      margin: 0;
      color: var(--muted);
      font-size: 16px;
      line-height: 1.5;
      max-width: 48ch;
    }}

    .stats {{
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 14px;
      margin-top: 22px;
    }}

    .stat {{
      background: var(--panel-2);
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 16px;
    }}

    .stat .k {{
      color: var(--muted);
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }}

    .stat .v {{
      display: block;
      font-size: 28px;
      font-weight: 700;
      margin-top: 8px;
    }}

    .hero-side {{
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 14px;
      justify-content: space-between;
    }}

    .side-row {{
      padding: 14px 16px;
      border-radius: 18px;
      border: 1px solid var(--border);
      background: var(--panel-2);
    }}

    .side-row span {{
      display: block;
      color: var(--muted);
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      margin-bottom: 6px;
    }}

    .side-row strong {{
      font-size: 17px;
      word-break: break-word;
    }}

    .section-title {{
      margin: 28px 0 14px;
      color: var(--muted);
      font-size: 14px;
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }}

    .cards {{
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
      gap: 14px;
    }}

    .card {{
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 18px;
      box-shadow: var(--shadow);
    }}

    .card.key {{
      border-color: rgba(65, 209, 125, 0.25);
    }}

    .card-top {{
      display: flex;
      justify-content: space-between;
      gap: 12px;
      align-items: start;
      margin-bottom: 16px;
    }}

    .badge {{
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 10px;
      border-radius: 999px;
      background: rgba(69, 183, 255, 0.12);
      color: var(--accent-2);
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      margin-bottom: 10px;
    }}

    .card h3 {{
      margin: 0;
      font-size: 22px;
    }}

    .ip-chip {{
      white-space: nowrap;
      padding: 8px 10px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.05);
      color: var(--text);
      font-size: 13px;
      border: 1px solid var(--border);
    }}

    .meta-grid {{
      display: grid;
      gap: 10px;
    }}

    .meta {{
      display: flex;
      justify-content: space-between;
      gap: 18px;
      padding-top: 10px;
      border-top: 1px solid rgba(143, 164, 183, 0.12);
    }}

    .meta span {{
      color: var(--muted);
      font-size: 13px;
    }}

    .meta strong {{
      text-align: right;
      font-size: 14px;
      font-weight: 600;
      max-width: 65%;
      overflow-wrap: anywhere;
    }}

    .change-list {{
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 14px;
    }}

    .change-box {{
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 18px;
    }}

    .pill-list {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 14px;
    }}

    .pill {{
      border-radius: 999px;
      padding: 7px 10px;
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid var(--border);
      font-size: 13px;
    }}

    @media (max-width: 860px) {{
      .hero {{
        grid-template-columns: 1fr;
      }}
      .stats {{
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }}
      .change-list {{
        grid-template-columns: 1fr;
      }}
    }}
  </style>
</head>
<body>
  <main class="shell">
    <section class="hero">
      <div class="panel hero-main">
        <div class="eyebrow">Menu Bar Monitor</div>
        <h1>Your Network At A Glance</h1>
        <p class="sub">A compact view of the devices your Mac can currently see on the local network. This dashboard is generated from the same data feeding your menu bar icon.</p>
        <div class="stats">
          <div class="stat"><span class="k">Visible devices</span><span class="v">{len(rows)}</span></div>
          <div class="stat"><span class="k">New since last scan</span><span class="v">{len(new_ips)}</span></div>
          <div class="stat"><span class="k">Missing since last scan</span><span class="v">{len(missing_ips)}</span></div>
          <div class="stat"><span class="k">Latest scan</span><span class="v" style="font-size:18px">{html.escape(latest_scan)}</span></div>
        </div>
      </div>
      <aside class="panel hero-side">
        <div class="side-row"><span>This Mac</span><strong>{html.escape(local_ip or "Unknown")}</strong></div>
        <div class="side-row"><span>Router</span><strong>{html.escape(gateway_ip or "Unknown")}</strong></div>
        <div class="side-row"><span>Data source</span><strong>{html.escape(str(latest_path))}</strong></div>
      </aside>
    </section>

    <div class="section-title">Devices</div>
    <section class="cards">
      {cards or "<div class='panel' style='padding:20px'>No device data yet.</div>"}
    </section>

    <div class="section-title">Changes</div>
    <section class="change-list">
      <div class="change-box">
        <div class="eyebrow">New</div>
        <div class="pill-list">
          {"".join(f"<span class='pill'>{html.escape(ip)}</span>" for ip in new_ips) or "<span class='pill'>No new devices</span>"}
        </div>
      </div>
      <div class="change-box">
        <div class="eyebrow">Missing</div>
        <div class="pill-list">
          {"".join(f"<span class='pill'>{html.escape(ip)}</span>" for ip in missing_ips) or "<span class='pill'>No missing devices</span>"}
        </div>
      </div>
    </section>
  </main>
</body>
</html>
"""

    output_path.write_text(html_doc)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
