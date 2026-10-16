#!/usr/bin/env python3
"""
Gera o visual do instalador (Anaconda) da Akari e monta o
disk_config/iso-personalizado.toml.

Como funciona: o kickstart da ISO ganha um %pre que, antes da interface
abrir, grava uma folha de estilo GTK + imagens em /run/install/updates.
O Anaconda carrega esse CSS por cima do dele (é o mesmo mecanismo do
updates.img), então o instalador fica preto e branco com a flor da Akari.
Se algo der errado, o %pre não trava nada: o instalador só fica com a
cara padrão do Fedora.

Uso (na raiz do repositório):
  python3 branding/fonte/gerar-instalador.py
"""
import base64
import importlib.util
import io
import pathlib
import tempfile

from PIL import Image
from playwright.sync_api import sync_playwright

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
spec = importlib.util.spec_from_file_location("assets", HERE / "gerar-assets.py")
assets = importlib.util.module_from_spec(spec)
spec.loader.exec_module(assets)

FONTES = f'@font-face{{font-family:"Fraktur";src:url("file://{HERE}/fonts/UnifrakturCook-Bold.woff2");font-weight:700}}'

SIDEBAR = f"""<!doctype html><html><head><meta charset="utf-8"><style>{FONTES}
html,body{{margin:0;width:300px;height:1200px;background:#050505;overflow:hidden}}
#halo{{position:absolute;left:-250px;top:-120px;width:800px;height:800px;border-radius:50%;
  background:radial-gradient(circle,rgba(255,255,255,.10) 0%,rgba(255,255,255,.03) 40%,rgba(255,255,255,0) 65%)}}
#kanji{{position:absolute;left:96px;top:520px;writing-mode:vertical-rl;font-family:"Noto Serif CJK JP";font-weight:900;font-size:120px;
  color:transparent;-webkit-text-stroke:1px rgba(255,255,255,.22);letter-spacing:.1em}}
#linha{{position:absolute;right:0;top:0;bottom:0;width:1px;background:linear-gradient(transparent,rgba(255,255,255,.35),transparent)}}
#sub{{position:absolute;left:0;right:0;bottom:60px;text-align:center;font-family:"DejaVu Sans Mono";font-size:11px;letter-spacing:.45em;color:rgba(255,255,255,.35)}}
</style></head><body><div id="halo"></div><div id="kanji">灯り</div><div id="linha"></div><div id="sub">INSTALAÇÃO</div></body></html>"""

LOGO = f"""<!doctype html><html><head><meta charset="utf-8"><style>{FONTES}
html,body{{margin:0;width:300px;height:330px;background:transparent;overflow:hidden}}
#flower{{position:absolute;left:60px;top:20px;width:180px;height:180px}}
#word{{position:absolute;left:0;right:0;top:200px;text-align:center;font-family:"Fraktur";font-weight:700;font-size:78px;color:#f2f2f2;
  text-shadow:0 0 24px rgba(255,255,255,.25)}}
</style></head><body><!--FLOR--><div id="word">akari</div></body></html>""".replace("<!--FLOR-->", assets.FLOR_INLINE)

TOPBAR = """<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0;width:1600px;height:80px;background:#0a0a0a;overflow:hidden}
#l{position:absolute;left:0;right:0;bottom:0;height:1px;background:linear-gradient(90deg,rgba(255,255,255,.4),rgba(255,255,255,.05))}
</style></head><body><div id="l"></div></body></html>"""

CSS = """/* Akari · visual do instalador (por cima do tema do Anaconda) */
.logo-sidebar {
  background-image: url("/run/install/updates/akari/sidebar.png");
  background-color: #050505;
  background-size: cover;
  background-position: left top;
}
.logo {
  background-image: url("/run/install/updates/akari/logo.png");
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center top;
}
AnacondaSpokeWindow #nav-box, #nav-box {
  background-image: url("/run/install/updates/akari/topbar.png");
  background-color: #0a0a0a;
  background-size: cover;
}
#nav-box label, #nav-box .titlelabel { color: #f2f2f2; }
#nav-box button { background-image: none; background-color: #f2f2f2; color: #0a0a0a; border-color: #f2f2f2; }
#nav-box button label { color: #0a0a0a; }
button.suggested-action, .suggested-action {
  background-image: none;
  background-color: #111111;
  color: #f7f7f7;
  border-color: #111111;
}
button.suggested-action label { color: #f7f7f7; }
"""


def png(pg, html, w, h, transparent=False) -> bytes:
    with tempfile.NamedTemporaryFile("w", suffix=".html", dir=HERE, delete=False) as f:
        f.write(html)
    try:
        pg.set_viewport_size({"width": w, "height": h})
        pg.goto(f"file://{f.name}")
        pg.evaluate("document.fonts.ready")
        pg.wait_for_timeout(500)
        raw = pg.screenshot(omit_background=transparent)
    finally:
        pathlib.Path(f.name).unlink()
    img = Image.open(io.BytesIO(raw))
    out = io.BytesIO()
    if transparent:
        img.save(out, "PNG", optimize=True)
    else:
        img.convert("RGB").quantize(64).save(out, "PNG", optimize=True)
    return out.getvalue()


def main():
    prev = ROOT / "branding/previews/instalador"
    prev.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page()
        imgs = {
            "sidebar.png": png(pg, SIDEBAR, 300, 1200),
            "logo.png": png(pg, LOGO, 300, 330, transparent=True),
            "topbar.png": png(pg, TOPBAR, 1600, 80),
        }
        b.close()
    for nome, dados in imgs.items():
        (prev / nome).write_bytes(dados)
        print(nome, len(dados), "bytes")

    linhas = ["%pre --log=/tmp/akari-visual.log", "# Visual da Akari no instalador (não trava nada se falhar)",
              "mkdir -p /run/install/updates/akari || exit 0"]
    for nome, dados in imgs.items():
        b64 = base64.b64encode(dados).decode()
        linhas.append(f"base64 -d > /run/install/updates/akari/{nome} <<'AKARI_FIM' || true")
        linhas += [b64[i:i + 76] for i in range(0, len(b64), 76)]
        linhas.append("AKARI_FIM")
    linhas.append("cat >> /run/install/updates/anaconda-gtk.css <<'AKARI_FIM' || true")
    linhas += CSS.rstrip("\n").split("\n")
    linhas.append("AKARI_FIM")
    linhas.append("exit 0")
    linhas.append("%end")
    pre = "\n".join(linhas)

    base = (ROOT / "disk_config/iso.toml").read_text()
    marca = 'contents = """\n'
    assert marca in base
    extra = ("lang pt_BR.UTF-8\n"
             "keyboard --vckeymap=br-abnt2 --xlayouts='br'\n"
             "timezone America/Sao_Paulo\n\n" + pre + "\n\n")
    out = base.replace("# Instalador (Anaconda) da Akari.",
                       "# Instalador PERSONALIZADO da Akari (gerado por branding/fonte/gerar-instalador.py).\n"
                       "# Igual ao iso.toml + português/Brasil pré-selecionado + visual preto e branco.", 1)
    out = out.replace(marca, marca + extra, 1)
    (ROOT / "disk_config/iso-personalizado.toml").write_text(out)
    print("disk_config/iso-personalizado.toml", len(out), "bytes")


if __name__ == "__main__":
    main()
