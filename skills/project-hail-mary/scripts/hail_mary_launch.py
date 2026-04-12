#!/usr/bin/env python3

import argparse
import datetime as dt
import shlex
import subprocess
from typing import Iterable
from urllib.parse import quote_plus


def music_url(service: str, anthem: str) -> str:
    query = quote_plus(anthem)
    if service == "apple-music":
        return f"https://music.apple.com/us/search?term={query}"
    if service == "youtube":
        return f"https://www.youtube.com/results?search_query={query}"
    if service == "local-file":
        return anthem
    return f"https://open.spotify.com/search/{query}"


def run_open(target: str, is_app: bool = False) -> None:
    cmd = ["open"]
    if is_app:
        cmd.extend(["-a", target])
    else:
        cmd.append(target)
    subprocess.run(cmd, check=False)


def copy_status(text: str) -> None:
    subprocess.run(["pbcopy"], input=text, text=True, check=False)


def notify(title: str, message: str) -> None:
    script = f'display notification {message!r} with title {title!r}'
    subprocess.run(["osascript", "-e", script], check=False)


def iter_clean(values: Iterable[str]) -> Iterable[str]:
    for value in values:
        cleaned = value.strip()
        if cleaned:
            yield cleaned


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Launch a small Project Hail Mary rescue ritual on macOS."
    )
    parser.add_argument("--anthem", default="Sign of the Times", help="Track, playlist, or local file")
    parser.add_argument(
        "--service",
        choices=["apple-music", "spotify", "youtube", "local-file"],
        default="spotify",
        help="Music surface to open",
    )
    parser.add_argument(
        "--app",
        action="append",
        default=[],
        help='App name to open, for example --app "Visual Studio Code"',
    )
    parser.add_argument(
        "--url",
        action="append",
        default=[],
        help='URL to open, for example --url "https://github.com"',
    )
    parser.add_argument("--minutes", type=int, default=45, help="Countdown length")
    parser.add_argument(
        "--status",
        default="",
        help="Status line to copy into the clipboard",
    )
    parser.add_argument(
        "--notify",
        action="store_true",
        help="Show a local notification with the finish time",
    )
    args = parser.parse_args()

    finish = dt.datetime.now() + dt.timedelta(minutes=max(1, args.minutes))
    finish_text = finish.strftime("%-I:%M %p")
    status_text = args.status or (
        f"Heads down for {max(1, args.minutes)} minutes. Shipping the last blocker now."
    )

    run_open(music_url(args.service, args.anthem))

    for app in iter_clean(args.app):
        run_open(app, is_app=True)

    for url in iter_clean(args.url):
        run_open(url)

    copy_status(status_text)

    print("Project Hail Mary launched.")
    print(f"Anthem: {args.anthem}")
    print(f"Music service: {args.service}")
    if args.app:
        print("Apps:")
        for app in iter_clean(args.app):
            print(f"- {app}")
    if args.url:
        print("URLs:")
        for url in iter_clean(args.url):
            print(f"- {url}")
    print(f"Finish by: {finish_text}")
    print(f"Clipboard status: {status_text}")
    print()
    print("Example follow-up:")
    print(
        shlex.join(
            [
                "python3",
                "scripts/hail_mary_launch.py",
                "--anthem",
                args.anthem,
                "--service",
                args.service,
                "--minutes",
                str(args.minutes),
            ]
        )
    )

    if args.notify:
        notify("Project Hail Mary", f"Finish this pass by {finish_text}.")


if __name__ == "__main__":
    main()
