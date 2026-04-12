#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run_xbox_studio.sh [--repo-root PATH] [--build-only]

Builds the Xbox Studio macOS app from a codex-goated-skills workspace and
opens the built app by default.
EOF
}

repo_root=""
build_only=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      [[ $# -ge 2 ]] || { echo "Missing value for --repo-root" >&2; exit 1; }
      repo_root="$2"
      shift 2
      ;;
    --build-only)
      build_only=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

find_repo_root() {
  local candidate
  candidate="$(cd "${1:-.}" && pwd)"

  while true; do
    if [[ -f "$candidate/apps/xbox-studio/project.yml" && -d "$candidate/apps/xbox-studio/XboxStudio.xcodeproj" ]]; then
      echo "$candidate"
      return 0
    fi

    if [[ "$candidate" == "/" ]]; then
      return 1
    fi

    candidate="$(dirname "$candidate")"
  done
}

if [[ -n "$repo_root" ]]; then
  repo_root="$(cd "$repo_root" && pwd)"
else
  repo_root="$(find_repo_root "$PWD")" || {
    echo "Could not find a codex-goated-skills workspace with apps/xbox-studio from $PWD" >&2
    exit 1
  }
fi

app_dir="$repo_root/apps/xbox-studio"
project_path="$app_dir/XboxStudio.xcodeproj"
derived_root="${TMPDIR:-/tmp}/xbox-studio-runner"
derived_data="$derived_root/derived-data"
app_path="$derived_data/Build/Products/Debug/XboxStudio.app"

mkdir -p "$derived_root"

echo "Building Xbox Studio from $app_dir"
xcodebuild \
  -project "$project_path" \
  -scheme XboxStudio \
  -configuration Debug \
  -derivedDataPath "$derived_data" \
  build \
  CODE_SIGNING_ALLOWED=NO

if [[ ! -d "$app_path" ]]; then
  echo "Build completed but $app_path was not found." >&2
  exit 1
fi

echo "Built app: $app_path"

if [[ "$build_only" -eq 0 ]]; then
  open "$app_path"
fi
