#!/usr/bin/env python3
"""Test renders for the eco logo kit, written to site/logos/reference/.
Not published. Needs google-chrome (headless) and Source Sans 3 installed
locally (fc-list | grep "Source Sans 3"), since the mock navbars and tabs
use live text.

    python3 site/logos/reference/make_reference.py
"""
import os, subprocess, tempfile, base64

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.dirname(HERE)
CHROME = os.environ.get("CHROME", "google-chrome")

def uri(name):
    p = os.path.join(KIT, name)
    mime = "image/svg+xml" if p.endswith(".svg") else "image/png"
    return f"data:{mime};base64," + base64.b64encode(open(p, "rb").read()).decode()

def shot(html, out, w, h, scale=1):
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as fh:
        fh.write(html); src = fh.name
    subprocess.run([CHROME, "--headless=new", "--no-sandbox", "--disable-gpu", "--hide-scrollbars",
                    f"--force-device-scale-factor={scale}", f"--window-size={w},{h}",
                    f"--screenshot={out}", "file://" + src], check=True, capture_output=True)
    os.remove(src)

CSS = """
body{margin:0;font-family:'Source Sans 3',sans-serif;background:#fff;color:#222}
.nav{background:#1f3d2f;color:#f3f6f4;display:flex;align-items:center;height:56px;padding:0 16px;position:relative;border-bottom:1px solid #fff}
.nav .brand{display:flex;align-items:center;gap:8px;font-weight:700;font-size:1.25rem;letter-spacing:.02em;margin-right:24px}
.nav .links{display:flex;gap:22px;font-size:1rem;flex:1}
.nav .links span::after{content:' \\25BE';font-size:.7em;opacity:.8}
.nav .links span.n::after{content:''}
.nav .right{display:flex;gap:16px;align-items:center;opacity:.9}
.tag{position:absolute;right:6px;top:2px;font-size:10px;color:#9fb8aa}
.burger{font-size:24px;margin-left:auto}
"""
SEARCH = '<svg width="16" height="16" viewBox="0 0 16 16"><circle cx="6.5" cy="6.5" r="5" stroke="#f3f6f4" stroke-width="1.6" fill="none"/><path d="M10.2 10.2L15 15" stroke="#f3f6f4" stroke-width="1.8"/></svg>'
GH = '<svg width="18" height="18" viewBox="0 0 16 16"><circle cx="8" cy="8" r="7.5" fill="#f3f6f4"/></svg>'

def navbar_test():
    rows = []
    def row(brand, tag, phone=False):
        links = ('<div class="burger">&#9776;</div>' if phone else
                 '<div class="links"><span>Data</span><span>Use it</span><span>The format</span>'
                 '<span class="n">About</span></div>'
                 f'<div class="right">{SEARCH}{GH}</div>')
        w = "width:390px;" if phone else ""
        rows.append(f'<div class="nav" style="{w}"><div class="brand">{brand}</div>{links}'
                    f'<span class="tag">{tag}</span></div>')
    lock = uri("eco-lockup-dark.svg"); icon = uri("eco-icon-dark.svg")
    row(f'<img src="{lock}" style="height:36px">', "lockup, 36px (chosen)")
    row(f'<img src="{lock}" style="height:30px">', "lockup, 30px")
    row(f'<img src="{lock}" style="height:24px">', "lockup, 24px (Quarto default max-height)")
    row(f'<img src="{icon}" style="height:30px">eco', "icon 30px + text title")
    row('eco', "before: text title only")
    row(f'<img src="{lock}" style="height:36px">', "phone 390px, lockup 36px", phone=True)
    html = f"<html><head><style>{CSS}</style></head><body>{''.join(rows)}</body></html>"
    shot(html, os.path.join(HERE, "kit-navbar-test.png"), 1000, 57 * 6)

def favicon_test():
    f16, f32 = uri("favicon-16.png"), uri("favicon-32.png")
    tabs = ""
    for bar, tab, idle, fg in (("#dee1e6", "#fff", "#dee1e6", "#202124"), ("#202124", "#35363a", "#202124", "#e8eaed")):
        tabs += f'<div style="background:{bar};padding:8px 8px 0;display:flex;gap:4px">'
        for i, t in enumerate(("eco", "eco - Browse the tables")):
            bgc = tab if i == 0 else idle
            tabs += (f'<div style="background:{bgc};color:{fg};padding:8px 12px;border-radius:8px 8px 0 0;'
                     f'display:flex;align-items:center;gap:8px;width:210px;font-size:13px">'
                     f'<img src="{f16}" width="16" height="16">{t}</div>')
        tabs += "</div>"
    pix = "image-rendering:pixelated"
    cell = lambda img, lab, bg="#fff", fg="#222": (
        f'<div style="background:{bg};color:{fg};padding:6px;font-size:12px;font-weight:600">{img}<div>{lab}</div></div>')
    grid = ('<div style="display:flex;gap:10px;align-items:flex-end;padding:10px">'
            + cell(f'<img src="{f16}" width="16">', "16 @1x")
            + cell(f'<img src="{f16}" width="128" style="{pix}">', "16 @8x")
            + cell(f'<img src="{f32}" width="32">', "32 @1x")
            + cell(f'<img src="{f32}" width="128" style="{pix}">', "32 @4x")
            + cell(f'<img src="{f16}" width="128" style="{pix}">', "16 @8x on dark", "#202124", "#e8eaed")
            + cell(f'<img src="{uri("apple-touch-icon.png")}" width="90">', "touch icon @0.5x")
            + "</div>")
    html = f"<html><head><style>{CSS}</style></head><body>{tabs}{grid}</body></html>"
    shot(html, os.path.join(HERE, "favicon-test.png"), 760, 290)

def brand_kit():
    sw = lambda c, n: (f'<div class="sw"><div class="dot" style="background:{c}"></div>'
                       f'<b>{n}</b><span>{c.upper()}</span></div>')
    f16 = uri("favicon-16.png")
    html = f"""<html><head><style>
body{{margin:0;background:#fbfcfb;font-family:'Source Sans 3',sans-serif;color:#1f3d2f;padding:56px 64px;width:1552px}}
h1{{font-size:56px;margin:0 0 6px;font-weight:700}} .lead{{font-size:22px;color:#3d5a4b;max-width:1250px;margin:0 0 28px}}
h2{{font-size:15px;letter-spacing:.14em;text-transform:uppercase;color:#3d5a4b;margin:0 0 18px;font-weight:600}}
section{{border-top:1px solid #dfe7e2;padding:28px 0}}
.cols{{display:grid;grid-template-columns:1fr 1fr 1fr;gap:0}} .cols>div{{text-align:center;padding:10px 20px;border-left:1px solid #dfe7e2}}
.cols>div:first-child{{border:0}} .cap b{{display:block;letter-spacing:.12em;font-size:14px;margin-top:18px}}
.cap{{font-size:16px;color:#3d5a4b}}
.dark{{background:#1f3d2f;border-radius:12px;padding:26px 28px;display:flex;align-items:center;gap:60px;color:#f3f6f4}}
.mock{{border:1px solid #dfe7e2;border-radius:10px;overflow:hidden;background:#fff}}
.sw{{display:inline-block;text-align:center;margin-right:14px;font-size:15px}} .sw span{{display:block;font-size:13px;color:#55705f}}
.dot{{width:72px;height:72px;border-radius:50%;border:2px solid #1f3d2f;margin:0 auto 8px}}
</style></head><body>
<h1>eco logo &amp; brand kit</h1>
<p class="lead">A walking trail of four bird tracks, read as the capture history <b>1&nbsp;0&nbsp;1&nbsp;1</b>.
The faded track is a survey that missed an animal that was there: imperfect detection, the idea the project is built around.</p>
<section><h2>Primary lockup</h2><div style="text-align:center;padding:16px 0"><img src="{uri('eco-lockup.svg')}" style="height:210px"></div></section>
<section><h2>Scaling &amp; variations</h2><div class="cols">
<div><img src="{uri('eco-icon.svg')}" style="height:150px"><div class="cap"><b>ICON</b>The trail, four tracks.<br>Use at 48px and up.</div></div>
<div><img src="{uri('eco-wordmark.svg')}" style="height:150px;padding-top:0"><div class="cap"><b>WORDMARK</b>Source Sans 3 Bold, outlined.</div></div>
<div><div style="height:150px;display:flex;align-items:center;justify-content:center;gap:26px">
<img src="{uri('eco-favicon-32.svg')}" style="width:96px;image-rendering:pixelated"><img src="{uri('eco-favicon-16.svg')}" style="width:64px">
<img src="{uri('favicon-32.png')}" width="32"><img src="{f16}" width="16"></div>
<div class="cap"><b>FAVICONS</b>Hand-tuned 32 (solid + faded) and 16 (one)<br>on a pine tile, shown large and at 1x.</div></div>
</div></section>
<section style="border:0"><div class="dark"><div style="font-size:15px;letter-spacing:.14em;font-weight:600;align-self:flex-start;color:#9fb8aa">DARK</div>
<img src="{uri('eco-lockup-dark.svg')}" style="height:140px"><img src="{uri('eco-icon-dark.svg')}" style="height:120px;margin-left:auto"></div></section>
<section><h2>Example mockups</h2><div style="display:grid;grid-template-columns:1.3fr 1fr;gap:36px">
<div><div class="mock"><div style="background:#e8ece9;padding:8px 12px;font-size:0">
<span style="display:inline-block;width:11px;height:11px;border-radius:50%;background:#ec6a5e;margin-right:7px"></span><span style="display:inline-block;width:11px;height:11px;border-radius:50%;background:#f4bf4f;margin-right:7px"></span><span style="display:inline-block;width:11px;height:11px;border-radius:50%;background:#61c554"></span></div>
<div style="background:#1f3d2f;height:56px;display:flex;align-items:center;padding:0 18px;gap:24px;color:#f3f6f4;font-size:17px">
<img src="{uri('eco-lockup-dark.svg')}" style="height:36px;margin-right:12px"><span>Data</span><span>Use it</span><span>The format</span><span>About</span></div>
<div style="height:60px"></div></div><div class="cap" style="text-align:left;margin-top:12px"><b style="margin:0">WEBSITE HEADER</b>Dark lockup at 36px on the pine navbar.</div></div>
<div><div class="mock" style="background:#dee1e6;padding:10px 10px 0"><div style="display:flex;gap:6px">
<div style="background:#fff;border-radius:8px 8px 0 0;padding:9px 14px;display:flex;gap:8px;align-items:center;font-size:14px;width:200px"><img src="{f16}" width="16" height="16">eco</div></div>
<div style="background:#fff;padding:10px"><div style="background:#f1f3f4;border-radius:16px;padding:7px 14px;font-size:14px">ben-domingue.github.io/eco</div></div></div>
<div class="cap" style="text-align:left;margin-top:12px"><b style="margin:0">BROWSER TAB FAVICON</b>Hand-tuned 16px favicon.</div></div>
</div></section>
<section><div style="display:grid;grid-template-columns:1fr 1fr;gap:40px">
<div><h2>Typography</h2><div style="font-size:72px;font-weight:700;line-height:1">Source Sans 3</div>
<div class="cap" style="text-align:left;margin-top:10px">Bold, slight negative tracking, in the wordmark (outlined).<br>The site sets everything in Source Sans 3.</div>
<div style="font-size:22px;letter-spacing:.08em;margin-top:14px;font-weight:700">ABCDEFGHIJKLM abcdefghijklm 0123456789</div></div>
<div><h2>Colour</h2>{sw('#1f3d2f','Pine')}{sw('#f3f6f4','Mist')}{sw('#f4f7f5','Ground')}{sw('#bfd3c7','Faded')}{sw('#4f7a64','Faded on pine')}{sw('#2f6b4f','Forest')}{sw('#b0522a','Rust')}
<div class="cap" style="text-align:left;margin-top:14px">Pine marks on light grounds, mist on pine; the missed track is faded (#BFD3C7 / #4F7A64). Forest and rust are accents, never in the mark.</div></div>
</div></section>
<section><h2>Social card</h2><img src="{uri('og-image.png')}" style="width:700px;border:1px solid #dfe7e2;border-radius:8px;margin-right:24px"><img src="{uri('og-image-dark.png')}" style="width:700px;border-radius:8px"></section>
</body></html>"""
    shot(html, os.path.join(HERE, "eco-brand-kit.png"), 1680, 2330)

if __name__ == "__main__":
    navbar_test(); favicon_test(); brand_kit()
    print("reference renders in", HERE)
