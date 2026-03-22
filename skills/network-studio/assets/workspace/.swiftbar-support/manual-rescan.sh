#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
bash "$script_dir/refresh-network-studio.sh" --scan >/dev/null 2>&1 || true
