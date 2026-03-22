#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shlex
import shutil
import stat
import sys
from pathlib import Path


SKILL_DIR = Path(__file__).resolve().parent.parent
TEMPLATE_DIR = SKILL_DIR / "assets" / "workspace"
DEFAULT_WORKSPACE = Path.home() / "Network Studio"
DEFAULT_PLUGIN_NAME = "network-studio.1m.sh"
PRESERVE_ON_UPDATE = {
    Path("device-labels.json"),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install or update a portable Network Studio workspace.",
    )
    parser.add_argument(
        "workspace",
        nargs="?",
        default=str(DEFAULT_WORKSPACE),
        help="Destination directory for the installed workspace.",
    )
    parser.add_argument(
        "--swiftbar-plugins-dir",
        help="Optional SwiftBar plugins directory for writing a thin wrapper plugin.",
    )
    parser.add_argument(
        "--plugin-name",
        default=DEFAULT_PLUGIN_NAME,
        help=f"Filename for the SwiftBar wrapper (default: {DEFAULT_PLUGIN_NAME}).",
    )
    return parser.parse_args()


def ensure_executable(path: Path) -> None:
    current_mode = path.stat().st_mode
    path.chmod(current_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def copy_workspace(template_dir: Path, workspace_dir: Path) -> None:
    if not template_dir.exists():
        raise FileNotFoundError(f"Missing template directory: {template_dir}")

    workspace_dir.mkdir(parents=True, exist_ok=True)
    (workspace_dir / "logs").mkdir(parents=True, exist_ok=True)

    for source in sorted(template_dir.rglob("*")):
        relative = source.relative_to(template_dir)
        destination = workspace_dir / relative

        if source.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
            continue

        if relative in PRESERVE_ON_UPDATE and destination.exists():
            continue

        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        if destination.suffix in {".sh", ".py"}:
            ensure_executable(destination)


def write_wrapper(workspace_dir: Path, plugins_dir: Path, plugin_name: str) -> Path:
    plugins_dir.mkdir(parents=True, exist_ok=True)
    plugin_path = plugins_dir / plugin_name
    workspace_plugin = (workspace_dir / "swiftbar" / "network-monitor.1m.sh").resolve()
    plugin_path.write_text(
        "#!/usr/bin/env bash\n"
        "set -euo pipefail\n\n"
        f"bash {shlex.quote(str(workspace_plugin))}\n"
    )
    ensure_executable(plugin_path)
    return plugin_path


def main() -> int:
    args = parse_args()
    workspace_dir = Path(args.workspace).expanduser().resolve()

    if workspace_dir.exists() and not workspace_dir.is_dir():
        print(f"Workspace path is not a directory: {workspace_dir}", file=sys.stderr)
        return 1

    copy_workspace(TEMPLATE_DIR, workspace_dir)

    wrapper_path: Path | None = None
    if args.swiftbar_plugins_dir:
        plugins_dir = Path(args.swiftbar_plugins_dir).expanduser().resolve()
        wrapper_path = write_wrapper(workspace_dir, plugins_dir, args.plugin_name)

    open_cmd = f"bash {shlex.quote(str(workspace_dir / '.swiftbar-support' / 'open-network-studio.sh'))}"
    watch_cmd = f"bash {shlex.quote(str(workspace_dir / 'network-watch.sh'))}"

    print(f"Installed workspace: {workspace_dir}")
    print(f"SwiftBar plugin folder: {workspace_dir / 'swiftbar'}")
    if wrapper_path:
        print(f"SwiftBar wrapper: {wrapper_path}")
    print(f"Open dashboard: {open_cmd}")
    print(f"Run watcher: {watch_cmd}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
