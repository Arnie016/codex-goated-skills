#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

PLUGIN_NAME="macos-icon-bars"
SOURCE_MANIFEST="${REPO_ROOT}/plugins/${PLUGIN_NAME}/.codex-plugin/plugin.json"
SOURCE_SKILLS_DIR="${REPO_ROOT}/skills"

TARGET_ROOT="${HOME}/plugins"
TARGET_PLUGIN_DIR="${TARGET_ROOT}/${PLUGIN_NAME}"
TARGET_MANIFEST_DIR="${TARGET_PLUGIN_DIR}/.codex-plugin"
TARGET_MANIFEST="${TARGET_MANIFEST_DIR}/plugin.json"

AGENTS_DIR="${HOME}/.agents/plugins"
AGENTS_PLUGIN_DIR="${AGENTS_DIR}/plugins"
AGENTS_PLUGIN_LINK="${AGENTS_PLUGIN_DIR}/${PLUGIN_NAME}"
MARKETPLACE_JSON="${AGENTS_DIR}/marketplace.json"

if [[ ! -f "${SOURCE_MANIFEST}" ]]; then
  echo "Missing plugin manifest at ${SOURCE_MANIFEST}" >&2
  exit 1
fi

if [[ ! -d "${SOURCE_SKILLS_DIR}" ]]; then
  echo "Missing skills directory at ${SOURCE_SKILLS_DIR}" >&2
  exit 1
fi

mkdir -p "${TARGET_MANIFEST_DIR}" "${AGENTS_PLUGIN_DIR}"

cp "${SOURCE_MANIFEST}" "${TARGET_MANIFEST}"
rsync -a --delete \
  --exclude '__pycache__' \
  --exclude '.DS_Store' \
  "${SOURCE_SKILLS_DIR}/" "${TARGET_PLUGIN_DIR}/skills/"

if [[ -L "${AGENTS_PLUGIN_LINK}" ]]; then
  rm "${AGENTS_PLUGIN_LINK}"
elif [[ -e "${AGENTS_PLUGIN_LINK}" ]]; then
  echo "Refusing to replace non-symlink plugin path: ${AGENTS_PLUGIN_LINK}" >&2
  exit 1
fi

ln -s "${TARGET_PLUGIN_DIR}" "${AGENTS_PLUGIN_LINK}"

python3 - "${MARKETPLACE_JSON}" <<'PY'
import json
import pathlib
import sys

marketplace_path = pathlib.Path(sys.argv[1])
entry = {
    "name": "macos-icon-bars",
    "source": {
        "source": "local",
        "path": "./plugins/macos-icon-bars",
    },
    "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
    },
    "category": "Productivity",
}

if marketplace_path.exists():
    try:
        data = json.loads(marketplace_path.read_text())
    except Exception as exc:
        raise SystemExit(f"Could not parse existing marketplace file at {marketplace_path}: {exc}")
else:
    data = {
        "name": "local-market",
        "interface": {
            "displayName": "Local Plugins",
        },
        "plugins": [],
    }

if not isinstance(data, dict):
    raise SystemExit(f"Marketplace file at {marketplace_path} is not a JSON object")

plugins = data.get("plugins")
if not isinstance(plugins, list):
    plugins = []
    data["plugins"] = plugins

updated = False
for index, plugin in enumerate(plugins):
    if isinstance(plugin, dict) and plugin.get("name") == entry["name"]:
        plugins[index] = entry
        updated = True
        break

if not updated:
    plugins.append(entry)

if "name" not in data or not isinstance(data["name"], str):
    data["name"] = "local-market"

interface = data.get("interface")
if not isinstance(interface, dict):
    interface = {}
    data["interface"] = interface
interface.setdefault("displayName", "Local Plugins")

marketplace_path.parent.mkdir(parents=True, exist_ok=True)
marketplace_path.write_text(json.dumps(data, indent=2) + "\n")
PY

echo "Installed ${PLUGIN_NAME} into ${TARGET_PLUGIN_DIR}"
echo "Marketplace registered at ${MARKETPLACE_JSON}"
echo "Next: fully quit and reopen Codex, then ask: What can macOS Icon Bars do?"
