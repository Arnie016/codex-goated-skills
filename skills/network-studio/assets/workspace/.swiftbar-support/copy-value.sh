#!/usr/bin/env bash
set -euo pipefail

printf '%s' "${1:-}" | pbcopy
