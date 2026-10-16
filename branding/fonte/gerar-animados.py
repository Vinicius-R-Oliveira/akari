#!/usr/bin/env python3
"""
Gera os wallpapers ANIMADOS da Akari:
  • vídeo em loop (MP4, 1080p)  → system_files/usr/share/akari/wallpapers/animados/<nome>.mp4
  • capa 4K (JPG) para o seletor → system_files/usr/share/akari/wallpapers/<nome>.jpg
Ao escolher a capa no seletor do Caelestia, a Akari troca para o vídeo sozinha
(veja /usr/libexec/akari/akari-wallpaper-hook).

Uso (na raiz do repositório):
  pip install playwright pillow && playwright install chromium   (e ffmpeg instalado)
  python3 branding/fonte/gerar-animados.py            # todos
  python3 branding/fonte/gerar-animados.py akari-10-ame   # só um
"""
import importlib.util
import json
import pathlib
import subprocess
import sys
import tempfile

from PIL import Image
from playwright.sync_api import sync_playwright

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("assets", HERE / "gerar-assets.py")
assets = importlib.util.module_from_spec(spec)
spec.loader.exec_module(assets)

SF = assets.SF
SRC = HERE / "wallpapers" / "animados"
OUT_IMG = SF / "usr/share/akari/wallpapers"
OUT_VID = OUT_IMG / "animados"

LOOP = 16   # segundos (igual ao comum.js)
FPS = 24

# nome → (HTML, variante de cor do Caelestia, modo)
ANIMADOS = {
    "akari-08-hanami-ugoki": ("hanami-ugoki.html", "monochrome", "dark"),
    "akari-09-yozakura":     ("yozakura.html", "monochrome", "dark"),
    "akari-10-ame":          ("ame.html", "monochrome", "dark"),
    "akari-11-mangetsu":     ("mangetsu.html", "monochrome", "dark"),
    "akari-12-fubuki":       ("fubuki.html", "tonalspot", "dark"),
}


def preparar(html_path: pathlib.Path, tmp: pathlib.Path) -> pathlib.Path:
    html = html_path.read_text()
    for marca, svg in assets.FLORES.items():
        html = html.replace(marca, svg)
    html = html.replace('url("../../fonts/', f'url("{HERE}/fonts/').replace('url("../fonts/', f'url("{HERE}/fonts/')
    html = html.replace('src="comum.js"', f'src="file://{SRC}/comum.js"')
    out = tmp / html_path.name
    out.write_text(html)
    return out


def main():
    only = [a for a in sys.argv[1:] if not a.startswith("-")]
    OUT_VID.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p, tempfile.TemporaryDirectory(dir=HERE) as tmp:
        tmp = pathlib.Path(tmp)
        b = p.chromium.launch()
        for nome, (src, _variant, _mode) in ANIMADOS.items():
            if only and nome not in only:
                continue
            page_file = preparar(SRC / src, tmp)

            # ── capa 4K ──
            ctx = b.new_context(viewport={"width": 1920, "height": 1080}, device_scale_factor=2)
            pg = ctx.new_page()
            pg.goto(f"file://{page_file}")
            pg.evaluate("document.fonts.ready")
            pg.wait_for_timeout(900)
            pg.evaluate("t => akariSeek(t)", LOOP * 1000 * 0.3)
            png = tmp / f"{nome}.png"
            pg.screenshot(path=str(png))
            Image.open(png).convert("RGB").save(OUT_IMG / f"{nome}.jpg", quality=93, subsampling=0)
            ctx.close()
            if "--so-capa" in sys.argv:
                print(nome, "capa")
                continue

            # ── vídeo em loop ──
            ctx = b.new_context(viewport={"width": 1920, "height": 1080})
            pg = ctx.new_page()
            pg.goto(f"file://{page_file}")
            pg.evaluate("document.fonts.ready")
            pg.wait_for_timeout(900)
            mp4 = OUT_VID / f"{nome}.mp4"
            ff = subprocess.Popen([
                "ffmpeg", "-v", "error", "-y", "-f", "image2pipe", "-framerate", str(FPS), "-c:v", "mjpeg", "-i", "-",
                "-c:v", "libx264", "-preset", "slow", "-crf", "24", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
                "-an", str(mp4)], stdin=subprocess.PIPE)
            total = LOOP * FPS
            for i in range(total):
                pg.evaluate("t => akariSeek(t)", i * 1000 / FPS)
                ff.stdin.write(pg.screenshot(type="jpeg", quality=92))
            ff.stdin.close()
            ff.wait()
            ctx.close()
            print(nome, f"{mp4.stat().st_size / 1e6:.1f} MB")
        b.close()

    # Junta os temas dos animados no temas.json
    temas_path = OUT_IMG / "temas.json"
    temas = json.loads(temas_path.read_text()) if temas_path.exists() else {}
    for nome, (_src, variant, mode) in ANIMADOS.items():
        temas[f"{nome}.jpg"] = {"variant": variant, "mode": mode, "video": f"animados/{nome}.mp4"}
    temas_path.write_text(json.dumps(temas, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
