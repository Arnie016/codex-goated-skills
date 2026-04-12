# Supported Surfaces

Use this reference when shaping a realistic Hail Mary ritual on macOS.

## Safe Defaults

- Launch the user's existing music surface instead of pretending to ship or embed the song.
- Open the user's own work surfaces with `open` and real URLs or app names.
- Copy a status line into the clipboard with `pbcopy` instead of auto-sending it.
- Show a finish time, countdown, or local notification rather than promising hidden scheduling magic.

## Music Handoff

- Apple Music: good for search or playlist handoff in the browser or Music app.
- Spotify: good for search or playlist handoff in the browser or Spotify app.
- YouTube: good universal fallback when the user just wants a fast playable result.
- Local file: useful when the user already has the anthem on disk and wants the shortest path.

Treat playback itself as user-session dependent. The safest claim is that the launcher opens the right surface quickly, not that it can always bypass sign-in, subscription, or autoplay restrictions.

## Work Surfaces

Common Hail Mary launch targets:

- GitHub repo, pull request, issue board, or CI dashboard
- Notion, Google Docs, or a launch checklist
- Slack, Telegram, Discord, or another comms app
- Figma, Linear, Jira, or a product board
- A local IDE, terminal, or design tool

Prefer an explicit list over guesswork. If the user gives only a vague goal, include the repo, notes, and the primary ticket board first.

## Countdown Patterns

- One-shot script: print `Finish by 6:30 PM` and optionally fire a local notification.
- Menu bar app: keep a visible timer or deadline badge.
- Dashboard: show the remaining time beside the blocker list.

Avoid claiming deep integration with system Focus modes or reminders unless the actual implementation proves it.

## Communication Patterns

- Clipboard-first is the safest default.
- Prefilled browser URLs can work for some services, but authentication and compose surfaces vary.
- If a message absolutely matters, let the user review it before sending.

## Phrasing To Avoid

- "It will directly control your Spotify account"
- "It can silently send Slack messages"
- "It will always start playback instantly"
- "It can switch Focus modes on any Mac without prompts"

Better phrasing:

- "It can open your preferred music surface on the right song or search."
- "It can copy a heads-down update and open the chat surface."
- "It can show or calculate the finish time for the rescue pass."
