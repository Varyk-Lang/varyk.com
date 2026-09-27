# Varyk design guidelines

How varyk.com looks and why. The implementation is `static/site.css`, `templates/`, and `content/_index.md`; this file is the reference they follow. Change the guidelines first, then the code.

## The idea

Varyk is a small, simple language that drives Rust. The brand says exactly that, and nothing borrowed:

- **Two metals.** Verdigris, copper's patina, is Varyk. Red oxide, rusted iron, is Rust. Every colour decision follows from that pair.
- **An editorial, engineered page.** Serif headlines, numbered sections, hairline rules, and code shown as captioned figures, like an engineering drawing. Not a template: no pills, no dotted-grid backgrounds, no rows of rounded cards, no gradients, no emoji, no "·"-separated eyebrow labels.
- **The compiler's work is visible.** Wherever Varyk code sits beside the Rust it becomes, the pieces the compiler writes are marked in red oxide.

## Logo

### The mark

A small verdigris gear (Varyk) at the top right drives a larger red-oxide gear (Rust) at the bottom left. The two are engaged, a Varyk tooth pointing into a Rust gap, but they never touch: Varyk writes the Rust, and rustc checks it.

Geometry, on a 64-unit square:

| Part | Value |
|---|---|
| Tile | 64 × 64, corner radius 15 |
| Rust gear | 8 teeth; body radius 14; teeth 7 wide × 5 tall; hub hole 38% of the body radius |
| Varyk gear | 6 teeth; body radius 6.5; teeth 4 wide × 3.5 tall; hub hole 38% |
| Placement | centres 29.5 units apart on a line 50° above horizontal; the pair is centred on the tile |
| Centres | Rust (26.94, 38.73), Varyk (46.06, 16.27) |
| Clearance | at least 0.9 units between the gears through a full turn |

29.5 units is the closest the pair can sit and still turn at 8 : 6 without the teeth ever touching; it was found by simulating a full turn. Do not move the gears closer.

Files:

- `templates/partials/logo.html`: the inline SVG used in the header, footer, and 404 page. Its colours and motion come from classes in `site.css` (`vk-tile`, `vk-rust`, `vk-varyk`, `vk-hole`, `vk-in-*`, `vk-big`, `vk-small`), because the CSP forbids inline styles.
- `static/favicon.svg`: the same geometry with fixed colours on the dark tile, so it reads on light and dark browser chrome.
- `docs/brand/`: standalone SVGs of every version (dark and paper tiles, no tile, one colour, app icon) and PNG exports at common sizes under `docs/brand/png/`, for use outside the site. Its README lists which file to use where.

### Colours of the mark

| | Tile | Rust gear | Varyk gear |
|---|---|---|---|
| Dark | `#1B201F` | `#BF3B33` | `#5FBFAE` |
| Paper | `#E4DFD3` | `#9C2A26` | `#23705F` |
| One colour | none | ink | ink |

The app icon and avatar version knocks both gears out of a solid verdigris tile.

### Wordmark

`varyk`, always lower case, in the system sans at weight 800 with −0.045em tracking, to the right of the mark with a gap of one third of the mark's width. The wordmark does not use the serif.

### Motion

- On page load the gears turn for 4.5 s and ease to a stop at 90° (Rust) and −120° (Varyk): exactly two teeth on, so the resting mark looks as drawn.
- While the logo link is hovered they keep turning (Rust 18 s per turn, Varyk 13.5 s the other way, 8 : 6) and stop where they are when the pointer leaves.
- Under `prefers-reduced-motion: reduce` nothing moves.
- Motion never runs longer than 5 s on its own, so no pause control is needed (WCAG 2.2.2).

### Clear space and minimum size

Keep clear space of one Varyk-gear diameter around the tile. At 16–24 px the gap between the gears closes visually; that is expected, the two silhouettes still read as a pair.

### Trademark guardrails

Rust's logo is a gear, so the mark stays clearly apart from it:

- Never a ring of many fine teeth, never a letter inside a gear, and no R anywhere.
- The two-gear layout (small drives large) and the two metals are what make the mark Varyk's.
- No crab, no gopher, no Ferris orange, no Go cyan.
- Saying "compiles to Rust" in text is fine; the words Rust or Go never appear inside the logo.

## Colour

The site follows the reader's system setting: paper when it is light, dark when it is dark. Both are defined as tokens at the top of `site.css`.

| Token | Paper | Dark | Role |
|---|---|---|---|
| `--bg` | `#EFEBE2` | `#0F1211` | page |
| `--alt` | `#E8E3D8` | `#151918` | every other home section, footer |
| `--code` | `#E4DFD3` | `#121615` | code, figures, the Varyk column |
| `--line` | `#D2CCBE` | `#2D3432` | hairlines and borders |
| `--ink` | `#1A2321` | `#EEEAE0` | headlines, code, emphasis |
| `--body` | `#283130` | `#DCD9D2` | running text |
| `--muted` | `#55605C` | `#B3AFA7` | labels, captions, secondary text |
| `--faint` | `#7A7E78` | `#7D7A74` | large section numerals and the `$` prompt only |
| `--accent` | `#23705F` | `#5FBFAE` | verdigris: Varyk, links, buttons, the small gear |
| `--on-accent` | `#F6F3EC` | `#0B1211` | text on a verdigris button |
| `--red` | `#9C2A26` | `#BF3B33` | red oxide: Rust, the big gear, compiler marks |
| `--mark` | `#F1D8D1` | `#3B1917` | background of marked code |
| `--strip` / `--strip-ink` | `#E9D6D0` / `#3A1D19` | `#2A1716` / `#EBCFC6` | the "Experimental" strip |

Rules:

- **Verdigris is the only green.** Text, backgrounds, and lines are neutral; a green tint on text next to a green-black ground makes it look soft.
- **Red oxide is for marks, never for text.** Light red on a dark page turns salmon and reads as someone else's brand. Red appears as the gear, underlines, the `cargo` box, and the underline of marked code; the marked text itself stays ink.
- **No orange anywhere.** Orange belongs to Rust's community, Swift, Zig, and Claude.
- Meaning never depends on colour alone: red marks also carry an underline or a box, and verdigris and red differ strongly in lightness, so they stay apart for red-green colour blindness.

## Typography

| Use | Face | Size | Notes |
|---|---|---|---|
| Hero headline | Newsreader 500 | clamp(2.75rem, 6.2vw, 4.75rem) | "Simple services." underlined in red oxide; "*speed.*" italic in verdigris |
| Home section headline (h2) | Newsreader 500 | clamp(2rem, 4vw, 3rem) | italic verdigris for one emphasised word at most |
| Page title (h1) | Newsreader 500 | clamp(2.5rem, 6vw, 3.5rem) | |
| Page h2 | Newsreader 500 | clamp(1.625rem, 3vw, 2.125rem) | |
| h3 | system sans 700 | 1.125rem | |
| Body, home | system sans | 1.0625–1.1875rem (17–19 px) | line height 1.6–1.65 |
| Body, docs | system sans | 1.125rem (18 px) | measure 46rem |
| Labels, captions | system sans | 0.9375rem (15 px) | never smaller for text |
| Code | system mono | 14–15 px | line height 1.6 |

- **Newsreader** (Production Type, SIL Open Font License) is the only web font. It is self-hosted in `static/fonts/` with its licence, `OFL.txt`; no font is ever loaded from another origin.
- The files are the variable fonts from the Google Fonts repository, limited to weights 400–600 with the full optical-size axis, subset to Latin (U+0000–017F plus common punctuation, arrows, and symbols), as WOFF2: about 116 KB upright and 131 KB italic. `Newsreader.woff2` is preloaded; the italic loads when first used.
- To rebuild them from the upstream TTFs you need fontTools with brotli (a one-off developer tool, not part of the build):

  ```text
  fonttools varLib.instancer Newsreader[opsz,wght].ttf wght=400:600 -o Newsreader-lim.ttf
  pyftsubset Newsreader-lim.ttf --unicodes="U+0000-017F,U+0192,U+02C6,U+02DA,U+02DC,U+2000-206F,U+20AC,U+2122,U+2190-2193,U+2212,U+2215,U+FEFF,U+FFFD" --layout-features='*' --flavor=woff2 --output-file=static/fonts/Newsreader.woff2
  ```

  and the same for `Newsreader-Italic[opsz,wght].ttf`.
- Serif for headlines and figure numbers, sans for reading, mono for code. The wordmark is the only heavy sans.
- Sentence case everywhere. Headlines end with a full stop.

## Layout

- Page width up to 90rem, with a gutter of `clamp(1rem, 6.6vw, 6rem)`: 16 px on a phone, 96 px on a 1440 px screen.
- Reading measure 46rem. Tables, `.panes`, and `.cols` may run wider.
- Breakpoints: 48rem (code comparisons side by side, both the home figure and `.panes`; two-column lists; the comparison table stacks below it), 56rem (three audience columns), 64rem (numbered-section grid, horizontal pipeline and roadmap), 80rem (hero text and figure side by side).
- Every page works at 360 px wide with no horizontal page scroll; only code blocks may scroll.

### Home page

The home page is ordinary Zola: `content/_index.md` holds all the copy as Markdown and front matter, and `templates/index.html` turns it into the page. Nothing in the Markdown is presentational, so the Markdown copy for agents stays clean.

- **Hero.** From `[extra]` in the front matter: `eyebrow`, `headline` (one entry per line; Markdown, so `*speed.*` becomes the verdigris italic; the first line gets the red-oxide underline), `lead`, `actions` (the first is the button, the rest text links), `install_label` and `install`, and `figure_caption` for the hero figure and `borrowing_caption` for the borrowing figure (both Markdown; `**Marked**` renders as a compiler mark).
- **Hero figure.** `templates/partials/home-service.html`: one Varyk pane showing a service as milestone 5 is designed to write it, with a "coming" note in the pane header (`.pane-note`) and no compiler marks. It is a design target, not code the compiler accepts, and lives only in the template so it never reaches the Markdown copies.
- **Borrowing figure.** `templates/partials/home-figure.html`: the borrowing example beside its generated Rust, with the compiler's additions in `<mark>`. It is a copy of `content/learn/examples.md`, checked on every build, and is placed after the first paragraph of the band whose `[[extra.bands]]` entry sets `figure = "borrowing"`.
- **Numbered sections.** Every `##` heading in the body starts a band. The template splits the rendered Markdown at each `<h2`, numbers the bands 01, 02, …, and describes each with the matching entry of `[[extra.bands]]`, in order:

  ```text
  [[extra.bands]]
  id = "roadmap"      # the anchor, #roadmap
  label = "Roadmap"   # the label beside or above the numeral
  style = "road"      # the layout: band-road in site.css
  done = 1            # roadmap only: completed milestones
  ```

  Add a `##` section and a `[[extra.bands]]` entry together; headings inside a band are `###`. The build fails if the counts of `##` headings, `[[extra.bands]]` entries, and rendered sections differ, or if any raw `<h2`/`<h3` text sneaks into the Markdown, because the template splits the rendered content on those tags.
- **Band styles** turn plain Markdown into layouts, with no HTML in the content: `mission` shows an ordered list as the source-to-binary pipeline (each entry's leading bold text is the step), `changes` styles the Rust-versus-Varyk table and, with `figure = "borrowing"`, holds the borrowing figure after its first paragraph, `who` (with `columns = true`) puts each `###` subsection in its own column, `get` shows a list as the two-column "what you get" grid, `road` shows an ordered list as the roadmap with one gear per milestone (solid up to `done`, faded for the next), and `start` keeps code blocks to a readable width.
- Bands alternate automatically, starting on `--alt`: the first band contrasts with the hero above it and, with an even number of bands, the last contrasts with the `--alt` footer. The rule counts bands only (`:nth-child(odd of .band)`), so the hero section does not shift the rhythm; an `@supports` fallback gives engines without that syntax the same result by counting sections, since the hero is always first.

### Other pages

Pages and sections are Markdown rendered into a reading column by `page.html`, `section.html`, `blog.html`, and `blog-page.html`. The one layout written as HTML inside Markdown is `<div class="panes">` on the examples page, which sets two code blocks side by side: Zola's usual tool for that, a shortcode, is ruled out because it would leak into the Markdown copies.

### Site-wide copy

The notice in the strip, the repository link, and the footer's tagline and contact sentence live under `[extra]` in `config.toml`, as inline Markdown. The nav and footer link lists are there too.

## Components

- **Experimental strip.** Every page opens with it until 1.0: "Experimental." in bold, then the pre-1.0 sentence from `config.toml`. It is an `aside` landmark labelled "Project status", so assistive technology can reach and skip it. The one exception is the 404 page, which is deliberately minimal: skip link, header with the mark, the message, and a link home; no strip, nav, or footer.
- **Header.** Mark and wordmark, the nav from `config.toml`, and GitHub's mark with "GitHub" at the right, linking to `extra.repository`. The icon is GitHub's own mark from Octicons (MIT), used as GitHub's logo guidelines allow, to link to a GitHub page; do not recolour or redraw it. The current section is marked with a verdigris underline. On phones the nav wraps onto its own row.
- **Buttons.** One style: verdigris fill, 4 px radius, at least 50 px tall. Use one per view at most; everything else is a text link.
- **Text links.** Ink text with a 2 px verdigris underline; verdigris on hover.
- **Install line.** A label, then the command on a hairline with a `$` prompt. The command is selected in one click (`user-select: all`); there is no copy button, because the site runs no JavaScript.
- **Figures.** Code panes are keyboard-focusable (`tabindex="0"`) because they can scroll sideways. They share one bordered block with a monospace file-name header (a verdigris square for Varyk, a red-oxide square for Rust). Caption below: "Fig. n" in serif italic, then the sentence in muted text.
- **Compiler marks.** `<mark>` around what the compiler writes: `--mark` background, red-oxide underline, ink text. Only in figures that set Varyk beside its generated Rust.
- **Numbered sections, tables, lists, the roadmap.** See the home page notes above; they are styled from plain Markdown by band style. Structure comes from hairlines, not boxes.
- **Footer.** On `--alt` with a hairline above: mark and wordmark, the serif line "Rust's safety. Go's *simplicity.*", the contact sentence, the link columns from `config.toml`, then the legal lines. The legal text is the owner's to change.

## Accessibility

Measured contrast (WCAG 2.x):

| Pair | Paper | Dark | Needs |
|---|---|---|---|
| Body text | 11.2 | 13.4 | 4.5 |
| Muted labels on page / alt / code | 5.5 / 5.1 / 4.9 | 8.6 / 8.1 / 8.3 | 4.5 |
| Verdigris link text on page / alt | 5.0 / 4.6 | 8.6 / 8.1 | 4.5 |
| Button text | 5.3 | 8.6 | 4.5 |
| Marked code | 11.9 | 13.1 | 4.5 |
| Large numerals | 3.5 | 4.4 | 3 |
| Red gear on its tile | 5.7 | 3.05 | 3 |

- Keep every new pair at or above these minimums, and check both modes.
- Focus is a 2 px verdigris outline, offset 3 px.
- Touch targets are at least 44 px tall (nav links, footer links, buttons).
- Motion follows `prefers-reduced-motion`.
- The skip link is the first element on every page, the 404 page included.

## Technical constraints

These come from `AGENTS.md` and still hold:

- No JavaScript, and no requests to other origins. Fonts are self-hosted.
- The CSP allows only `'self'`: no `style` attributes, no `<style>` elements, no inline event handlers. SVG colours and motion therefore live in `site.css` classes.
- Code blocks in Markdown stay plain and correctly tagged; the red marks exist only in the home figure template (`templates/partials/home-figure.html`), which `scripts/agents.sh` checks against `content/learn/examples.md` on every build.
