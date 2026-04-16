#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONVERTER="$SKILL_DIR/scripts/dark_pdf.py"
WORKFLOW_MAP="$SKILL_DIR/references/workflow-map.md"

usage() {
  cat <<'EOF'
Usage:
  run_dark_pdf_studio.sh <doctor|inspect|convert|validate> [args...]

Examples:
  bash scripts/run_dark_pdf_studio.sh doctor
  bash scripts/run_dark_pdf_studio.sh inspect
  bash scripts/run_dark_pdf_studio.sh convert --input input.pdf --output output-dark.pdf
  bash scripts/run_dark_pdf_studio.sh convert input.pdf output-dark.pdf --theme midnight --dpi 180
  bash scripts/run_dark_pdf_studio.sh validate
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_python() {
  command -v python3 >/dev/null 2>&1 || die "python3 is required."
}

python_module_status() {
  python3 - <<'PY'
import importlib

missing = []
for module, label in [("fitz", "PyMuPDF"), ("PIL.Image", "Pillow")]:
    try:
        importlib.import_module(module)
    except Exception:
        missing.append(label)

if missing:
    print("missing: " + ", ".join(missing))
else:
    print("ready")
PY
}

document_backend_status() {
  if command -v textutil >/dev/null 2>&1; then
    printf 'textutil'
    return 0
  fi

  if command -v soffice >/dev/null 2>&1; then
    printf 'soffice'
    return 0
  fi

  if command -v libreoffice >/dev/null 2>&1; then
    printf 'libreoffice'
    return 0
  fi

  printf 'missing'
}

doctor() {
  require_python
  printf 'Skill dir: %s\n' "$SKILL_DIR"
  printf 'Converter: %s\n' "$CONVERTER"
  printf 'Workflow map: %s\n' "$WORKFLOW_MAP"
  printf 'python3: %s\n' "$(python3 --version 2>&1)"
  printf 'Python modules: %s\n' "$(python_module_status)"
  printf 'Document backend: %s\n' "$(document_backend_status)"
}

inspect() {
  cat <<EOF
Skill: dark-pdf-studio
Main files:
- $SKILL_DIR/SKILL.md
- $SKILL_DIR/agents/openai.yaml
- $WORKFLOW_MAP
- $CONVERTER

Command lanes:
- doctor: prerequisites and backend availability
- inspect: file map and workflow orientation
- convert: dark-background PDF conversion
- validate: py_compile plus CLI help check
EOF
}

validate() {
  require_python
  python3 -m py_compile "$CONVERTER"
  python3 "$CONVERTER" --help >/dev/null
  printf 'Validation OK: dark_pdf.py compiles and exposes help.\n'
}

convert() {
  require_python

  local input=""
  local output=""
  local theme="graphite"
  local dpi="160"
  local positionals=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --input)
        [[ $# -ge 2 ]] || die "--input requires a path"
        input="$2"
        shift 2
        ;;
      --output)
        [[ $# -ge 2 ]] || die "--output requires a path"
        output="$2"
        shift 2
        ;;
      --theme)
        [[ $# -ge 2 ]] || die "--theme requires a value"
        theme="$2"
        shift 2
        ;;
      --dpi)
        [[ $# -ge 2 ]] || die "--dpi requires a value"
        dpi="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          positionals+=("$1")
          shift
        done
        ;;
      -*)
        die "Unknown option: $1"
        ;;
      *)
        positionals+=("$1")
        shift
        ;;
    esac
  done

  if [[ -z "$input" && ${#positionals[@]} -ge 1 ]]; then
    input="${positionals[0]}"
  fi

  if [[ -z "$output" && ${#positionals[@]} -ge 2 ]]; then
    output="${positionals[1]}"
  fi

  if [[ ${#positionals[@]} -gt 2 ]]; then
    die "Pass at most two positional paths: input and output"
  fi

  [[ -n "$input" ]] || die "Missing input path"
  [[ -n "$output" ]] || die "Missing output path"
  [[ -f "$input" ]] || die "Input file not found: $input"

  mkdir -p "$(dirname "$output")"
  exec python3 "$CONVERTER" --input "$input" --output "$output" --theme "$theme" --dpi "$dpi"
}

command="${1:-}"
[[ -n "$command" ]] || {
  usage
  exit 1
}
shift || true

case "$command" in
  doctor)
    doctor "$@"
    ;;
  inspect)
    inspect "$@"
    ;;
  convert)
    convert "$@"
    ;;
  validate)
    validate "$@"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    die "Unknown command: $command"
    ;;
esac
