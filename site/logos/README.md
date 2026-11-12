# eco logo kit: bird tracks

A walking trail of four bird tracks, going from bottom-left to top-right and alternating left and right of the line like a real stride. The trail reads as a capture history, 1 0 1 1: the second track is dashed, a survey that missed an animal that was there. Imperfect detection is the idea the project is built around. Colours are the site's: pine #1f3d2f (tracks and text), mist #f3f6f4 (the same on pine), ground #f4f7f5 / #fbfcfb (backgrounds); forest #2f6b4f and rust #b0522a are accents and never in the mark. The name is Source Sans 3 Bold (the site font) with slight negative tracking, converted to outlines. All SVGs have tight viewBoxes, role="img" and a <title>, with no rasters, filters or <style> blocks.

| File | Use |
| --- | --- |
| `eco-lockup.svg` / `-dark` | Trail to the left of "eco". The navbar uses `-dark` at 36px tall; below about 36px the tracks blur. |
| `eco-icon.svg` / `-dark` | The trail alone. 48px and up. |
| `eco-wordmark.svg` / `-dark` | "eco" alone, for text-heavy contexts where the mark is already on the page. |
| `eco-favicon-16.svg`, `eco-favicon-32.svg` | Hand-tuned, pixel-aligned icons on a pine tile: 32 has two tracks (solid, dashed), 16 has one solid track. |
| `favicon.ico` | 16 (hand-tuned) + 32 (hand-tuned) + 48 (the 32 design scaled). |
| `favicon-16.png`, `favicon-32.png` | PNG favicons. |
| `apple-touch-icon.png` | 180×180, the trail on #f4f7f5. |
| `icon-192.png`, `icon-512.png` | Manifest icons (`../site.webmanifest`), the trail on #f4f7f5. |
| `og-image.png` / `og-image-dark.png` | 1200×630 social cards on #fbfcfb / pine: wordmark and site description, with a six-track trail (1 0 1 1 0 1) walking up the right. |
| `_head.html` | The extra `<link>` tags, included on every page by `_quarto.yml`. |
| `reference/kit-navbar-test.png`, `reference/favicon-test.png`, `reference/site-render-test.png` | Test renders at 1x (100% zoom). Not published. |
| `reference/eco-brand-kit.png` | One-page overview. Not published. |
| `reference/build_kit.py`, `reference/make_reference.py`, `reference/og-card*.svg` | Build scripts and the OG cards' SVG sources. Not published. |

On pine the tracks and text turn mist. Small sizes are not the master scaled down: below 48px the kit switches to the tiled favicons, where the side toes are drawn exactly vertical and horizontal (in the master they are within 5° of that) so whole-pixel strokes land crisp, and the dashed track uses butt caps so its gaps stay open. The tile is there because pine tracks on a transparent ground vanish on dark browser tab strips.

To rebuild (needs fontTools, uharfbuzz, rsvg-convert, ImageMagick; Source Sans 3 from github.com/adobe-fonts/source-sans, OFL):

```bash
python3 site/logos/reference/build_kit.py --font OTF/SourceSans3-Bold.otf \
  --font-regular OTF/SourceSans3-Regular.otf --font-semibold OTF/SourceSans3-Semibold.otf
python3 site/logos/reference/make_reference.py   # google-chrome + Source Sans 3 installed locally
```

```html
<link rel="icon" href="/logos/favicon.ico" sizes="any">
<link rel="icon" type="image/png" sizes="32x32" href="/logos/favicon-32.png">
<link rel="icon" type="image/png" sizes="16x16" href="/logos/favicon-16.png">
<link rel="apple-touch-icon" href="/logos/apple-touch-icon.png">
<meta property="og:image" content="https://ben-domingue.github.io/eco/logos/og-image.png">
<meta name="twitter:card" content="summary_large_image">
```

On the site these come from `_quarto.yml` (`website.favicon`, `open-graph`, `twitter-card`) and `_head.html`; Quarto rewrites the root paths to page-relative ones, so they resolve under the `/eco/` prefix.
