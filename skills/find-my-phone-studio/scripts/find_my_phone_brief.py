#!/usr/bin/env python3

import argparse
import json
import re


def infer_action(goal: str, explicit: str | None) -> str:
    if explicit:
        return explicit
    lowered = goal.lower()
    if re.search(r"\b(ring|play sound|ping)\b", lowered):
        return "ring"
    if re.search(r"\b(direction|navigate|map)\b", lowered):
        return "directions"
    if re.search(r"\b(nearby|precision|exact)\b", lowered):
        return "nearby"
    return "locate"


def infer_surface(goal: str, explicit: str | None) -> str:
    if explicit:
        return explicit
    lowered = goal.lower()
    if "browser" in lowered or "icloud" in lowered or "web" in lowered:
        return "browser-helper"
    if "shortcut" in lowered or "applescript" in lowered or "automation" in lowered:
        return "shortcut-helper"
    if "app" in lowered or "menu" in lowered or "icon" in lowered or "mac" in lowered:
        return "menu-bar-app"
    return "support-only"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normalize a find-my-phone request into a build brief."
    )
    parser.add_argument("--goal", required=True, help="User request in plain language")
    parser.add_argument("--device", default="iPhone", help="Primary device type")
    parser.add_argument(
        "--surface",
        choices=["menu-bar-app", "shortcut-helper", "browser-helper", "support-only"],
        help="Implementation lane override",
    )
    parser.add_argument(
        "--action",
        choices=["locate", "ring", "directions", "nearby"],
        help="Primary action override",
    )
    parser.add_argument(
        "--format", choices=["json", "markdown"], default="markdown", help="Output format"
    )
    args = parser.parse_args()

    brief = {
        "goal": args.goal.strip(),
        "device": args.device,
        "surface": infer_surface(args.goal, args.surface),
        "primary_action": infer_action(args.goal, args.action),
        "default_shell": "menu bar popover"
        if infer_surface(args.goal, args.surface) == "menu-bar-app"
        else "none",
        "trust_boundary": "Prefer Apple-managed sign-in and device actions. Avoid custom credential storage.",
        "fallback": "If direct automation is unavailable, open the Apple-managed surface and optimize time-to-action.",
    }

    if args.format == "json":
        print(json.dumps(brief, indent=2))
        return

    print("# Find My Phone Brief")
    print()
    print(f"- Goal: {brief['goal']}")
    print(f"- Device: {brief['device']}")
    print(f"- Lane: `{brief['surface']}`")
    print(f"- Primary action: `{brief['primary_action']}`")
    print(f"- Default shell: {brief['default_shell']}")
    print(f"- Trust boundary: {brief['trust_boundary']}")
    print(f"- Fallback: {brief['fallback']}")


if __name__ == "__main__":
    main()
