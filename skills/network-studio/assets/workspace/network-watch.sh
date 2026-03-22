#!/usr/bin/env bash
set -euo pipefail

interval=60
log_dir="$(pwd)/logs"
iface=""
subnet=""
resolve_hostnames=0
run_once=0

usage() {
  cat <<'EOF'
Usage: ./network-watch.sh [options]

Continuously discovers devices on your local subnet and logs snapshots.

Options:
  --interval SECONDS   Time between scans (default: 60)
  --iface NAME         Network interface to use, for example en0
  --subnet CIDR        Subnet to scan, for example 192.168.1.0/24
  --log-dir PATH       Directory for CSV logs (default: ./logs)
  --resolve            Attempt reverse-DNS hostname lookups
  --once               Run one scan and exit
  --help               Show this help

Examples:
  ./network-watch.sh
  ./network-watch.sh --interval 30 --resolve
  ./network-watch.sh --subnet 192.168.1.0/24 --log-dir ~/network-logs

Notes:
  - This is best-effort LAN presence monitoring, not deep packet inspection.
  - For reliable discovery, install nmap: brew install nmap
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --interval)
        interval="${2:?missing value for --interval}"
        shift 2
        ;;
      --iface)
        iface="${2:?missing value for --iface}"
        shift 2
        ;;
      --subnet)
        subnet="${2:?missing value for --subnet}"
        shift 2
        ;;
      --log-dir)
        log_dir="${2:?missing value for --log-dir}"
        shift 2
        ;;
      --resolve)
        resolve_hostnames=1
        shift
        ;;
      --once)
        run_once=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
}

detect_default_iface() {
  route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}'
}

detect_ipv4() {
  local target_iface="$1"
  ipconfig getifaddr "$target_iface" 2>/dev/null || true
}

guess_subnet() {
  local ip="$1"
  local prefix
  prefix="${ip%.*}"
  printf '%s.0/24\n' "$prefix"
}

require_tools() {
  command -v arp >/dev/null 2>&1 || {
    echo "arp is required but not available" >&2
    exit 1
  }
}

reverse_lookup() {
  local ip="$1"
  python3 - "$ip" <<'PY'
import socket
import sys

ip = sys.argv[1]
try:
    host, _, _ = socket.gethostbyaddr(ip)
    print(host)
except Exception:
    print("")
PY
}

warm_arp_cache_with_nmap() {
  nmap -sn -n "$subnet" >/dev/null 2>&1 || true
}

warm_arp_cache_with_ping() {
  if [[ ! "$subnet" =~ /24$ ]]; then
    echo "Install nmap for non-/24 subnets: brew install nmap" >&2
    return
  fi

  local base
  base="${subnet%.*}"
  seq 1 254 | xargs -I{} -P 48 sh -c 'ping -c 1 -W 500 "$1" >/dev/null 2>&1 || true' _ "${base}.{}"
}

warm_arp_cache() {
  if command -v nmap >/dev/null 2>&1; then
    warm_arp_cache_with_nmap
  else
    warm_arp_cache_with_ping
  fi
}

snapshot_from_arp() {
  local snapshot_file="$1"
  local timestamp="$2"

  : > "$snapshot_file"

  while IFS= read -r line; do
    if [[ "$line" == *"(incomplete)"* ]]; then
      continue
    fi

    local ip=""
    local mac=""
    local on_iface=""
    local hostname=""
    local -a parts
    read -r -a parts <<<"$line"

    local idx
    for idx in "${!parts[@]}"; do
      case "${parts[$idx]}" in
        at)
          mac="${parts[$((idx + 1))]:-}"
          ;;
        on)
          on_iface="${parts[$((idx + 1))]:-}"
          ;;
      esac
    done

    if [[ "${parts[1]:-}" == \(*\) ]]; then
      ip="${parts[1]//[\(\)]/}"
    fi

    if [[ -z "$ip" || -z "$mac" ]]; then
      continue
    fi

    if [[ "$ip" == 224.* || "$ip" == 239.* || "$ip" == 255.255.255.255 ]]; then
      continue
    fi

    if [[ "$ip" == *.255 || "$mac" == "ff:ff:ff:ff:ff:ff" ]]; then
      continue
    fi

    if [[ -n "$iface" && "$on_iface" != "$iface" ]]; then
      continue
    fi

    if [[ "$resolve_hostnames" -eq 1 ]]; then
      hostname="$(reverse_lookup "$ip")"
    fi

    printf '%s,%s,%s,%s,%s\n' "$timestamp" "$ip" "$mac" "$on_iface" "$hostname" >> "$snapshot_file"
  done < <(arp -an)

  sort -u "$snapshot_file" -o "$snapshot_file"
}

print_snapshot() {
  local snapshot_file="$1"

  printf '\n[%s] Active devices\n' "$(date '+%Y-%m-%d %H:%M:%S')"
  printf '%-16s %-20s %-8s %s\n' "IP" "MAC" "IFACE" "HOSTNAME"
  printf '%-16s %-20s %-8s %s\n' "----------------" "--------------------" "--------" "--------"

  if [[ ! -s "$snapshot_file" ]]; then
    echo "No devices found."
    return
  fi

  while IFS=, read -r _ ip mac on_iface hostname; do
    printf '%-16s %-20s %-8s %s\n' "$ip" "$mac" "$on_iface" "${hostname:--}"
  done < "$snapshot_file"
}

print_changes() {
  local previous_file="$1"
  local current_file="$2"

  if [[ ! -f "$previous_file" ]]; then
    return
  fi

  local previous_tmp current_tmp
  previous_tmp="$(mktemp)"
  current_tmp="$(mktemp)"

  cut -d, -f2- "$previous_file" | sort -u > "$previous_tmp"
  cut -d, -f2- "$current_file" | sort -u > "$current_tmp"

  local added removed
  added="$(comm -13 "$previous_tmp" "$current_tmp" || true)"
  removed="$(comm -23 "$previous_tmp" "$current_tmp" || true)"

  if [[ -n "$added" ]]; then
    echo
    echo "New since last scan:"
    printf '%s\n' "$added"
  fi

  if [[ -n "$removed" ]]; then
    echo
    echo "Missing since last scan:"
    printf '%s\n' "$removed"
  fi

  rm -f "$previous_tmp" "$current_tmp"
}

prepare_paths() {
  mkdir -p "$log_dir"
  history_file="$log_dir/device-history.csv"
  latest_file="$log_dir/latest-snapshot.csv"
  previous_file="$log_dir/previous-snapshot.csv"

  if [[ ! -f "$history_file" ]]; then
    echo "timestamp,ip,mac,iface,hostname" > "$history_file"
  fi
}

main() {
  parse_args "$@"
  require_tools

  if [[ -z "$iface" ]]; then
    iface="$(detect_default_iface)"
  fi

  if [[ -z "$iface" ]]; then
    echo "Could not detect a default network interface." >&2
    exit 1
  fi

  local_ip="$(detect_ipv4 "$iface")"
  if [[ -z "$local_ip" ]]; then
    echo "Could not detect an IPv4 address on interface $iface." >&2
    exit 1
  fi

  if [[ -z "$subnet" ]]; then
    subnet="$(guess_subnet "$local_ip")"
  fi

  prepare_paths

  echo "Watching interface: $iface"
  echo "Local IPv4: $local_ip"
  echo "Subnet: $subnet"
  echo "Logs: $log_dir"
  echo "Hostname resolution: $([[ "$resolve_hostnames" -eq 1 ]] && echo on || echo off)"
  echo "Discovery method: $([[ $(command -v nmap >/dev/null 2>&1; echo $?) -eq 0 ]] && echo nmap || echo arp+ping)"

  while true; do
    local timestamp
    timestamp="$(date '+%Y-%m-%dT%H:%M:%S%z')"

    warm_arp_cache

    if [[ -f "$latest_file" ]]; then
      cp "$latest_file" "$previous_file"
    fi

    local current_raw
    current_raw="$(mktemp)"
    snapshot_from_arp "$current_raw" "$timestamp"

    cat "$current_raw" > "$latest_file"
    cat "$current_raw" >> "$history_file"

    print_snapshot "$current_raw"
    print_changes "$previous_file" "$current_raw"

    rm -f "$current_raw"

    if [[ "$run_once" -eq 1 ]]; then
      break
    fi

    sleep "$interval"
  done
}

main "$@"
