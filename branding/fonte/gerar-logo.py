"""Gera os SVGs do logo da Akari (flor sakura minimalista, preto e branco, com luz).
Depois rode gerar-assets.py para exportar os PNGs."""
import math, os, pathlib
from fontTools.ttLib import TTFont, TTCollection
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

OUT = pathlib.Path(__file__).resolve().parent.parent / "logo"  # branding/logo
(OUT / "svg").mkdir(parents=True, exist_ok=True)

PETAL = "M0 -14 C-20 -30 -26 -58 -12 -76 L0 -66 L12 -76 C26 -58 20 -30 0 -14 Z"
# traços brancos dentro da pétala: nervura central + duas laterais
VEIN_C = "M0 -24 L0 -57"
VEIN_L = "M-4 -30 Q-11 -44 -10 -58"
VEIN_R = "M4 -30 Q11 -44 10 -58"
ANGLES = [0, 72, 144, 216, 288]


def defs(uid=""):
    return f"""
  <defs>
    <radialGradient id="halo{uid}" cx="0" cy="0" r="98" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#fff" stop-opacity=".32"/>
      <stop offset=".45" stop-color="#fff" stop-opacity=".08"/>
      <stop offset="1" stop-color="#fff" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="paper{uid}" cx="0" cy="0" r="78" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#fff" stop-opacity=".7"/>
      <stop offset=".3" stop-color="#f2f2f2" stop-opacity=".3"/>
      <stop offset=".7" stop-color="#bdbdbd" stop-opacity=".08"/>
      <stop offset="1" stop-color="#8a8a8a" stop-opacity=".04"/>
    </radialGradient>
    <radialGradient id="core{uid}" cx="0" cy="0" r="12" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#fff"/>
      <stop offset=".7" stop-color="#fafafa"/>
      <stop offset="1" stop-color="#d9d9d9"/>
    </radialGradient>
    <filter id="bloom{uid}" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="3.2"/>
    </filter>
    <filter id="bloomBig{uid}" x="-80%" y="-80%" width="260%" height="260%">
      <feGaussianBlur stdDeviation="9"/>
    </filter>
  </defs>"""


def petals(cls="", fill=None, stroke="#fff", sw=4.5, extra=""):
    out = []
    for i, a in enumerate(ANGLES):
        f = f'fill="{fill}"' if fill else 'fill="none"'
        out.append(f'<path class="{cls} p{i}" d="{PETAL}" transform="rotate({a})" {f} '
                   f'stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" {extra}/>')
    return "\n      ".join(out)


def veins(cls="vein"):
    out = []
    for i, a in enumerate(ANGLES):
        for d, w, o in ((VEIN_C, 1.9, .95), (VEIN_L, 1.3, .6), (VEIN_R, 1.3, .6)):
            out.append(f'<path class="{cls} v{i}" d="{d}" transform="rotate({a})" fill="none" '
                       f'stroke="#fff" stroke-opacity="{o}" stroke-width="{w}" stroke-linecap="round" pathLength="1"/>')
    return "\n      ".join(out)


def stamens(cls="stamen"):
    out = []
    for i, a in enumerate(ANGLES):
        a2 = a + 36
        x = 19 * math.sin(math.radians(a2)); y = -19 * math.cos(math.radians(a2))
        out.append(f'<g class="{cls} s{i}"><line x1="0" y1="0" x2="{x:.2f}" y2="{y:.2f}" stroke="#fff" '
                   f'stroke-opacity=".75" stroke-width="1.2" stroke-linecap="round"/>'
                   f'<circle cx="{x:.2f}" cy="{y:.2f}" r="1.9" fill="#fff"/></g>')
    return "\n      ".join(out)


def flower_body(uid="", anim=False):
    pl = 'pathLength="1"'
    return f"""
    <g transform="translate(100 102)">
      <circle class="halo" r="98" fill="url(#halo{uid})"/>
      <g class="glowfill" opacity="1">
      {petals("fill", fill=f"url(#paper{uid})", stroke="none", sw=0)}
      </g>
      <g class="bloom" filter="url(#bloom{uid})" opacity=".6">
      {petals("bl", stroke="#fff", sw=5, extra=pl)}
      </g>
      <g class="lines">
      {petals("ol", stroke="#fff", sw=4.6, extra=pl)}
      </g>
      <circle class="corehalo" r="26" fill="#fff" opacity=".55" filter="url(#bloomBig{uid})"/>
      <circle class="core" r="10" fill="url(#core{uid})"/>
    </g>"""


def svg_full():
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="1024" height="1024">
  <title>Akari — logo</title>{defs()}
  {flower_body()}
</svg>
"""


def svg_icon(color="#fff", dot=True):
    ps = "\n    ".join(f'<path d="{PETAL}" transform="rotate({a})"/>' for a in ANGLES)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="256" height="256">
  <title>Akari — ícone</title>
  <g transform="translate(100 102)" fill="none" stroke="{color}" stroke-width="9" stroke-linejoin="round">
    {ps}
  </g>
  <circle cx="100" cy="102" r="12" fill="{color}"/>
</svg>
"""


# ---------- texto -> path ----------
def text_path(fontfile, text, size, x, y, tracking=0.0, ttc_match=None):
    if ttc_match:
        coll = TTCollection(fontfile)
        font = next(f for f in coll.fonts if ttc_match in f["name"].getDebugName(4))
    else:
        font = TTFont(fontfile)
    gs = font.getGlyphSet(); cmap = font.getBestCmap()
    upm = font["head"].unitsPerEm; s = size / upm
    parts = []; cx = x
    for ch in text:
        g = cmap[ord(ch)]
        pen = SVGPathPen(gs)
        gs[g].draw(TransformPen(pen, (s, 0, 0, -s, cx, y)))
        parts.append(pen.getCommands())
        cx += gs[g].width * s + tracking * size
    return " ".join(parts), cx - tracking * size - x


def vtext_path(fontfile, text, size, x, y, ttc_match):
    coll = TTCollection(fontfile)
    font = next(f for f in coll.fonts if ttc_match in f["name"].getDebugName(4))
    gs = font.getGlyphSet(); cmap = font.getBestCmap(); upm = font["head"].unitsPerEm; s = size / upm
    parts = []; cy = y
    for ch in text:
        g = cmap[ord(ch)]; pen = SVGPathPen(gs)
        gs[g].draw(TransformPen(pen, (s, 0, 0, -s, x, cy + size * .88)))
        parts.append(pen.getCommands()); cy += size * 1.02
    return " ".join(parts)


INTER = "/usr/share/fonts/opentype/inter/Inter-Light.otf"
NOTO = "/usr/share/fonts/opentype/noto/NotoSerifCJK-Light.ttc"
WORD, WORD_W = text_path(INTER, "akari", 64, 0, 0, tracking=0.30)
KANJI = vtext_path(NOTO, "灯り", 22, 0, 0, "Noto Serif CJK JP Light")


def svg_wordmark():
    # flor 200 + gap + palavra + divisória + kanji
    fx = 0; wx = 205; wy = 124
    kx = wx + WORD_W + 26
    W = int(kx + 30)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} 200" width="{W*3}" height="600">
  <title>Akari — logo com nome</title>{defs()}
  <g transform="translate({fx} 0)">{flower_body()}</g>
  <path d="{WORD}" transform="translate({wx} {wy})" fill="#fff"/>
  <line x1="{kx-12}" y1="78" x2="{kx-12}" y2="128" stroke="#fff" stroke-opacity=".35" stroke-width="1"/>
  <path d="{KANJI}" transform="translate({kx-3} 78)" fill="#fff" fill-opacity=".8"/>
</svg>
"""


ANIM_CSS = """
  <style>
    /* 0.0s pétalas se desenham → 1.6s nervuras → 2.2s acende o centro → 2.6s a luz enche as pétalas → 3.2s nome → loop respirando */
    .ol, .bl { stroke-dasharray: 1; stroke-dashoffset: 1; animation: draw 1.4s cubic-bezier(.6,.05,.3,1) forwards; }
    .p0{animation-delay:.10s}.p1{animation-delay:.28s}.p2{animation-delay:.46s}.p3{animation-delay:.64s}.p4{animation-delay:.82s}
    .vein { stroke-dasharray: 1; stroke-dashoffset: 1; animation: draw .9s ease-out forwards; }
    .v0{animation-delay:1.55s}.v1{animation-delay:1.65s}.v2{animation-delay:1.75s}.v3{animation-delay:1.85s}.v4{animation-delay:1.95s}
    .stamen { opacity: 0; animation: fade .6s ease-out forwards; animation-delay: 2.2s; }
    .core { transform: scale(0); animation: pop .7s cubic-bezier(.3,1.6,.5,1) forwards 2.15s; }
    .corehalo { opacity: 0; animation: ignite 1.2s ease-out forwards 2.25s, breathe 4s ease-in-out infinite 3.6s; }
    .glowfill, .halo { opacity: 0; animation: fill 1.6s ease-out forwards 2.5s; }
    .bloom { opacity: 0; animation: fill 1.2s ease-out forwards .9s; }
    .word { opacity: 0; animation: word 1.4s ease-out forwards 3.1s; }
    @keyframes draw { to { stroke-dashoffset: 0; } }
    @keyframes fade { to { opacity: 1; } }
    @keyframes pop { to { transform: scale(1); } }
    @keyframes ignite { 0%{opacity:0} 40%{opacity:1} 100%{opacity:.55} }
    @keyframes fill { to { opacity: 1; } }
    @keyframes breathe { 0%,100%{opacity:.55} 50%{opacity:.9} }
    @keyframes word { from { opacity: 0; transform: translateY(8px); letter-spacing: 0 } to { opacity: 1; transform: translateY(0) } }
  </style>"""


def svg_anim():
    wx = (400 - WORD_W * .55) / 2
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 330" width="800" height="660" style="background:#000">
  <title>Akari — animação do login</title>{defs()}{ANIM_CSS}
  <rect width="400" height="330" fill="#000"/>
  <g transform="translate(100 10)">{flower_body()}</g>
  <g class="word"><path d="{WORD}" transform="translate({wx:.1f} 278) scale(.55)" fill="#fff"/></g>
</svg>
"""


files = {
    "svg/akari-flor.svg": svg_full(),
    "svg/akari-icone-branco.svg": svg_icon("#fff"),
    "svg/akari-icone-preto.svg": svg_icon("#000"),
    "svg/akari-logo-nome.svg": svg_wordmark(),
    "svg/akari-login-animacao.svg": svg_anim(),
}
for name, content in files.items():
    (OUT / name).write_text(content, encoding="utf-8")
print("ok", list(files))
