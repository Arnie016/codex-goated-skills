#!/usr/bin/env bash
set -euo pipefail

port="${1:-25565}"
hostname_value="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
lan_ip="$(ipconfig getifaddr en0 2>/dev/null || true)"

printf 'Same machine: localhost:%s\n' "$port"

if [[ -n "$lan_ip" ]]; then
  printf 'Same Wi-Fi: %s:%s\n' "$lan_ip" "$port"
fi

if [[ -n "$hostname_value" ]]; then
  printf 'Hostname: %s.local:%s\n' "$hostname_value" "$port"
fi
