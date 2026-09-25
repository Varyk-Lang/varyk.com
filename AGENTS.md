# AGENTS.md

Instructions for AI coding agents working in this repository. People should start with [README.md](README.md).

This is the source of <https://varyk.com>, the website for the Varyk programming language. It is a [Zola](https://www.getzola.org) static site served as assets by a Cloudflare Worker. The compiler is a separate repository, [Varyk-Lang/varyk](https://github.com/Varyk-Lang/varyk). Both repositories are public, so everything you write here is published.

## Commands

```sh
./scripts/build.sh                 # build into public/: pinned Zola, then scripts/agents.sh
zola serve                         # live preview while editing content (no agent outputs)
npx wrangler dev                   # after build.sh: production-like preview with headers and 404
npx wrangler deploy --dry-run      # validate wrangler.jsonc without deploying
```

A change is done when `./scripts/build.sh` and `npx wrangler deploy --dry-run` both succeed. CI runs the same steps on every pull request.

## Layout

- `content/` pages as Markdown with TOML front matter; `content/blog/` posts.
- `templates/` Tera templates; `partials/` holds head, nav, footer, the logo (`logo.html`), the GitHub icon (`icon-github.html`), and the home page figure (`home-figure.html`); `robots.txt` allows all crawlers and declares Content Signals.
- `static/` copied as is: `site.css`, `favicon.svg`, `fonts/` (self-hosted Newsreader and its licence), `_headers` (security headers, CSP, and the home page's `Link` header), `.well-known/security.txt`.
- `config.toml` site settings; nav and footer links live under `[extra]`.
- `scripts/build.sh` build entry point for local builds, CI, and Cloudflare.
- `scripts/agents.sh` writes a Markdown copy of each page and `/llms.txt`, and checks the home page figure against the borrowing example.
- `syntaxes/varyk.json` minimal grammar that keeps Varyk code blocks labelled `varyk`.
- `wrangler.jsonc` the Worker: assets only, custom domain `varyk.com`.
- `docs/design-guidelines.md` the design system: logo, colour, type, layout, components; `docs/brand/` the logo as standalone SVG files. Neither is published.

## Content rules

- **Every claim about Varyk must trace to the compiler repository**: its README, `docs/`, `docs/specs/`, `examples/`, or license and trademark files. Do not invent features, benchmarks, install commands, versions, or dates. Unfinished work names a milestone, never a date.
- **Copies must stay exact.** `content/learn/reference.md` is `docs/language.md` from the compiler repository, with the source commit noted at the top; the examples and the generated Rust on the home and examples pages match `examples/` and the compiler README byte for byte. Refresh them by copying, not by editing. The home page figure (`templates/partials/home-figure.html`) is a marked-up copy of the borrowing example in `content/learn/examples.md`; the build fails if the two differ, so update both together.
- **Tag Varyk code blocks ` ```varyk `**, never ` ```rust `. The Markdown copies are read by AI agents, and a wrong tag teaches them that Varyk is Rust.
- **The home page is Markdown plus front matter.** In `content/_index.md`, every `##` heading starts a numbered section, described in order by a `[[extra.bands]]` entry; add or remove both together, and use `###` inside a section. The hero copy is in `[extra]`. Keep HTML out of content; site-wide copy (the notice, tagline, contact line, repository link) lives under `[extra]` in `config.toml`.
- **No shortcodes in content.** The build fails on a shortcode call such as `{{ name(...) }}` in `content/`, because it would leak into the Markdown copies unexpanded.
- **Every page needs `title` and `description`** in its front matter; they become the page title, meta description, and `llms.txt` entry. The build fails without them.
- Things only a release can settle are marked `<!-- TODO(release): ... -->`. HTML comments are stripped from the Markdown copies but are visible in the page source, so never put private information in them.
- Legal text (license, trademark, copyright, privacy, security policy) is the owner's to change. Do not reword it on your own initiative.

## Design constraints

- Follow `docs/design-guidelines.md` for colour, type, the logo, layout, and components. Red oxide marks things and is never a text colour; verdigris is the only green.
- No JavaScript, no external requests, no build dependencies beyond Zola and a POSIX shell with standard tools (`bash`, `awk`, `sed`, `grep`). The only web font is Newsreader, self-hosted in `static/fonts/` with its licence; never load a font or anything else from another origin. The font files are committed; rebuilding them (rarely) needs fontTools, as the guidelines describe.
- The CSP in `static/_headers` allows only `'self'`: no inline `style` attributes, no `<style>` elements, and no executable `<script>` in templates or content, so SVG colours and animation live in `site.css` classes. The JSON-LD blocks in `templates/partials/head.html` (`type="application/ld+json"`) are data, not code, and are the only `<script>` elements allowed.
- Link within the site with root-relative paths (`/learn/`, or `page.path` in templates), never `https://varyk.com/...` or `permalink`: absolute links send preview deployments to production. Absolute URLs belong only where the page is read from elsewhere: the canonical tag, Open Graph tags, JSON-LD, the sitemap, the feed, and `llms.txt`.
- Pages must work at 360px wide with no horizontal page scroll (code blocks may scroll), and in light and dark mode through the tokens in `site.css`.

## Safety

- **`scripts/`, `wrangler.jsonc`, and `static/_headers` are the deploy.** Changes to them change what runs on Cloudflare or what the site allows; call them out explicitly in the pull request.
- Never commit secrets, tokens, local paths such as `/Users/...`, or email addresses other than hello@varyk.com and security@varyk.com. CI greps the build for local paths.
- Never push to `main` directly or deploy by hand. Merging a pull request to `main` deploys production through Cloudflare Workers Builds.
- Do not run code from a contributor's pull request (`scripts/`) without reading its diff first.
