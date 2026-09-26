# varyk.com

The website for [Varyk](https://varyk.com), an experimental programming language for backend services, with Rust-like safety and Go-like simplicity, that compiles to Rust. The compiler lives at [github.com/Varyk-Lang/varyk](https://github.com/Varyk-Lang/varyk).

The site is built with [Zola](https://www.getzola.org) and served as static assets by a Cloudflare Worker. No JavaScript, no external requests. The design system (logo, colour, type, layout) is in [docs/design-guidelines.md](docs/design-guidelines.md).

## Layout

- `content/` — the pages, as Markdown with TOML front matter.
- `templates/` — Tera templates; `partials/` holds the head, nav, footer, the logo, the borrowing figure, and the hero figure.
- `static/` — copied as is: `site.css`, `favicon.svg`, `fonts/` (Newsreader, SIL Open Font License), `_headers`, `.well-known/security.txt`.
- `syntaxes/varyk.json` — a minimal grammar so Varyk code blocks keep their `varyk` label.
- `scripts/build.sh` — fetches the pinned Zola if needed, builds into `public/`, then runs `scripts/agents.sh`.
- `scripts/agents.sh` — writes a Markdown copy of every page (`<page>/index.md`, the home page copy starting with the hero lead) and `/llms.txt` for AI agents, and fails the build if the borrowing figure on the home page drifts from the borrowing example.
- `config.toml` — site settings; the nav and footer link lists and the site-wide copy live under `[extra]`.
- `docs/` — the design guidelines and the brand assets (`docs/brand/`); not published.
- `wrangler.jsonc` — the Worker: assets only, served from `public/`, with `404.html` for missing paths.

## Working on the site

Install Zola 0.23.6 (`brew install zola`, or let the build script download it) and run:

```sh
zola serve                                   # live preview while writing
./scripts/build.sh && npx wrangler dev       # production-like preview: headers, 404, Markdown copies
```

`zola serve` does not run `agents.sh`, so `/llms.txt` and the `.md` copies only appear in the full build.

## Content rules

- Every claim about Varyk traces to the compiler repository: its design spec, roadmap, examples, and license files. Placeholders name a milestone, never a date.
- The examples and the language reference are copied by hand from the compiler repository and must be refreshed when it changes.
- Varyk code blocks are tagged `varyk`, never `rust`, so agents reading the Markdown copies see the right language.
- No shortcodes in content; the build fails if one is used, because it would leak into the Markdown copies.
- Things that only the first release can settle are marked `<!-- TODO(release): ... -->` in the content. Comments are stripped from the Markdown copies.
- To publish a blog post, remove `draft = true` from its front matter and set its `date` with the time, such as `date = 2026-09-24T20:25:00+02:00`. The blog lists the newest post first, and a time keeps posts from the same day in order.

## Contributing

Open an issue or a pull request. CI builds the site and validates the Worker config on every pull request; a pull request that fails CI is not merged. Unless you explicitly state otherwise, any contribution you intentionally submit for inclusion, as defined in the Apache-2.0 license, is dual-licensed as below, without any additional terms or conditions.

### Previewing a pull request from a fork

Cloudflare only builds branches in this repository, so fork pull requests get no preview URL. Two ways to see one:

- **Locally.** `gh pr checkout <number>`, then `zola serve`. Zola only renders Markdown and templates, so this runs none of the contributor's code. For a production-like preview, `./scripts/build.sh && npx wrangler dev` runs their `scripts/`, so read that diff first.
- **Build it on Cloudflare.** After reviewing the diff, push the branch into this repository: `gh pr checkout <number>` then `git push origin HEAD:preview/pr-<number>`. Cloudflare builds it and posts a preview URL. That build can deploy, so read any change to `scripts/`, `wrangler.jsonc`, or `static/_headers` first.

## Deploying

Pushes to `main` deploy through Cloudflare Workers Builds, configured in the Cloudflare dashboard (Workers & Pages → `varyk-com` → Settings → Build):

- Git repository: `Varyk-Lang/varyk.com`, production branch `main`
- Build command: `./scripts/build.sh`
- Deploy command: `npx wrangler deploy`
- Root directory: `/`

Every branch pushed to this repository, including pull request branches, gets a preview build with its own URL; pull requests from forks do not (see above). Merging to `main` builds and deploys production. The custom domain `varyk.com` is attached by the `routes` entry in `wrangler.jsonc`, so every deploy keeps it; the zone must be on the same Cloudflare account.

### Keeping the site in sync with the compiler

`content/learn/reference.md` and the examples are copies from the compiler repository, and the generated Rust on the home and examples pages is the output of the released compiler. When the compiler's `docs/language.md`, `examples/`, or code generation changes, copy them again and update the commit noted at the top of the reference. The compiler is released by release-please, so the site never names a version; the Install page links to crates.io instead.

### Cloudflare settings

Set in the dashboard, not in this repository. They must allow crawlers, or the site's own `robots.txt` is moot:

- AI crawler blocking: off
- Managed `robots.txt`: off
- Bot Fight Mode: off
- Crawler Hints (IndexNow): on
- HSTS: on
- The `workers.dev` route is off and preview URLs are on, set by `workers_dev` and `preview_urls` in `wrangler.jsonc` so deploys keep them

The domain is verified in Google Search Console and Bing Webmaster Tools by a DNS TXT record, not by a file or tag in this repository, and `https://varyk.com/sitemap.xml` is submitted to both.

### To do

- Add an `og:image` for link previews and review the `img-src` rule in `static/_headers`

## License

MIT or Apache-2.0, at your option. See `LICENSE-MIT` and `LICENSE-APACHE`.
