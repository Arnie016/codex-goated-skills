#!/usr/bin/env python3

import argparse
import json
import re


def is_mac_hub_request(goal: str) -> bool:
    lowered = goal.lower()
    hub_terms = [
        "control my xbox stuff",
        "xbox stuff from my mac",
        "xbox hub",
        "xbox control center",
        "control center",
        "dashboard",
        "launcher",
    ]
    mentions_mac = any(token in lowered for token in [" mac", "mac ", "menu", "menubar", "status bar", "app"])
    mentions_hub_intent = re.search(r"\b(control|hub|launcher|dashboard)\b", lowered) is not None
    return any(term in lowered for term in hub_terms) or (
        mentions_mac and "xbox" in lowered and mentions_hub_intent
    )


def infer_focus(goal: str, explicit: str | None) -> str:
    if explicit:
        return explicit
    lowered = goal.lower()
    if re.search(r"\b(controller|bluetooth|pair|gamepad|elite|adaptive)\b", lowered):
        return "controller"
    if is_mac_hub_request(goal):
        return "controller"
    if re.search(r"\b(capture|captures|clip|clips|recording|recordings|screenshot|share)\b", lowered):
        return "captures"
    if re.search(r"\b(remote play|remoteplay|stream from my console|play from my xbox)\b", lowered):
        return "remote-play"
    if re.search(r"\b(cloud gaming|game pass|xbox.com/play|browser play|stream games)\b", lowered):
        return "cloud-gaming"
    if re.search(r"\b(account|subscription|billing|profile|store|redeem)\b", lowered):
        return "account"
    return "console-help"


def infer_lane(goal: str, explicit: str | None, focus: str) -> str:
    if explicit:
        return explicit
    lowered = goal.lower()
    if is_mac_hub_request(goal):
        return "menu-bar-app"
    if focus == "controller":
        if any(token in lowered for token in ["menu", "menubar", "status bar", "dashboard", "launcher", "app"]):
            return "menu-bar-app"
        return "controller-setup"
    if focus == "captures":
        return "capture-helper"
    if "menu" in lowered or "menubar" in lowered or "status bar" in lowered or "app" in lowered:
        return "menu-bar-app"
    if focus in {"cloud-gaming", "remote-play", "account"}:
        return "browser-helper"
    return "support-only"


def surfaces_for_focus(focus: str) -> list[str]:
    if focus == "cloud-gaming":
        return [
            "xbox.com/play in the user's browser",
            "Signed-in Microsoft session",
            "Optional controller pairing on macOS",
        ]
    if focus == "remote-play":
        return [
            "xbox.com/play remote play entry",
            "Console with remote features enabled",
            "Signed-in Microsoft session",
        ]
    if focus == "controller":
        return [
            "macOS Bluetooth settings",
            "Apple's supported Xbox controller pairing flow",
            "Microsoft firmware-update guidance if needed",
        ]
    if focus == "captures":
        return [
            "User-exported or downloaded capture files",
            "Local Mac folder workflow",
            "Official Microsoft or Xbox share surface when needed",
        ]
    if focus == "account":
        return [
            "account.microsoft.com or account.xbox.com",
            "Xbox.com store or subscription pages",
            "Signed-in browser session",
        ]
    return [
        "Xbox support pages",
        "Console settings",
        "Signed-in browser session when account context is required",
    ]


def boundary_for_focus(focus: str) -> str:
    if focus == "controller":
        return "Keep pairing in Apple settings and firmware updates in Microsoft's documented surfaces."
    if focus == "captures":
        return "Automate local organization after export or download, not private capture-library APIs."
    if focus in {"cloud-gaming", "remote-play"}:
        return "Keep sign-in and streaming inside official Xbox browser surfaces instead of custom auth flows."
    if focus == "account":
        return "Use Microsoft-owned account surfaces rather than storing credentials or scraping unsupported endpoints."
    return "Do not claim direct Xbox console-control APIs unless the current official docs prove they exist."


def fallback_for_focus(focus: str) -> str:
    if focus == "remote-play":
        return "If remote play is not enabled or unavailable, open the console instructions and fall back to cloud gaming when appropriate."
    if focus == "controller":
        return "If pairing fails, open Bluetooth troubleshooting and firmware guidance instead of building custom low-level tooling."
    if focus == "captures":
        return "If the media is not on disk yet, hand off to the official export or share surface and resume local automation after download."
    return "If direct automation is unavailable, open the official Xbox or Microsoft surface and optimize time-to-action."


def shell_for_lane(lane: str) -> str:
    if lane == "menu-bar-app":
        return "existing Xbox Studio menu bar app"
    if lane == "browser-helper":
        return "browser launcher"
    if lane == "controller-setup":
        return "setup guide"
    if lane == "capture-helper":
        return "local folder helper"
    return "none"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normalize an Xbox request into a realistic macOS build brief."
    )
    parser.add_argument("--goal", required=True, help="User request in plain language")
    parser.add_argument("--device", default="Xbox console", help="Primary device or target")
    parser.add_argument(
        "--lane",
        choices=[
            "menu-bar-app",
            "browser-helper",
            "controller-setup",
            "capture-helper",
            "support-only",
        ],
        help="Implementation lane override",
    )
    parser.add_argument(
        "--focus",
        choices=[
            "cloud-gaming",
            "remote-play",
            "controller",
            "captures",
            "account",
            "console-help",
        ],
        help="Primary task override",
    )
    parser.add_argument(
        "--format", choices=["json", "markdown"], default="markdown", help="Output format"
    )
    args = parser.parse_args()

    focus = infer_focus(args.goal, args.focus)
    lane = infer_lane(args.goal, args.lane, focus)
    brief = {
        "goal": args.goal.strip(),
        "device": args.device,
        "focus": focus,
        "lane": lane,
        "default_shell": shell_for_lane(lane),
        "supported_surfaces": surfaces_for_focus(focus),
        "trust_boundary": boundary_for_focus(focus),
        "fallback": fallback_for_focus(focus),
        "recommended_app": "apps/xbox-studio" if lane == "menu-bar-app" else None,
    }

    if args.format == "json":
        print(json.dumps(brief, indent=2))
        return

    print("# Xbox Brief")
    print()
    print(f"- Goal: {brief['goal']}")
    print(f"- Device: {brief['device']}")
    print(f"- Focus: `{brief['focus']}`")
    print(f"- Lane: `{brief['lane']}`")
    print(f"- Default shell: {brief['default_shell']}")
    if brief["recommended_app"]:
        print(f"- Recommended app: `{brief['recommended_app']}`")
    print("- Supported surfaces:")
    for surface in brief["supported_surfaces"]:
        print(f"  - {surface}")
    print(f"- Trust boundary: {brief['trust_boundary']}")
    print(f"- Fallback: {brief['fallback']}")


if __name__ == "__main__":
    main()
