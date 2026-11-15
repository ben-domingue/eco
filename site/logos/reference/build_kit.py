#!/usr/bin/env python3
"""Build the eco logo kit (site/logos/) from the design constants below.

The design is the "Bird feet" mark: four bird tracks walking bottom-left to
top-right, read as the capture history 1 0 1 1 (the faded track is a survey
that missed an animal that was there). This script only refines the hand-off
masters: tight viewBoxes, outlined text, pixel-tuned favicons, rasters.

Usage (from the repo root):
    python3 site/logos/reference/build_kit.py --font path/to/SourceSans3-Bold.otf \
        [--font-regular path/to/SourceSans3-Regular.otf]

Needs fontTools, uharfbuzz, rsvg-convert and ImageMagick (`convert`).
Source Sans 3 is OFL: github.com/adobe-fonts/source-sans (release branch, OTF/).
The reference/ test renders are made separately by make_reference.py.
"""
import argparse, math, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.dirname(HERE)                      # site/logos/

# ---- colours (site/custom.scss) ---------------------------------------------
PINE = "#1f3d2f"      # tracks + text, light backgrounds; also the navbar
MIST = "#f3f6f4"      # tracks + text on pine
FADE = "#bfd3c7"      # the missed track on light grounds
FADE_DARK = "#4f7a64" # the missed track on pine
FADED = {PINE: FADE, MIST: FADE_DARK}   # detected colour -> missed colour
BG_TOUCH = "#f4f7f5"  # apple-touch-icon / manifest icons
BG_OG = "#fbfcfb"     # light OG card
FOREST = "#2f6b4f"    # accent
RUST = "#b0522a"      # accent

# ---- the track glyph (100-unit icon box, before the 0.95 scale) -------------
TOES = [((0, 6), (0, -13)), ((0, 3), (-10, -9)), ((0, 3), (10, -9)), ((0, 6), (0, 13))]
# A missed track is the same glyph at the same stroke width, solid, in the
# faded colour (it replaced the hand-off's thinner dashed track, which at large
# sizes read as a different, thinner bird rather than a missed one).
SW_SOLID = 4.4
SCALE = 0.95
# Four tracks evenly spaced on (16,86)->(84,16), offset 8 at right angles,
# alternating; detected = 1, missed = 0. Same transforms as the hand-off master.
def trail_positions(p0=(16, 86), p1=(84, 16), n=4, off=8.0):
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    L = math.hypot(dx, dy)
    # the master offsets along (-1,-1)/sqrt2 first, then (+1,+1)/sqrt2
    nx, ny = -1 / math.sqrt(2), -1 / math.sqrt(2)
    out = []
    for i in range(n):
        t = i / (n - 1)
        s = 1 if i % 2 == 0 else -1
        out.append((p0[0] + t * dx + s * off * nx, p0[1] + t * dy + s * off * ny))
    return out
HISTORY = [1, 0, 1, 1]

def f(v):
    s = f"{v:.3f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s

def rot(x, y, deg):
    a = math.radians(deg)
    return x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a)

def track_bbox(tx, ty, scale, sw, deg=45):
    r = sw / 2 * scale
    xs, ys = [], []
    for a, b in TOES:
        for (x, y) in (a, b):
            X, Y = rot(x * scale, y * scale, deg)
            xs += [tx + X - r, tx + X + r]; ys += [ty + Y - r, ty + Y + r]
    return min(xs), min(ys), max(xs), max(ys)

def union(bbs):
    return (min(b[0] for b in bbs), min(b[1] for b in bbs),
            max(b[2] for b in bbs), max(b[3] for b in bbs))

TOE_D = "".join(f"M{f(a[0])} {f(a[1])}L{f(b[0])} {f(b[1])}" for a, b in TOES)

def track_svg(tx, ty, hit, col, scale=SCALE, deg=45):
    tr = f'translate({f(tx)} {f(ty)}) rotate({f(deg)}) scale({f(scale)})'
    c = col if hit else FADED[col]
    return (f'<path transform="{tr}" d="{TOE_D}" fill="none" stroke="{c}" '
            f'stroke-width="{SW_SOLID}" stroke-linecap="round"/>')

def trail(col, positions=None, history=HISTORY, scale=SCALE, dx=0, dy=0):
    positions = positions or trail_positions()
    body = "".join(track_svg(x + dx, y + dy, h, col, scale) for (x, y), h in zip(positions, history))
    bb = union([track_bbox(x + dx, y + dy, scale, SW_SOLID) for (x, y) in positions])
    return body, bb

# ---- text to outlines --------------------------------------------------------
class Font:
    def __init__(self, path):
        import uharfbuzz as hb
        from fontTools.ttLib import TTFont
        self.hb = hb
        data = open(path, "rb").read()
        self.hbfont = hb.Font(hb.Face(data))
        self.tt = TTFont(path)
        self.upem = self.tt["head"].unitsPerEm
        self.gs = self.tt.getGlyphSet()
        self.order = self.tt.getGlyphOrder()

    def path(self, text, x, y, size, tracking=0.0):
        """Outline `text` with its baseline at (x, y). tracking in user units
        between letters (CSS letter-spacing). Returns (d, bbox)."""
        from fontTools.pens.svgPathPen import SVGPathPen
        from fontTools.pens.transformPen import TransformPen
        from fontTools.pens.boundsPen import BoundsPen
        hb = self.hb
        buf = hb.Buffer(); buf.add_str(text); buf.guess_segment_properties()
        hb.shape(self.hbfont, buf, {"kern": True, "liga": True})
        k = size / self.upem
        pen_x = x
        ds, bbs = [], []
        n = len(buf.glyph_infos)
        for i, (info, pos) in enumerate(zip(buf.glyph_infos, buf.glyph_positions)):
            name = self.order[info.codepoint]
            gx, gy = pen_x + pos.x_offset * k, y - pos.y_offset * k
            T = (k, 0, 0, -k, gx, gy)
            sp = SVGPathPen(self.gs, ntos=lambda v: f(v))
            self.gs[name].draw(TransformPen(sp, T))
            ds.append(sp.getCommands())
            bp = BoundsPen(self.gs); self.gs[name].draw(bp)
            if bp.bounds:
                x0, y0, x1, y1 = bp.bounds
                bbs.append((gx + x0 * k, gy - y1 * k, gx + x1 * k, gy - y0 * k))
            pen_x += pos.x_advance * k + (tracking if i < n - 1 else 0)
        return "".join(ds), union(bbs), pen_x

# ---- SVG wrapper -------------------------------------------------------------
def svg_doc(bb, body, title, pad=0.0, w=None, h=None, exact=False):
    x0, y0, x1, y1 = bb
    if exact:
        vb = f"{f(x0)} {f(y0)} {f(x1 - x0)} {f(y1 - y0)}"
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" role="img" '
                f'aria-labelledby="t"><title id="t">{title}</title>{body}</svg>\n')
    x0 = math.floor((x0 - pad) * 10) / 10; y0 = math.floor((y0 - pad) * 10) / 10
    x1 = math.ceil((x1 + pad) * 10) / 10; y1 = math.ceil((y1 + pad) * 10) / 10
    vb = f"{f(x0)} {f(y0)} {f(x1 - x0)} {f(y1 - y0)}"
    size = f' width="{w}" height="{h}"' if w else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}"{size} role="img" '
            f'aria-labelledby="t"><title id="t">{title}</title>{body}</svg>\n')

# Wordmark placement, as in the hand-off lockup: "eco" at x=118, baseline 78,
# 96 units, letter-spacing -1.
WM = dict(x=118, y=78, size=96, tracking=-1)

# ---- favicons: hand-tuned on a pixel grid -------------------------------------
# After rotate(45) the two side toes of the glyph run within 5 degrees of
# vertical and horizontal, so on a pixel grid they are drawn exactly vertical
# and horizontal (whole-pixel strokes land crisp); the shaft (hind toe +
# centre toe) stays on the 45-degree diagonal. Toe proportions follow the
# glyph: side toe L, centre toe ~0.72 L beyond the branch, hind ~0.45 L behind.
#
# Both favicons sit on a rounded pine tile with light tracks: transparent pine
# tracks vanish on dark browser tab strips (see reference/favicon-test.png).
def px_track(B, L, C, H, col, sw):
    bx, by = B
    segs = [((bx, by - L), (bx, by)), ((bx + L, by), (bx, by)), ((bx + C, by - C), (bx - H, by + H))]
    d = "".join(f"M{f(a[0])} {f(a[1])}L{f(b[0])} {f(b[1])}" for a, b in segs)
    return f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{f(sw)}" stroke-linecap="round"/>'

# The missed track on the 32px tile; tuned against the 1x render.
FAV_FADE = FADE_DARK

def favicon32():
    body = (f'<rect width="32" height="32" rx="6" fill="{PINE}"/>'
            + px_track((7, 25), 8, 6, 3, MIST, 2)
            + px_track((20, 12), 8, 6, 3, FAV_FADE, 2))
    return svg_doc((0, 0, 32, 32), body, "eco")

def favicon16():
    # Two tracks (solid + faded) were tried at 16 px and read as one track plus
    # a smudge; the brief's fallback, a single solid track, is used.
    body = f'<rect width="16" height="16" rx="3" fill="{PINE}"/>' + px_track((6, 10), 7, 5, 3, MIST, 2)
    return svg_doc((0, 0, 16, 16), body, "eco")

# ---- build -------------------------------------------------------------------
def write(name, text):
    with open(os.path.join(KIT, name), "w") as fh:
        fh.write(text)

def rsvg(src, out, w, h=None, bg=None):
    cmd = ["rsvg-convert", "-w", str(w), "-h", str(h or w), "-a"]
    if bg: cmd += ["-b", bg]
    subprocess.run(cmd + [src, "-o", out], check=True)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--font", required=True, help="SourceSans3-Bold.otf")
    ap.add_argument("--font-regular", help="SourceSans3-Regular.otf (OG card description)")
    ap.add_argument("--font-semibold", help="SourceSans3-Semibold.otf (OG card kicker)")
    a = ap.parse_args()
    bold = Font(a.font)

    # icon
    for suffix, col in (("", PINE), ("-dark", MIST)):
        body, bb = trail(col)
        write(f"eco-icon{suffix}.svg", svg_doc(bb, body, "eco"))
    # wordmark
    d, tbb, _ = bold.path("eco", WM["x"], WM["y"], WM["size"], WM["tracking"])
    for suffix, col in (("", PINE), ("-dark", MIST)):
        write(f"eco-wordmark{suffix}.svg", svg_doc(tbb, f'<path d="{d}" fill="{col}"/>', "eco"))
    # lockup
    for suffix, col in (("", PINE), ("-dark", MIST)):
        body, bb = trail(col)
        write(f"eco-lockup{suffix}.svg",
              svg_doc(union([bb, tbb]), body + f'<path d="{d}" fill="{col}"/>', "eco"))
    # favicons
    write("eco-favicon-32.svg", favicon32())
    write("eco-favicon-16.svg", favicon16())
    k = lambda n: os.path.join(KIT, n)
    rsvg(k("eco-favicon-16.svg"), k("favicon-16.png"), 16)
    rsvg(k("eco-favicon-32.svg"), k("favicon-32.png"), 32)
    tmp48 = k("reference/_favicon-48.png")
    rsvg(k("eco-favicon-32.svg"), tmp48, 48)
    subprocess.run(["convert", k("favicon-16.png"), k("favicon-32.png"), tmp48, k("favicon.ico")], check=True)
    os.remove(tmp48)

    # app icons: the full trail on a light square (pine tracks need a ground)
    body, bb = trail(PINE)
    cx, cy = (bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2
    for name, size, frac in (("apple-touch-icon.png", 180, 0.70), ("icon-192.png", 192, 0.70),
                             ("icon-512.png", 512, 0.70)):
        half = max(bb[2] - bb[0], bb[3] - bb[1]) / frac / 2
        sq = (cx - half, cy - half, cx + half, cy + half)
        src = os.path.join(HERE, "_tmp.svg")
        open(src, "w").write(svg_doc(sq, f'<rect x="{f(sq[0])}" y="{f(sq[1])}" width="{f(2*half)}" '
                                         f'height="{f(2*half)}" fill="{BG_TOUCH}"/>' + body, "eco", exact=True))
        rsvg(src, k(name), size)
        os.remove(src)

    # OG cards
    reg = Font(a.font_regular) if a.font_regular else bold
    semi = Font(a.font_semibold) if a.font_semibold else bold
    for suffix, bg, fg, sub, rule in (("", BG_OG, PINE, "#3d5a4b", FOREST), ("-dark", PINE, MIST, "#c9d8cf", "#8fb3a0")):
        svg = og_card(bold, reg, semi, bg, fg, sub, rule)
        src = os.path.join(HERE, f"og-card{suffix}.svg")   # kept as the card's source
        open(src, "w").write(svg)
        rsvg(src, k(f"og-image{suffix}.png"), 1200, 630)
    print("built", KIT)

OG_DESC = ["Ecological detection data in one format:",
           "occupancy surveys, repeated counts and",
           "capture histories from public deposits,",
           "validated and versioned."]
OG_HISTORY = [1, 0, 1, 1, 0, 1]   # the mark's 1 0 1 1, walking on

def og_card(bold, reg, semi, bg, fg, sub, rule):
    """1200x630 card: wordmark and the site description on the left, a larger
    trail (same glyph, same 45-degree heading, same stride) walking up the
    right-hand side."""
    W, H = 1200, 630
    parts = [f'<rect width="{W}" height="{H}" fill="{bg}"/>']
    s = 3.3                                  # track scale (mark: 0.95)
    step = 32.06 / 0.95 * s                  # mark spacing along the line, per unit scale
    off = 8 / 0.95 * s
    n = len(OG_HISTORY)
    c = (880, 322)                           # centre of the trail
    half = step * (n - 1) / 2 / math.sqrt(2)
    p0 = (c[0] - half, c[1] + half); p1 = (c[0] + half, c[1] - half)
    pos = trail_positions(p0, p1, n, off)
    parts += [track_svg(x, y, h, fg, scale=s) for (x, y), h in zip(pos, OG_HISTORY)]
    tb = union([track_bbox(x, y, s, SW_SOLID) for (x, y) in pos])
    assert tb[0] > 600 and tb[1] >= 50 and tb[2] <= W - 50 and tb[3] <= H - 50, tb
    # wordmark
    d, bb, _ = bold.path("eco", 0, 0, 190, -2)
    tx = 84 - bb[0]
    d, bb, _ = bold.path("eco", tx, 236, 190, -2)
    parts.append(f'<path d="{d}" fill="{fg}"/>')
    parts.append(f'<rect x="88" y="290" width="64" height="5" rx="2.5" fill="{rule}"/>')
    for j, line in enumerate(OG_DESC):
        d2, _, _ = reg.path(line, 86, 356 + j * 44, 33)
        parts.append(f'<path d="{d2}" fill="{sub}"/>')
    d3, _, _ = semi.path("ben-domingue.github.io/eco", 86, 566, 25)
    parts.append(f'<path d="{d3}" fill="{rule}"/>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
            f'role="img" aria-labelledby="t"><title id="t">eco: ecological detection data</title>'
            + "".join(parts) + "</svg>\n")

if __name__ == "__main__":
    main()
