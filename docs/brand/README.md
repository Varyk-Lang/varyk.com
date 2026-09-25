# Varyk brand assets

The Varyk mark as standalone SVG files, for use outside the website: slides, READMEs, avatars, stickers. The rules for using them are in [../design-guidelines.md](../design-guidelines.md).

| File | Use |
|---|---|
| `varyk-mark.svg` | The mark on its dark tile. The default; identical to the site's `favicon.svg`. |
| `varyk-mark-paper.svg` | The mark on its paper tile, for light layouts. |
| `varyk-mark-bare-dark.svg` | No tile, for dark backgrounds. The hubs are real holes. |
| `varyk-mark-bare-paper.svg` | No tile, for light backgrounds. |
| `varyk-mark-mono-black.svg` | One colour (ink), for single-colour print on light. |
| `varyk-mark-mono-white.svg` | One colour (white), for single-colour print on dark. |
| `varyk-mark-square.svg` | The mark with the tile filling the whole square, no rounded corners: for services that round avatars themselves, such as GitHub. |
| `varyk-app-icon.svg` | Both gears in one dark colour on a solid verdigris tile: where a single flat colour is required or clearly better, such as home-screen icons and monochrome badges. |

All files use the same geometry as `templates/partials/logo.html` (64-unit grid, Rust gear centre 26.94, 38.73; Varyk gear centre 46.06, 16.27). Export PNGs from these SVGs when a service needs a bitmap; do not redraw the mark.

Prefer the two-colour mark wherever it can be shown; the two metals are the brand. Use `varyk-mark-square` for avatars that the service rounds itself (GitHub), `varyk-mark` where the rounded tile shows as drawn (favicons, the site), and the one-colour app icon only where a single flat colour is required.

The wordmark, `varyk` in lower case, is set in the system sans at weight 800; there is no outlined wordmark file, so place it as live text beside the mark.

## PNG exports

`png/` holds renders of the SVGs above at the sizes services usually ask for, all with a transparent background outside the tile:

| Files | Sizes | For |
|---|---|---|
| `varyk-mark-<size>.png` | 16, 32, 48, 64, 128, 256, 512, 1024 | favicons, avatars, READMEs |
| `varyk-mark-paper-<size>.png` | 256, 1024 | light layouts |
| `varyk-mark-square-<size>.png` | 512, 1024 | **the GitHub organisation avatar**, and any service that rounds avatars itself |
| `varyk-app-icon-<size>.png` | 180, 192, 512, 1024 | Apple touch icon, web app manifest, and other places that want one flat colour |
| `varyk-mark-bare-dark-<size>.png`, `varyk-mark-bare-paper-<size>.png` | 512, 1024 | placing the gears without a tile |
| `varyk-mark-mono-black-512.png`, `varyk-mark-mono-white-512.png` | 512 | single-colour use |

They were rendered from the SVGs with a browser engine. When the SVGs change, re-export at the same sizes rather than editing the PNGs.
