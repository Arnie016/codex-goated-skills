#!/bin/sh
set -eu

ROOT="${1:-$HOME}"

find "$ROOT" -type f \( -name 'paper-*.jar' -o -name 'purpur-*.jar' -o -name 'spigot-*.jar' \) 2>/dev/null \
  | while IFS= read -r jar; do
      server_dir=$(dirname "$jar")
      if [ -d "$server_dir/plugins" ]; then
        printf '%s\n' "$server_dir"
      fi
    done \
  | awk '!seen[$0]++'
