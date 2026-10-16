"""
Ichiba 市場 — lógica da loja: catálogo do Flathub, instalação via Flatpak,
atualizações do sistema (rpm-ostree) e cores do Caelestia.
"""
from __future__ import annotations

import gzip
import json
import os
import re
import shutil
import threading
import xml.etree.ElementTree as ET
from pathlib import Path

from PySide6.QtCore import (Property, QFileSystemWatcher, QObject, QProcess, QTimer, Signal, Slot)

HOME = Path.home()
CACHE = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache")) / "akari-ichiba"
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state"))
SCHEME = STATE / "caelestia/scheme.json"
ARCH = os.uname().machine
APPSTREAM_DIRS = [
    Path(f"/var/lib/flatpak/appstream/flathub/{ARCH}/active"),
    HOME / f".local/share/flatpak/appstream/flathub/{ARCH}/active",
]
DEMO = os.environ.get("AKARI_ICHIBA_DEMO") == "1" or shutil.which("flatpak") is None

CATEGORIES = [
    ("Game", "Jogos", "sports_esports"),
    ("AudioVideo", "Áudio e vídeo", "music_video"),
    ("Development", "Desenvolvimento", "code"),
    ("Graphics", "Gráficos", "palette"),
    ("Network", "Internet", "public"),
    ("Office", "Escritório", "description"),
    ("Education", "Educação", "school"),
    ("Science", "Ciência", "science"),
    ("System", "Sistema", "settings"),
    ("Utility", "Utilitários", "handyman"),
]

COLLECTIONS = [
    ("Para jogar", "sports_esports", [
        "net.davidotek.pupgui2", "net.lutris.Lutris", "com.usebottles.bottles", "org.prismlauncher.PrismLauncher",
        "dev.vencord.Vesktop", "com.discordapp.Discord", "io.github.radiolamp.mangojuice", "com.heroicgameslauncher.hgl",
    ]),
    ("Para programar", "terminal", [
        "com.getpostman.Postman", "com.usebruno.Bruno", "io.dbeaver.DBeaverCommunity", "io.github.shiftey.Desktop",
        "io.podman_desktop.PodmanDesktop", "rest.insomnia.Insomnia", "com.jetbrains.IntelliJ-IDEA-Community", "dev.zed.Zed",
    ]),
    ("Para criar", "brush", [
        "com.obsproject.Studio", "org.kde.kdenlive", "org.gimp.GIMP", "org.kde.krita",
        "org.blender.Blender", "org.inkscape.Inkscape", "com.github.PintaProject.Pinta", "org.audacityteam.Audacity",
    ]),
    ("Essenciais", "star", [
        "com.github.tchx84.Flatseal", "io.github.flattool.Warehouse", "com.spotify.Client", "org.videolan.VLC",
        "md.obsidian.Obsidian", "org.libreoffice.LibreOffice", "org.telegram.desktop", "com.bitwarden.desktop",
    ]),
]

# Tema monocromático usado se o Caelestia ainda não gerou as cores
DEFAULT_COLOURS = {
    "background": "#0d0d0d", "surface": "#0d0d0d", "surfaceContainerLowest": "#000000",
    "surfaceContainerLow": "#141414", "surfaceContainer": "#181818", "surfaceContainerHigh": "#222222",
    "surfaceContainerHighest": "#2c2c2c", "onSurface": "#e6e6e6", "onSurfaceVariant": "#a8a8a8",
    "outline": "#777777", "outlineVariant": "#3a3a3a", "primary": "#f2f2f2", "onPrimary": "#111111",
    "primaryContainer": "#3d3d3d", "onPrimaryContainer": "#f2f2f2", "secondaryContainer": "#333333",
    "onSecondaryContainer": "#ececec", "error": "#f2b8b5", "onError": "#601410",
}


# ─────────────────────────────── Tema ───────────────────────────────
class Theme(QObject):
    changed = Signal()

    def __init__(self):
        super().__init__()
        self._c = dict(DEFAULT_COLOURS)
        self._dark = True
        self._watch = QFileSystemWatcher(self)
        self._watch.directoryChanged.connect(lambda *_: QTimer.singleShot(250, self.load))
        self._watch.fileChanged.connect(lambda *_: QTimer.singleShot(250, self.load))
        if SCHEME.parent.exists():
            self._watch.addPath(str(SCHEME.parent))
        self.load()

    @Slot()
    def load(self):
        try:
            data = json.loads(SCHEME.read_text())
            cols = data.get("colours", {})
            merged = dict(DEFAULT_COLOURS)
            for k, v in cols.items():
                if isinstance(v, str) and re.fullmatch(r"[0-9a-fA-F]{6}", v):
                    merged[k] = "#" + v
            self._c = merged
            self._dark = data.get("mode", "dark") != "light"
            if SCHEME.exists() and str(SCHEME) not in self._watch.files():
                self._watch.addPath(str(SCHEME))
        except (OSError, ValueError):
            pass
        self.changed.emit()

    @Property("QVariantMap", notify=changed)
    def c(self):
        return self._c

    @Property(bool, notify=changed)
    def dark(self):
        return self._dark


# ─────────────────────────────── Catálogo ───────────────────────────────
def _text(el):
    return "".join(el.itertext()).strip() if el is not None else ""


def _localized(comp, tag):
    """Prefere pt_BR, depois pt, depois o texto padrão (sem idioma)."""
    best = {}
    for el in comp.findall(tag):
        lang = el.get("{http://www.w3.org/XML/1998/namespace}lang") or ""
        best.setdefault(lang, el)
    for lang in ("pt_BR", "pt-BR", "pt", ""):
        if lang in best:
            return best[lang]
    return next(iter(best.values()), None)


def _description(comp):
    """Converte a descrição (p/ul/li) em texto simples com parágrafos."""
    desc = _localized(comp, "description")
    if desc is None:
        return ""
    parts = []
    for child in desc:
        if child.tag == "p":
            parts.append(_text(child))
        elif child.tag in ("ul", "ol"):
            parts.extend("•  " + _text(li) for li in child.findall("li"))
    return "\n\n".join(p for p in parts if p)


def parse_appstream(folder: Path) -> list[dict]:
    path = folder / "appstream.xml.gz"
    opener = gzip.open
    if not path.exists():
        path, opener = folder / "appstream.xml", open
    apps = []
    with opener(path, "rb") as fh:
        for _, comp in ET.iterparse(fh):
            if comp.tag != "component":
                continue
            if comp.get("type") not in ("desktop", "desktop-application", "console-application"):
                comp.clear()
                continue
            bundle = comp.find("bundle")
            ref = bundle.text if bundle is not None and bundle.text else ""
            app_id = ref.split("/")[1] if ref.count("/") >= 2 else (comp.findtext("id") or "").removesuffix(".desktop")
            if not app_id:
                comp.clear()
                continue
            icon = ""
            for ic in comp.findall("icon"):
                if ic.get("type") == "cached" and ic.text:
                    size = ic.get("height") or "64"
                    cand = folder / "icons" / f"{size}x{size}" / ic.text
                    if cand.exists() and (not icon or size == "128"):
                        icon = str(cand)
                elif ic.get("type") == "remote" and ic.text and not icon:
                    icon = ic.text
            shots = []
            for sc in comp.findall("screenshots/screenshot"):
                imgs = sc.findall("image")
                pick = next((i for i in imgs if i.get("type") == "source"), None) or \
                    max(imgs, key=lambda i: int(i.get("width") or 0), default=None)
                if pick is not None and pick.text:
                    shots.append(pick.text.strip())
                if len(shots) >= 5:
                    break
            rel = comp.find("releases/release")
            dev = comp.find("developer/name")
            apps.append({
                "id": app_id,
                "name": _text(_localized(comp, "name")) or app_id,
                "summary": _text(_localized(comp, "summary")),
                "description": _description(comp),
                "icon": icon,
                "categories": [c.text for c in comp.findall("categories/category") if c.text],
                "developer": _text(dev) if dev is not None else (comp.findtext("developer_name") or ""),
                "license": comp.findtext("project_license") or "",
                "homepage": next((u.text for u in comp.findall("url") if u.get("type") == "homepage" and u.text), ""),
                "version": rel.get("version", "") if rel is not None else "",
                "screenshots": shots,
                "verified": any(v.get("key") == "flathub::verification::verified" and (v.text or "") == "true"
                                for v in comp.findall("custom/value")),
            })
            comp.clear()
    apps.sort(key=lambda a: a["name"].lower())
    return apps


def demo_catalog() -> list[dict]:
    rows = [
        ("com.heroicgameslauncher.hgl", "Heroic Games Launcher", "Jogos da Epic, GOG e Amazon", ["Game"]),
        ("net.davidotek.pupgui2", "ProtonUp-Qt", "Instale e gerencie versões do Proton", ["Game", "Utility"]),
        ("net.lutris.Lutris", "Lutris", "Sua biblioteca de jogos em um só lugar", ["Game"]),
        ("com.usebottles.bottles", "Bottles", "Rode programas do Windows", ["Utility"]),
        ("dev.vencord.Vesktop", "Vesktop", "Discord com Vencord, mais leve", ["Network"]),
        ("com.obsproject.Studio", "OBS Studio", "Gravação e transmissão ao vivo", ["AudioVideo"]),
        ("org.gimp.GIMP", "GIMP", "Editor de imagens", ["Graphics"]),
        ("org.blender.Blender", "Blender", "Modelagem e animação 3D", ["Graphics"]),
        ("com.getpostman.Postman", "Postman", "Plataforma para testar APIs", ["Development"]),
        ("io.dbeaver.DBeaverCommunity", "DBeaver", "Cliente universal de banco de dados", ["Development"]),
        ("com.github.tchx84.Flatseal", "Flatseal", "Gerencie as permissões dos Flatpaks", ["Utility"]),
        ("com.spotify.Client", "Spotify", "Música e podcasts", ["AudioVideo"]),
        ("md.obsidian.Obsidian", "Obsidian", "Notas em Markdown conectadas", ["Office"]),
        ("org.videolan.VLC", "VLC", "Toca qualquer vídeo", ["AudioVideo"]),
    ]
    return [{
        "id": i, "name": n, "summary": s, "categories": c, "icon": "", "developer": "Demonstração",
        "license": "GPL-3.0", "homepage": "https://flathub.org", "version": "1.0", "screenshots": [], "verified": True,
        "description": f"{n}: {s}.\n\nEste é um catálogo de demonstração (o Flatpak não foi encontrado).",
    } for i, n, s, c in rows]


class Store(QObject):
    catalogChanged = Signal()
    installedChanged = Signal()
    updatesChanged = Signal()
    jobsChanged = Signal()
    systemChanged = Signal()
    loadingChanged = Signal()
    message = Signal(str)
    _parsed = Signal(list)

    def __init__(self):
        super().__init__()
        self._apps: list[dict] = []
        self._by_id: dict[str, dict] = {}
        self._installed: dict[str, dict] = {}
        self._updates: list[dict] = []
        self._jobs: dict[str, dict] = {}
        self._system: dict = {}
        self._loading = False
        self._procs: list[QProcess] = []
        self._parsed.connect(self._on_parsed)

    # ── propriedades para o QML ─────────────────────────────
    @Property("QVariantList", notify=catalogChanged)
    def apps(self):
        return self._apps

    @Property("QVariantList", constant=True)
    def categories(self):
        return [{"id": i, "name": n, "icon": ic} for i, n, ic in CATEGORIES]

    @Property("QVariantList", notify=catalogChanged)
    def collections(self):
        out = []
        for title, icon, ids in COLLECTIONS:
            items = [self._by_id[i] for i in ids if i in self._by_id]
            if items:
                out.append({"title": title, "icon": icon, "apps": items[:8]})
        return out

    @Property("QVariantMap", notify=installedChanged)
    def installed(self):
        return self._installed

    @Property("QVariantList", notify=installedChanged)
    def installedList(self):
        rows = []
        for app_id, info in self._installed.items():
            meta = self._by_id.get(app_id, {})
            rows.append({**meta, **info, "id": app_id, "name": meta.get("name") or info.get("name") or app_id})
        return sorted(rows, key=lambda r: r["name"].lower())

    @Property("QVariantList", notify=updatesChanged)
    def updates(self):
        return self._updates

    @Property("QVariantMap", notify=jobsChanged)
    def jobs(self):
        return self._jobs

    @Property("QVariantMap", notify=systemChanged)
    def system(self):
        return self._system

    @Property(bool, notify=loadingChanged)
    def loading(self):
        return self._loading

    @Property(bool, constant=True)
    def demo(self):
        return DEMO

    # ── busca ─────────────────────────────────────────────
    @Slot(str, str, result="QVariantList")
    def search(self, text, category):
        text = (text or "").strip().lower()
        res = []
        for a in self._apps:
            if category and category not in a["categories"]:
                continue
            if text:
                hay = f'{a["name"]} {a["summary"]} {a["id"]} {a["developer"]}'.lower()
                if not all(w in hay for w in text.split()):
                    continue
            res.append(a)
        if text:
            res.sort(key=lambda a: (not a["name"].lower().startswith(text), text not in a["name"].lower()))
        return res[:240]

    @Slot(str, result="QVariantMap")
    def app(self, app_id):
        return self._by_id.get(app_id) or {"id": app_id, "name": app_id, "summary": "", "description": "",
                                            "icon": "", "categories": [], "screenshots": []}

    # ── carregar catálogo ─────────────────────────────────
    def _set_loading(self, v):
        self._loading = v
        self.loadingChanged.emit()

    @Slot()
    def start(self):
        self.load_catalog()
        self.refresh_installed()
        self.refresh_system()
        # Atualiza os metadados do Flathub em segundo plano
        QTimer.singleShot(1500, self.refresh_appstream)

    def _appstream_folder(self):
        for d in APPSTREAM_DIRS:
            if (d / "appstream.xml.gz").exists() or (d / "appstream.xml").exists():
                return d
        return None

    @Slot()
    def load_catalog(self):
        if DEMO:
            self._on_parsed(demo_catalog())
            return
        folder = self._appstream_folder()
        if folder is None:
            self.message.emit("Baixando o catálogo do Flathub…")
            return
        src = folder / ("appstream.xml.gz" if (folder / "appstream.xml.gz").exists() else "appstream.xml")
        cache = CACHE / f"catalog-{int(src.stat().st_mtime)}.json"
        if cache.exists():
            try:
                self._on_parsed(json.loads(cache.read_text()))
                return
            except ValueError:
                pass
        self._set_loading(True)

        def work():
            try:
                apps = parse_appstream(folder)
                CACHE.mkdir(parents=True, exist_ok=True)
                for old in CACHE.glob("catalog-*.json"):
                    old.unlink(missing_ok=True)
                cache.write_text(json.dumps(apps, ensure_ascii=False))
            except Exception as e:  # noqa: BLE001
                print("ichiba: erro lendo o catálogo:", e)
                apps = []
            self._parsed.emit(apps)

        threading.Thread(target=work, daemon=True).start()

    def _on_parsed(self, apps):
        self._apps = apps
        self._by_id = {a["id"]: a for a in apps}
        self._set_loading(False)
        self.catalogChanged.emit()
        self.installedChanged.emit()

    @Slot()
    def refresh_appstream(self):
        if DEMO:
            return
        self._run(["flatpak", "update", "--appstream", "--noninteractive"], on_done=lambda ok, out: self.load_catalog())

    # ── processos ─────────────────────────────────────────
    def _run(self, cmd, on_done=None, on_line=None):
        p = QProcess(self)
        p.setProcessChannelMode(QProcess.MergedChannels)
        buf = []
        state = {"done": False}

        def read():
            data = bytes(p.readAll()).decode(errors="replace")
            buf.append(data)
            if on_line:
                for line in re.split(r"[\r\n]+", data):
                    if line.strip():
                        on_line(line)

        def done(code, _status):
            if state["done"]:
                return
            state["done"] = True
            read()
            if p in self._procs:
                self._procs.remove(p)
            if on_done:
                on_done(code == 0, "".join(buf))
            p.deleteLater()

        p.readyRead.connect(read)
        p.finished.connect(done)
        p.errorOccurred.connect(lambda e: done(1, None) if e == QProcess.FailedToStart else None)
        self._procs.append(p)
        p.start(cmd[0], cmd[1:])
        return p

    # ── instalados e atualizações ──────────────────────────
    @Slot()
    def refresh_installed(self):
        if DEMO:
            if not self._installed:
                self._installed = {"com.heroicgameslauncher.hgl": {"version": "2.18", "installation": "system"}}
            self._updates = [{"id": "com.heroicgameslauncher.hgl", "name": "Heroic Games Launcher", "version": "2.19"}]
            self.installedChanged.emit()
            self.updatesChanged.emit()
            return

        def parsed(ok, out):
            inst = {}
            for line in out.splitlines():
                cols = line.split("\t")
                if len(cols) >= 4 and "." in cols[0]:
                    inst[cols[0]] = {"name": cols[1], "version": cols[2], "installation": cols[3]}
            self._installed = inst
            self.installedChanged.emit()
            self.refresh_updates()

        self._run(["flatpak", "list", "--app", "--columns=application,name,version,installation"], on_done=parsed)

    @Slot()
    def refresh_updates(self):
        if DEMO:
            return

        def parsed(ok, out):
            ups = []
            for line in out.splitlines():
                cols = line.split("\t")
                if cols and "." in cols[0] and cols[0] in self._installed:
                    meta = self._by_id.get(cols[0], {})
                    ups.append({"id": cols[0], "name": meta.get("name", cols[0]), "icon": meta.get("icon", ""),
                                "version": cols[1] if len(cols) > 1 else ""})
            self._updates = ups
            self.updatesChanged.emit()

        self._run(["flatpak", "remote-ls", "--updates", "--app", "--columns=application,version"], on_done=parsed)

    # ── ações ─────────────────────────────────────────────
    def _job(self, app_id, kind, cmd, ok_msg, fail_msg):
        if app_id in self._jobs:
            return
        self._jobs[app_id] = {"kind": kind, "progress": -1}
        self.jobsChanged.emit()

        def line(text):
            m = re.findall(r"(\d{1,3})%", text)
            if m:
                self._jobs[app_id] = {"kind": kind, "progress": min(100, int(m[-1]))}
                self.jobsChanged.emit()

        def done(ok, out):
            self._jobs.pop(app_id, None)
            self.jobsChanged.emit()
            name = self._by_id.get(app_id, {}).get("name", app_id)
            self.message.emit((ok_msg if ok else fail_msg).format(name=name))
            if not ok:
                print(out)
            self.refresh_installed()

        if DEMO:
            def fake(step=0):
                if step > 10:
                    if kind == "remove":
                        self._installed.pop(app_id, None)
                    else:
                        self._installed[app_id] = {"version": "1.0", "installation": "system"}
                    done(True, "")
                    return
                self._jobs[app_id] = {"kind": kind, "progress": step * 10}
                self.jobsChanged.emit()
                QTimer.singleShot(120, lambda: fake(step + 1))
            fake()
            return
        self._run(cmd, on_done=done, on_line=line)

    @Slot(str)
    def install(self, app_id):
        self._job(app_id, "install",
                  ["flatpak", "install", "--system", "-y", "--noninteractive", "flathub", app_id],
                  "{name} instalado", "Não foi possível instalar {name}")

    @Slot(str)
    def remove(self, app_id):
        self._job(app_id, "remove",
                  ["flatpak", "uninstall", "-y", "--noninteractive", app_id],
                  "{name} removido", "Não foi possível remover {name}")

    @Slot(str)
    def update(self, app_id):
        self._job(app_id, "update",
                  ["flatpak", "update", "-y", "--noninteractive", app_id],
                  "{name} atualizado", "Não foi possível atualizar {name}")

    @Slot()
    def updateAll(self):
        for u in list(self._updates):
            self.update(u["id"])

    @Slot(str)
    def launch(self, app_id):
        QProcess.startDetached("flatpak", ["run", app_id])

    @Slot(str)
    def openUrl(self, url):
        QProcess.startDetached("xdg-open", [url])

    # ── sistema (rpm-ostree / bootc) ───────────────────────
    def _os_release(self):
        info = {}
        try:
            for line in Path("/etc/os-release").read_text().splitlines():
                if "=" in line:
                    k, v = line.split("=", 1)
                    info[k] = v.strip().strip('"')
        except OSError:
            pass
        return info

    @Slot()
    def refresh_system(self):
        osr = self._os_release()
        base = {"name": osr.get("PRETTY_NAME", "Akari"), "build": osr.get("AKARI_BUILD_DATE", ""),
                "busy": False, "status": "", "staged": False, "image": "", "deployed": "", "rollback": False}
        if DEMO or shutil.which("rpm-ostree") is None:
            base.update(image="ghcr.io/seu-usuario/akari:latest", deployed="2026-10-15", status="Sistema em dia")
            self._system = base
            self.systemChanged.emit()
            return

        def parsed(ok, out):
            try:
                data = json.loads(out[out.index("{"):])
                deps = data.get("deployments", [])
                booted = next((d for d in deps if d.get("booted")), {})
                staged = next((d for d in deps if d.get("staged")), None)
                base["image"] = booted.get("container-image-reference", "").split(":", 1)[-1]
                ts = booted.get("timestamp")
                if ts:
                    import datetime
                    base["deployed"] = datetime.datetime.fromtimestamp(ts).strftime("%d/%m/%Y %H:%M")
                base["staged"] = staged is not None
                base["rollback"] = len(deps) > 1 and not staged
                base["status"] = "Atualização pronta: reinicie para aplicar" if staged else "Sistema em dia"
            except (ValueError, KeyError):
                base["status"] = "Não foi possível ler o estado do sistema"
            self._system = base
            self.systemChanged.emit()

        self._run(["rpm-ostree", "status", "--json"], on_done=parsed)

    def _sys_busy(self, text):
        self._system = {**self._system, "busy": True, "status": text}
        self.systemChanged.emit()

    @Slot()
    def checkSystemUpdate(self):
        self._sys_busy("Procurando atualização…")

        def done(ok, out):
            if "AvailableUpdate" in out or "Diff:" in out:
                st = "Há uma nova versão da Akari disponível"
            elif ok:
                st = "Você já está na versão mais recente"
            else:
                st = "Não foi possível verificar (sem internet?)"
            self._system = {**self._system, "busy": False, "status": st}
            self.systemChanged.emit()

        if DEMO:
            QTimer.singleShot(800, lambda: done(True, ""))
            return
        self._run(["rpm-ostree", "upgrade", "--check"], on_done=done)

    @Slot()
    def upgradeSystem(self):
        self._sys_busy("Baixando a nova versão… (você pode continuar usando o PC)")

        def done(ok, _out):
            self._system = {**self._system, "busy": False}
            self.systemChanged.emit()
            self.message.emit("Atualização pronta: reinicie quando quiser" if ok else "A atualização falhou")
            self.refresh_system()

        if DEMO:
            QTimer.singleShot(1200, lambda: done(True, ""))
            return
        self._run(["rpm-ostree", "upgrade"], on_done=done)

    @Slot()
    def rollbackSystem(self):
        self._sys_busy("Preparando a versão anterior…")

        def done(ok, _out):
            self.message.emit("Versão anterior escolhida: reinicie para voltar" if ok else "Não foi possível voltar")
            self.refresh_system()

        if DEMO:
            QTimer.singleShot(800, lambda: done(True, ""))
            return
        self._run(["rpm-ostree", "rollback"], on_done=done)

    @Slot()
    def reboot(self):
        if not DEMO:
            QProcess.startDetached("systemctl", ["reboot"])
