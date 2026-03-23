#!/usr/bin/env bash
set -euo pipefail

workspace="${1:-$PWD}"

say() {
  printf '%s\n' "$*"
}

check_tool() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    say "tool:$tool=present"
  else
    say "tool:$tool=missing"
  fi
}

say "workspace:$workspace"

if [[ -d "$workspace/.git" ]]; then
  say "marker:git=present"
else
  say "marker:git=missing"
fi

for marker in package.json pnpm-lock.yaml yarn.lock bun.lockb pyproject.toml requirements.txt uv.lock Cargo.toml go.mod project.yml docker-compose.yml Dockerfile; do
  if [[ -e "$workspace/$marker" ]]; then
    say "marker:$marker=present"
  fi
done

for tool in git node npm pnpm bun python3 pip uv cargo go docker xcodebuild gh; do
  check_tool "$tool"
done
