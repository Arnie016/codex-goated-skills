#!/usr/bin/env python3
"""Thin wrapper around the shared On This Day feed helper."""

from __future__ import annotations

import os
import sys
from pathlib import Path


def main() -> int:
    delegate = Path(__file__).resolve().parents[2] / "on-this-day" / "scripts" / "fetch_on_this_day.py"
    if not delegate.is_file():
        print(f"Error: shared helper not found: {delegate}", file=sys.stderr)
        return 1

    os.execv(sys.executable, [sys.executable, str(delegate), *sys.argv[1:]])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
