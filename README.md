# varyk.com

The website for [Varyk](https://varyk.com), an experimental systems programming language with Rust-like safety and Go-like simplicity that compiles to Rust. The compiler lives at [github.com/Varyk-Lang/varyk](https://github.com/Varyk-Lang/varyk).

The site is built with [Zola](https://www.getzola.org) and served as static assets by a Cloudflare Worker. No JavaScript, no external requests.

## Layout

- `content/` — the pages, as Markdown with TOML front matter.
- `templates/` — Tera templates; `partials/` holds the head, nav, and footer.
- `static/` — copied as is: `site.css`, `favicon.svg`, `_headers`, `.well-known/security.txt`.
- `syntaxes/varyk.json` — a minimal grammar so Varyk code blocks keep their `varyk` label.
- `scripts/build.sh` — fetches the pinned Zola if needed, builds into `public/`, then runs `scripts/agents.py`.
- `scripts/agents.py` — writes a Markdown copy of every page (`<page>/index.md`) and `/llms.txt` for AI agents.
- `config.toml` — site settings; the nav and footer link lists live under `[extra]`.
- `wrangler.jsonc` — the Worker: assets only, served from `public/`, with `404.html` for missing paths.

## Working on the site

Install Zola 0.23.6 (`brew install zola`, or let the build script download it) and run:

```sh
zola serve                                   # live preview while writing
./scripts/build.sh && npx wrangler dev       # production-like preview: headers, 404, Markdown copies
```

`zola serve` does not run `agents.py`, so `/llms.txt` and the `.md` copies only appear in the full build.

## Content rules

- Every claim about Varyk traces to the compiler repository: its design spec, roadmap, examples, and license files. Placeholders name a milestone, never a date.
- The examples and the language reference are copied by hand from the compiler repository and must be refreshed when it changes.
- Varyk code blocks are tagged `varyk`, never `rust`, so agents reading the Markdown copies see the right language.
- No shortcodes in content; the build fails if one is used, because it would leak into the Markdown copies.
- Things that only the first release can settle are marked `<!-- TODO(release): ... -->` in the content. Comments are stripped from the Markdown copies.
- To publish a blog post, remove `draft = true` from its front matter and set its `date`.

## Contributing

Open an issue or a pull request. CI builds the site and validates the Worker config on every pull request; a pull request that fails CI is not merged. Unless you explicitly state otherwise, any contribution you intentionally submit for inclusion, as defined in the Apache-2.0 license, is dual-licensed as below, without any additional terms or conditions.

## Deploying

Pushes to `main` deploy through Cloudflare Workers Builds, configured in the Cloudflare dashboard (Workers & Pages → `varyk-com` → Settings → Build):

- Git repository: `Varyk-Lang/varyk.com`, production branch `main`
- Build command: `./scripts/build.sh`
- Deploy command: `npx wrangler deploy`
- Root directory: `/`

Every pull request gets a preview build with its own URL; merging to `main` builds and deploys production. The custom domain `varyk.com` is attached to the Worker in the dashboard, not in `wrangler.jsonc`.

### Launch checklist

- [ ] Publish `varyk-syntax` and then `varyk` 0.0.1 to crates.io, and confirm `cargo install varyk` on a clean machine
- [ ] Resolve the remaining markers: `grep -rn "TODO(release)" content`
- [ ] Publish the announcement post: set its `date`, remove `draft = true`
- [ ] Refresh `content/learn/reference.md` and the examples if the compiler repository's `docs/language.md` or `examples/` changed since the commit noted at the top of the reference
- [ ] Add an `og:image` for link previews and review the `img-src` rule in `static/_headers`

### Cloudflare dashboard

Settings the repository cannot control. All of them must allow crawlers, or the site's own `robots.txt` is moot:

- [ ] AI crawler blocking: off
- [ ] Managed `robots.txt`: off
- [ ] Bot Fight Mode: off, or not challenging verified bots
- [ ] Crawler Hints (IndexNow): on
- [ ] HSTS: on
- [ ] Once the custom domain is attached: disable the `workers.dev` route and preview URLs, so search engines see one host

### After launch

- [ ] Verify the domain in Google Search Console and Bing Webmaster Tools using a DNS TXT record in Cloudflare, not a file or tag in this repository
- [ ] Submit `https://varyk.com/sitemap.xml` to both

## License

MIT or Apache-2.0, at your option. See `LICENSE-MIT` and `LICENSE-APACHE`.
