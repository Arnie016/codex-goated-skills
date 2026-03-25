#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${WORKSPACE:-$SCRIPT_DIR/../../../apps/skillbar}"
PROJECT_NAME="SkillBar.xcodeproj"
SCHEME="SkillBar"

usage() {
  cat <<EOF
Usage:
  bash run_skillbar.sh <doctor|generate|build|test|run>
EOF
}

[[ $# -ge 1 ]] || { usage; exit 1; }
COMMAND="$1"

cd "$WORKSPACE"

case "$COMMAND" in
  doctor)
    command -v xcodegen >/dev/null 2>&1 || { echo "xcodegen is required."; exit 1; }
    command -v xcodebuild >/dev/null 2>&1 || { echo "xcodebuild is required."; exit 1; }
    echo "SkillBar workspace looks ready."
    ;;
  generate)
    xcodegen generate
    ;;
  build)
    xcodegen generate >/dev/null
    xcodebuild -project "$PROJECT_NAME" -scheme "$SCHEME" -configuration Debug -sdk macosx build
    ;;
  test)
    xcodegen generate >/dev/null
    xcodebuild -project "$PROJECT_NAME" -scheme "$SCHEME" -configuration Debug -sdk macosx test
    ;;
  run)
    xcodegen generate >/dev/null
    xcodebuild -project "$PROJECT_NAME" -scheme "$SCHEME" -configuration Debug -sdk macosx build >/dev/null
    open "$HOME/Library/Developer/Xcode/DerivedData/SkillBar-"*"/Build/Products/Debug/SkillBar.app"
    ;;
  *)
    usage
    exit 1
    ;;
esac
