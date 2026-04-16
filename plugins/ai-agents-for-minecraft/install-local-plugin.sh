#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="ai-agents-for-minecraft"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SOURCE="${SCRIPT_DIR}"
REGISTRY_ROOT="${HOME}/.agents/plugins"
PLUGIN_LINK_ROOT="${REGISTRY_ROOT}/plugins"
PLUGIN_LINK_PATH="${PLUGIN_LINK_ROOT}/${PLUGIN_NAME}"
MARKETPLACE_PATH="${REGISTRY_ROOT}/marketplace.json"

AR_LOCAL_ROOT="${HOME}/.codex/plugins/cache/arnav-local/${PLUGIN_NAME}"
export PLUGIN_SOURCE
PLUGIN_VERSION="$(python3 - <<'PY'
import json
import os
from pathlib import Path

manifest_path = Path(os.environ["PLUGIN_SOURCE"]) / ".codex-plugin" / "plugin.json"
print(json.loads(manifest_path.read_text())["version"])
PY
)"
AR_LOCAL_PATH="${AR_LOCAL_ROOT}/${PLUGIN_VERSION}"

mkdir -p "${PLUGIN_LINK_ROOT}" "${AR_LOCAL_ROOT}"

if [ -L "${PLUGIN_LINK_PATH}" ] || [ -e "${PLUGIN_LINK_PATH}" ]; then
  rm -rf "${PLUGIN_LINK_PATH}"
fi

ln -s "${PLUGIN_SOURCE}" "${PLUGIN_LINK_PATH}"

rm -rf "${AR_LOCAL_PATH}"
mkdir -p "${AR_LOCAL_PATH}"
rsync -a --delete "${PLUGIN_SOURCE}/" "${AR_LOCAL_PATH}/"

python3 - <<'PY'
import json
from pathlib import Path

plugin_name = "ai-agents-for-minecraft"
marketplace_path = Path.home() / ".agents" / "plugins" / "marketplace.json"

default_root = {
    "name": "macos-icon-bars-market",
    "interface": {"displayName": "macOS Icon Bars"},
    "plugins": [],
}

if marketplace_path.exists():
    data = json.loads(marketplace_path.read_text())
else:
    data = default_root

data.setdefault("name", "macos-icon-bars-market")
data.setdefault("interface", {})
data["interface"].setdefault("displayName", "macOS Icon Bars")
plugins = data.setdefault("plugins", [])

entry = {
    "name": plugin_name,
    "source": {
        "source": "local",
        "path": f"./plugins/{plugin_name}",
    },
    "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
    },
    "category": "Developer Tools",
}

plugins = [item for item in plugins if item.get("name") != plugin_name]
plugins.append(entry)
data["plugins"] = plugins

marketplace_path.write_text(json.dumps(data, indent=2) + "\n")
PY

echo "Installed ${PLUGIN_NAME} into ${PLUGIN_LINK_PATH}"
echo "Mirrored ${PLUGIN_NAME} into ${AR_LOCAL_PATH}"
echo "Updated marketplace at ${MARKETPLACE_PATH}"
echo "Restart Codex desktop to reload the plugin list."
