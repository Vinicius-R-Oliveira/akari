#!/usr/bin/env python3
"""
Gera os arquivos visuais da Akari a partir das fontes deste diretório:
  • wallpapers (4K)            → system_files/usr/share/akari/wallpapers/
  • fundo da Genkan/Hajime      → system_files/usr/share/akari/genkan/
  • avatar padrão               → system_files/usr/share/akari/logo/akari-avatar.png
  • ícone da Ichiba             → system_files/usr/share/icons/hicolor/...
  • quadros do boot (Plymouth)  → system_files/usr/share/plymouth/themes/akari/

Uso (na raiz do repositório):
  pip install playwright pillow && playwright install chromium
  python3 branding/fonte/gerar-assets.py
Precisa das fontes "Noto Serif CJK JP" instaladas no sistema.
"""
import pathlib
import re
import tempfile

from PIL import Image, ImageFilter, ImageEnhance
from playwright.sync_api import sync_playwright

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SF = ROOT / "system_files"
FLOR = (SF / "usr/share/akari/logo/akari-flor.svg").read_text()
FLOR_INLINE = re.sub(r"<svg [^>]*>", '<svg id="flower" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">', FLOR, count=1)
PETAL = "M0 -14 C-20 -30 -26 -58 -12 -76 L0 -66 L12 -76 C26 -58 20 -30 0 -14 Z"
ANGLES = [0, 72, 144, 216, 288]

WALLS = {"akari-01-hanami": "hanami.html", "akari-02-yoru": "yoru.html", "akari-03-hanabira": "hanabira.html"}


def shot(pg, html_path, out, w, h, transparent=False):
    pg.set_viewport_size({"width": w, "height": h})
    pg.goto(f"file://{html_path}")
    pg.evaluate("document.fonts.ready")
    pg.wait_for_timeout(700)
    pg.screenshot(path=str(out), omit_background=transparent)


def main():
    walls = SF / "usr/share/akari/wallpapers"
    genkan = SF / "usr/share/akari/genkan"
    plym = SF / "usr/share/plymouth/themes/akari"
    for d in (walls, genkan, plym):
        d.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p, tempfile.TemporaryDirectory(dir=HERE) as tmp:
        tmp = pathlib.Path(tmp)
        b = p.chromium.launch()
        pg = b.new_page()

        # ── Wallpapers ─────────────────────────────────────────
        for name, src in WALLS.items():
            html = (HERE / "wallpapers" / src).read_text().replace("<!--FLOR-->", FLOR_INLINE)
            html = html.replace('url("../fonts/', f'url("{HERE}/fonts/')
            f = tmp / f"{name}.html"
            f.write_text(html)
            png = tmp / f"{name}.png"
            shot(pg, f, png, 3840, 2160)
            Image.open(png).convert("RGB").save(walls / f"{name}.jpg", quality=94, subsampling=0)
            print("wallpaper", name)

        # ── Fundo da Genkan/Hajime: wallpaper principal desfocado e escurecido
        base = Image.open(tmp / "akari-01-hanami.png").convert("RGB").resize((1920, 1080), Image.LANCZOS)
        bg = base.filter(ImageFilter.GaussianBlur(28))
        bg = ImageEnhance.Brightness(bg).enhance(0.36)
        bg.save(genkan / "fundo.jpg", quality=92)

        # ── Avatar padrão (~/.face) ────────────────────────────
        av = tmp / "avatar.html"
        av.write_text(f"""<html><body style="margin:0;background:transparent">
          <div style="width:512px;height:512px;border-radius:50%;background:radial-gradient(circle at 50% 45%,#2a2a2a,#0a0a0a 70%);
          display:grid;place-items:center;overflow:hidden">
          <div style="width:380px;height:380px">{FLOR.replace('width="1024" height="1024"', 'width="380" height="380"')}</div></div></body></html>""")
        shot(pg, av, SF / "usr/share/akari/logo/akari-avatar.png", 512, 512, transparent=True)

        # ── Ícone da Ichiba: sacola em traço branco com a flor dentro ─
        ichiba_svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#202020"/><stop offset="1" stop-color="#090909"/></linearGradient>
    <radialGradient id="glow" cx="128" cy="150" r="70" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#fff" stop-opacity=".35"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>
  </defs>
  <rect x="8" y="8" width="240" height="240" rx="64" fill="url(#bg)"/>
  <rect x="8.75" y="8.75" width="238.5" height="238.5" rx="63.25" fill="none" stroke="#fff" stroke-opacity=".12" stroke-width="1.5"/>
  <path d="M60 94 H196 L186 206 Q185 214 177 214 H79 Q71 214 70 206 Z" fill="none" stroke="#fff" stroke-width="9" stroke-linejoin="round"/>
  <path d="M98 94 V80 Q98 50 128 50 Q158 50 158 80 V94" fill="none" stroke="#fff" stroke-width="9" stroke-linecap="round"/>
  <circle cx="128" cy="152" r="70" fill="url(#glow)"/>
  <g transform="translate(128 154) scale(.42)" fill="none" stroke="#fff" stroke-width="11" stroke-linejoin="round">
    {''.join(f'<path d="{PETAL}" transform="rotate({a})"/>' for a in ANGLES)}
  </g>
  <circle cx="128" cy="154.8" r="6" fill="#fff"/>
</svg>
"""
        icons = SF / "usr/share/icons/hicolor"
        (icons / "scalable/apps").mkdir(parents=True, exist_ok=True)
        (icons / "scalable/apps/ichiba.svg").write_text(ichiba_svg)
        ic = tmp / "ichiba.html"
        ic.write_text(f'<html><body style="margin:0;background:transparent">{ichiba_svg}</body></html>')
        (icons / "256x256/apps").mkdir(parents=True, exist_ok=True)
        shot(pg, ic, icons / "256x256/apps/ichiba.png", 256, 256, transparent=True)

        # ── Quadros do Plymouth: a flor se desenhando e acendendo ─
        css = (HERE / "gerar-logo.py").read_text().split('ANIM_CSS = """', 1)[1].split('"""', 1)[0]
        boot = tmp / "boot.html"
        flor_anim = FLOR.replace("</defs>", "</defs>" + css, 1).replace('width="1024" height="1024"', 'width="200" height="200"')
        boot.write_text(f'<html><body style="margin:0;background:transparent">{flor_anim}</body></html>')
        pg.set_viewport_size({"width": 200, "height": 200})
        pg.goto(f"file://{boot}")
        pg.wait_for_timeout(300)
        frames = 48
        for i in range(frames):
            t = 3300 * i / (frames - 1)
            pg.evaluate("t => document.getAnimations().forEach(a => { a.pause(); a.currentTime = t; })", t)
            pg.screenshot(path=str(plym / f"flor-{i:02d}.png"), omit_background=True)
        print("plymouth", frames, "quadros")

        # Barra de progresso (1 px, escalada pelo script do Plymouth)
        Image.new("RGBA", (4, 4), (255, 255, 255, 255)).save(plym / "barra.png")
        Image.new("RGBA", (4, 4), (255, 255, 255, 46)).save(plym / "trilho.png")
        Image.new("RGBA", (4, 4), (255, 255, 255, 255)).save(plym / "ponto.png")
        # ── PNGs do logo (todas as versões e tamanhos) ─────────
        logo_svg = ROOT / "branding/logo/svg"
        logo_png = ROOT / "branding/logo/png"
        logo_png.mkdir(parents=True, exist_ok=True)

        def svg_png(svg, out, w, h):
            page = tmp / "svg.html"
            page.write_text(f'<html><body style="margin:0;background:transparent">'
                            f'<img src="file://{svg}" style="width:{w}px;height:{h}px;display:block"></body></html>')
            shot(pg, page, out, w, h, transparent=True)

        for size in (1024, 512, 256):
            svg_png(logo_svg / "akari-flor.svg", logo_png / f"akari-flor-{size}.png", size, size)
        for cor in ("branco", "preto"):
            for size in (16, 32, 48, 64, 128, 256, 512):
                svg_png(logo_svg / f"akari-icone-{cor}.svg", logo_png / f"akari-icone-{cor}-{size}.png", size, size)
        vb = (logo_svg / "akari-logo-nome.svg").read_text().split('viewBox="')[1].split('"')[0].split()
        svg_png(logo_svg / "akari-logo-nome.svg", logo_png / "akari-logo-nome.png", int(float(vb[2]) * 4), 800)

        # cópias usadas pelo sistema
        import shutil
        shutil.copy(logo_png / "akari-flor-512.png", SF / "usr/share/akari/logo/akari-flor-512.png")
        shutil.copy(logo_png / "akari-icone-branco-256.png", SF / "usr/share/icons/hicolor/256x256/apps/akari-logo.png")
        print("logo PNGs")
        b.close()


if __name__ == "__main__":
    main()
