# Deploy Heuristics

Choose the host with the fewest moving parts that still matches the project.

## Vercel

Best for:

- Next.js
- React or Vite apps
- projects that need instant preview URLs

Prefer when the repo already looks Vercel-friendly or the user says "just make it live fast."

## Netlify

Best for:

- static sites
- Vite, Astro, Eleventy, or simple front-end builds
- teams that want a simple dashboard and forms or edge add-ons later

## Cloudflare

Best for:

- static or edge-heavy deployments
- Workers-based sites
- projects already using Cloudflare products

## Before You Claim It Is Ready

- verify the app actually installs
- verify install command
- verify build command
- verify output directory
- verify env vars if required
- verify the deployment target matches the framework
