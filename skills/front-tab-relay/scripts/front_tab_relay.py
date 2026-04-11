#!/usr/bin/env python3
"""Read the visible front browser tab on macOS and format it for handoff."""

from __future__ import annotations

import argparse
import json
import subprocess
from urllib.parse import urlparse

SUPPORTED_BROWSERS = {
    'Safari': 'safari',
    'Google Chrome': 'chrome',
    'Brave Browser': 'chrome',
    'Arc': 'chrome',
    'Microsoft Edge': 'chrome',
}


def run_osascript(script: str) -> str:
    try:
        result = subprocess.run(
            ['osascript', '-e', script],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as error:
        raise SystemExit('osascript is required on macOS for this helper.') from error
    except subprocess.CalledProcessError as error:
        message = (error.stderr or error.stdout or '').strip() or 'AppleScript request failed.'
        raise SystemExit(message)
    return result.stdout.strip()


def frontmost_app() -> str:
    script = '''
    tell application "System Events"
        set frontApp to name of first application process whose frontmost is true
    end tell
    return frontApp
    '''
    return run_osascript(script)


def current_tab(browser: str) -> dict[str, str]:
    browser_kind = SUPPORTED_BROWSERS.get(browser)
    if not browser_kind:
        supported = ', '.join(sorted(SUPPORTED_BROWSERS))
        raise SystemExit(f'Unsupported browser: {browser}. Supported browsers: {supported}')

    if browser_kind == 'safari':
        script = f'''
        tell application "{browser}"
            if not (exists front window) then error "{browser} has no open window."
            set tabTitle to name of current tab of front window
            set tabURL to URL of current tab of front window
            return tabTitle & linefeed & tabURL
        end tell
        '''
    else:
        script = f'''
        tell application "{browser}"
            if (count of windows) is 0 then error "{browser} has no open window."
            set tabTitle to title of active tab of front window
            set tabURL to URL of active tab of front window
            return tabTitle & linefeed & tabURL
        end tell
        '''

    output = run_osascript(script)
    if not output:
        raise SystemExit(f'No tab data returned from {browser}.')

    parts = output.splitlines()
    if len(parts) < 2:
        raise SystemExit(f'Unexpected tab payload from {browser}: {output!r}')

    title = parts[0].strip()
    url = parts[1].strip()
    domain = urlparse(url).netloc or ''
    return {
        'browser': browser,
        'title': title,
        'url': url,
        'domain': domain,
    }


def format_payload(tab: dict[str, str], style: str) -> str:
    title = tab['title']
    url = tab['url']
    domain = tab['domain'] or 'unknown domain'

    if style == 'json':
        return json.dumps(tab, indent=2, ensure_ascii=False)
    if style == 'plain':
        return f'{title}\n{url}'
    if style == 'markdown':
        return f'[{title}]({url})'
    if style == 'ticket':
        return f'- {title}\n  URL: {url}\n  Domain: {domain}'
    if style == 'prompt':
        return f'Context link\nTitle: {title}\nURL: {url}\nWhy it matters: add the short relevance note here.'
    if style == 'slack':
        safe_title = title.replace('|', '-')
        return f'<{url}|{safe_title}>'
    raise SystemExit(f'Unsupported format: {style}')


def copy_text(text: str) -> None:
    subprocess.run(['pbcopy'], input=text, text=True, check=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['current', 'copy'], nargs='?', default='current')
    parser.add_argument('--browser', help='Browser name override. Defaults to the frontmost supported app.')
    parser.add_argument(
        '--format',
        default='json',
        choices=['json', 'plain', 'markdown', 'ticket', 'prompt', 'slack'],
        help='Output format for the current tab payload.',
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    browser = args.browser or frontmost_app()
    tab = current_tab(browser)
    text = format_payload(tab, args.format)
    if args.command == 'copy':
        copy_text(text)
    print(text)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
