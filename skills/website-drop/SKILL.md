---
name: website-drop
description: Publish a local website or app with the shortest sensible path to a live URL. Use when Codex needs to prepare a web project for deployment, choose a simple hosting path, and get the user from local code to a shareable link quickly.
---

# Website Drop

Use this skill when the user wants a website or front-end project to go live fast with a clear deployment path.

## Quick Start

1. Detect the app type and current build command before changing deployment config.
2. Prefer the lightest hosting flow that matches the project and user constraints.
3. Keep the goal simple: build, deploy, and return the live link.
4. Add platform-specific config only when the target host actually needs it.
5. If a deployment-specific skill already fits the stack, route to it instead of reinventing the flow.

## Workflow

### Choose The Path

- For static or framework sites, prefer straightforward hosts such as Vercel, Netlify, or Cloudflare when they match the project.
- If the user names a platform, align the deployment flow to that platform instead of abstracting it away.
- If deployment depends on environment variables, call that out before shipping.
- If the repo already contains deployment config, preserve it and finish the flow instead of replacing it.

### Prepare The Project

- Confirm the install, build, and output directory commands from the existing project files.
- Keep deployment config as small as possible.
- Avoid adding hosting-specific files that duplicate what the framework already provides.
- Verify that the built output actually exists before claiming the site is ready to deploy.

### Required Deliverables

- One clear hosting recommendation with a short reason.
- The exact build command and output directory.
- The minimum config or command needed to deploy.
- The resulting live URL or the exact user handoff needed to get it.

### Routing Rules

- If the user explicitly wants Vercel, use the `vercel-deploy` skill when available.
- If the user explicitly wants Netlify, use the `netlify-deploy` skill when available.
- If the user explicitly wants Cloudflare, use the `cloudflare-deploy` skill when available.
- If no host is named, choose the simplest stable path based on the project and explain why.

### Editing Guidance

- Optimize for one repeatable deploy flow, not every possible host.
- Keep docs short and action-oriented.
- Return the exact command or handoff needed to get a live URL.
- Avoid adding deployment clutter for hosts the user is not using.

## Resources

- `agents/openai.yaml`: UI metadata and default invocation prompt.
- `assets/`: branded icons for repo listings and skill chips.
- `references/deploy-heuristics.md`: quick matrix for choosing a host and minimizing config.
