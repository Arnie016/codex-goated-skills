#!/usr/bin/env python3
"""Compatibility wrapper for the generated skill catalog index."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    catalog_builder = repo_root / "scripts" / "build-catalog.py"
    if not catalog_builder.is_file():
        print(f"Error: missing catalog builder: {catalog_builder}", file=sys.stderr)
        return 1

    return subprocess.run(
        [sys.executable, str(catalog_builder), "--repo-dir", str(repo_root), *sys.argv[1:]],
        check=False,
    ).returncode


if __name__ == "__main__":
    raise SystemExit(main())
