#!/usr/bin/env python3

import argparse
import json
import re


def infer_lane(goal: str, explicit: str | None) -> str:
    if explicit:
        return explicit
    lowered = goal.lower()
    if any(token in lowered for token in ["menu bar", "menu-bar", "menubar", "icon", "mac app"]):
        return "menu-bar-app"
    if any(token in lowered for token in ["shortcut", "automate", "applescript"]):
        return "shortcut-pack"
    if any(token in lowered for token in ["script", "command line", "terminal", "one-shot"]):
        return "one-shot-script"
    if any(token in lowered for token in ["dashboard", "window", "board"]):
        return "dashboard"
    if any(token in lowered for token in ["play", "open", "launch", "start"]):
        return "one-shot-script"
    return "support-only"


def infer_focus(goal: str, explicit: str | None) -> str:
    if explicit:
        return explicit
    lowered = goal.lower()
    if re.search(r"\b(ship|launch|release|deploy)\b", lowered):
        return "shipping"
    if re.search(r"\b(study|exam|revise|revision)\b", lowered):
        return "study"
    if re.search(r"\b(game|ranked|tournament|scrim)\b", lowered):
        return "game-time"
    if re.search(r"\b(write|essay|draft)\b", lowered):
        return "writing"
    return "deep-focus"


def infer_service(goal: str, explicit: str | None) -> str:
    if explicit:
        return explicit
    lowered = goal.lower()
    if "spotify" in lowered:
        return "spotify"
    if "apple music" in lowered or "music app" in lowered:
        return "apple-music"
    if "youtube" in lowered:
        return "youtube"
    return "spotify"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normalize a Project Hail Mary request into an implementation brief."
    )
    parser.add_argument("--goal", required=True, help="User request in plain language")
    parser.add_argument("--anthem", default="Sign of the Times", help="Track, playlist, or vibe")
    parser.add_argument(
        "--lane",
        choices=["menu-bar-app", "shortcut-pack", "one-shot-script", "dashboard", "support-only"],
        help="Implementation lane override",
    )
    parser.add_argument(
        "--focus",
        choices=["deep-focus", "shipping", "study", "game-time", "writing"],
        help="Primary rescue mode",
    )
    parser.add_argument(
        "--service",
        choices=["apple-music", "spotify", "youtube", "local-file"],
        help="Preferred music surface",
    )
    parser.add_argument("--minutes", type=int, default=45, help="Default countdown length")
    parser.add_argument(
        "--format", choices=["json", "markdown"], default="markdown", help="Output format"
    )
    args = parser.parse_args()

    lane = infer_lane(args.goal, args.lane)
    focus = infer_focus(args.goal, args.focus)
    service = infer_service(args.goal, args.service)

    brief = {
        "goal": args.goal.strip(),
        "anthem": args.anthem,
        "lane": lane,
        "focus": focus,
        "music_service": service,
        "countdown_minutes": args.minutes,
        "default_shell": "menu bar popover" if lane == "menu-bar-app" else "shell or browser handoff",
        "trust_boundary": "Keep sign-in in the user's browser or apps. Prefer launchers, clipboard text, and visible timers over hidden account automation.",
        "fallback": "If direct playback or posting is unreliable, open the right surface, copy the message, and make the next step obvious.",
    }

    if args.format == "json":
        print(json.dumps(brief, indent=2))
        return

    print("# Project Hail Mary Brief")
    print()
    print(f"- Goal: {brief['goal']}")
    print(f"- Anthem: {brief['anthem']}")
    print(f"- Lane: `{brief['lane']}`")
    print(f"- Focus: `{brief['focus']}`")
    print(f"- Music service: `{brief['music_service']}`")
    print(f"- Countdown: {brief['countdown_minutes']} minutes")
    print(f"- Default shell: {brief['default_shell']}")
    print(f"- Trust boundary: {brief['trust_boundary']}")
    print(f"- Fallback: {brief['fallback']}")


if __name__ == "__main__":
    main()
