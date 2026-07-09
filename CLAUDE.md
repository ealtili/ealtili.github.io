# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-page professional portfolio for Eray ALTILI, deployed as a static site to GitHub Pages. There is no build step, framework, or package manager — the entire site is one self-contained file.

## Architecture

- `index.html` — the entire site. HTML structure, CSS (in a `<style>` block), and JS (in a `<script>` block) all live in this one file. There are no other source files, no bundler, and no external dependencies (fonts, JS libraries, CSS frameworks) — everything is inlined or system-native.
  - **Theming**: light/dark mode is driven purely by `@media (prefers-color-scheme: dark)` CSS variables (`--bg`, `--text`, `--muted`, `--border`, etc. redefined in the dark block). There is no manual theme toggle — do not add JS-based theme switching without discussing it first, as this is an intentional design choice.
  - **i18n**: bilingual EN/TR content lives in a single JS object (`i18n = { en: {...}, tr: {...} }`) keyed by the same dotted keys used in each element's `data-i18n="..."` attribute. Language switching re-renders via `innerHTML` swap, no page reload. Default language is detected from `localStorage` (key `eray-altili-lang`), falling back to `navigator.language`. When adding new copy, you must add the key to **both** the `en` and `tr` dictionaries and to the corresponding `data-i18n` attribute in the HTML — missed keys silently show stale/English text.
  - All bullet/metric text that needs inline `<strong>`/`<span>` markup is stored as HTML strings in the i18n dictionaries (not escaped), since it's set via `innerHTML`.
  - **Meta tags**: favicon and Open Graph/Twitter Card tags live inline in `<head>`. The favicon is a hand-rolled SVG `data:` URI (no external file, no CDN) to preserve the zero-external-dependency architecture — keep this pattern for any future icon/image assets rather than adding a binary file or remote URL. `og:url` and `og:image` are currently left as a `TODO` comment pending a live URL and headshot/logo image.
  - **Contact links**: LinkedIn/Medium/GitHub are listed once, in the `#contact` section only. The footer intentionally holds just the copyright line — don't reintroduce the same links there (previously duplicated) or add an email address (removed by request; there is currently no email contact method on the site, by design).

- `Dockerfile` — two-stage build for **local/prod-parity testing only** (not used for GitHub Pages, which serves `index.html` directly from the repo).
  - Stage 1 (`source`, `alpine:3.20`): isolates the build context, copies in `index.html`.
  - Stage 2 (`runtime`, `nginxinc/nginx-unprivileged:1.27-alpine`): runs as non-root user `nginx` on port 8080 (not 80, since unprivileged). Includes a `HEALTHCHECK`.

- `.devcontainer/devcontainer.json` — a **separate, lightweight editing environment**, intentionally decoupled from the production Dockerfile above. Uses `mcr.microsoft.com/devcontainers/base:alpine-3.20` and serves the site via `python3 -m http.server 8000` on container start for live preview while editing. Do not conflate this with the nginx Dockerfile — they serve different purposes (editing vs. prod-parity verification).

## Commands

There is no build/lint/test tooling in this repo (no `package.json`, no test framework). Common workflows:

```bash
# Local prod-parity test (nginx, non-root, port 8080)
docker build -t erayweb .
docker run -d --name erayweb-test -p 8080:8080 erayweb
curl -s http://localhost:8080/ | grep "<title>"   # sanity check
docker exec erayweb-test whoami                    # should print "nginx", confirming non-root
docker rm -f erayweb-test

# Quick local preview without Docker
python3 -m http.server 8000    # then open http://localhost:8000
```

Devcontainer users get the `python3 -m http.server 8000` preview automatically via `postStartCommand`.

## Git workflow

This repo follows a git-flow branch model (no `git-flow` CLI extension installed — the model is applied with plain git):

- `main` — production; this is the branch GitHub Pages deploys from. Only receives merges from `develop` (or a `hotfix/*` branch for urgent fixes).
- `develop` — integration branch. `feature/*` branches are cut from and merged back into `develop`.
- `feature/*`, `hotfix/*` — short-lived branches, isolated via `git worktree` rather than switching branches in place, so `main`'s working copy is never disturbed mid-feature:

```bash
git worktree add ../erayweb-feature-x -b feature/x develop
# ...work in the new worktree...
git checkout develop && git merge --no-ff feature/x
git worktree remove ../erayweb-feature-x
git worktree prune
git branch -d feature/x
```

To ship: merge `develop` into `main` (`git checkout main && git merge --no-ff develop`) — this is the only path that should update the GitHub Pages deploy branch.
