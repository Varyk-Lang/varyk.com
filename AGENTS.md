# AGENTS.md

Instructions for AI coding agents working in this repository. People should start with [README.md](README.md).

This is the source of <https://varyk.com>, the website for the Varyk programming language. It is a [Zola](https://www.getzola.org) static site served as assets by a Cloudflare Worker. The compiler is a separate repository, [Varyk-Lang/varyk](https://github.com/Varyk-Lang/varyk). Both repositories are public, so everything you write here is published.

## Commands

```sh
./scripts/build.sh                 # build into public/: pinned Zola, then scripts/agents.py
zola serve                         # live preview while editing content (no agent outputs)
npx wrangler dev                   # after build.sh: production-like preview with headers and 404
npx wrangler deploy --dry-run      # validate wrangler.jsonc without deploying
```

A change is done when `./scripts/build.sh` and `npx wrangler deploy --dry-run` both succeed. CI runs the same steps on every pull request.

## Layout

- `content/` pages as Markdown with TOML front matter; `content/blog/` posts.
- `templates/` Tera templates; `partials/` holds head, nav, footer.
- `static/` copied as is: `site.css`, `_headers` (security headers and CSP), `.well-known/security.txt`.
- `config.toml` site settings; nav and footer links live under `[extra]`.
- `scripts/build.sh` build entry point for local builds, CI, and Cloudflare.
- `scripts/agents.py` writes a Markdown copy of each page and `/llms.txt`.
- `syntaxes/varyk.json` minimal grammar that keeps Varyk code blocks labelled `varyk`.
- `wrangler.jsonc` the Worker: assets only, custom domain `varyk.com`.

## Content rules

- **Every claim about Varyk must trace to the compiler repository**: its README, `docs/`, `docs/specs/`, `examples/`, or license and trademark files. Do not invent features, benchmarks, install commands, versions, or dates. Unfinished work names a milestone, never a date.
- **Copies must stay exact.** `content/learn/reference.md` is `docs/language.md` from the compiler repository, with the source commit noted at the top; the examples and the generated Rust on the home and examples pages match `examples/` and the compiler README byte for byte. Refresh them by copying, not by editing.
- **Tag Varyk code blocks ` ```varyk `**, never ` ```rust `. The Markdown copies are read by AI agents, and a wrong tag teaches them that Varyk is Rust.
- **No shortcodes in content.** The build fails on a shortcode call such as `{{ name(...) }}` in `content/`, because it would leak into the Markdown copies unexpanded.
- **Every page needs `title` and `description`** in its front matter; they become the page title, meta description, and `llms.txt` entry.
- Things only a release can settle are marked `<!-- TODO(release): ... -->`. HTML comments are stripped from the Markdown copies but are visible in the page source, so never put private information in them.
- Legal text (license, trademark, copyright, privacy, security policy) is the owner's to change. Do not reword it on your own initiative.

## Design constraints

- No JavaScript, no external requests, no web fonts, no build dependencies beyond Zola and Python's standard library.
- The CSP in `static/_headers` allows only `'self'`: no inline `style` attributes, no `<style>` elements, and no executable `<script>` in templates or content. The JSON-LD blocks in `templates/partials/head.html` (`type="application/ld+json"`) are data, not code, and are the only `<script>` elements allowed.
- Link within the site with root-relative paths (`/learn/`, or `page.path` in templates), never `https://varyk.com/...` or `permalink`: absolute links send preview deployments to production. Absolute URLs belong only where the page is read from elsewhere: the canonical tag, Open Graph tags, JSON-LD, the sitemap, the feed, and `llms.txt`.
- Pages must work at 360px wide with no horizontal page scroll (code blocks may scroll), and in light and dark mode through the tokens in `site.css`.

## Safety

- **`scripts/`, `wrangler.jsonc`, and `static/_headers` are the deploy.** Changes to them change what runs on Cloudflare or what the site allows; call them out explicitly in the pull request.
- Never commit secrets, tokens, local paths such as `/Users/...`, or email addresses other than hello@varyk.com and security@varyk.com. CI greps the build for local paths.
- Never push to `main` directly or deploy by hand. Merging a pull request to `main` deploys production through Cloudflare Workers Builds.
- Do not run code from a contributor's pull request (`scripts/`) without reading its diff first.
