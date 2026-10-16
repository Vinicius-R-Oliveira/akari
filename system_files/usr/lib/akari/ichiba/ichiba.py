#!/usr/bin/env python3
"""Ichiba 市場 — a loja de apps da Akari."""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from PySide6.QtCore import QUrl  # noqa: E402
from PySide6.QtGui import QFontDatabase, QGuiApplication, QIcon  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402

from backend import Store, Theme  # noqa: E402

HERE = Path(__file__).resolve().parent


def main():
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Ichiba")
    app.setApplicationDisplayName("Ichiba")
    app.setOrganizationName("Akari")
    # No Wayland o app_id vem daqui (usado pelas regras de janela do Hyprland)
    app.setDesktopFileName("ichiba")
    app.setWindowIcon(QIcon.fromTheme("ichiba"))

    # Fontes da Akari, caso não estejam instaladas no sistema (ex.: testes)
    for f in os.environ.get("ICHIBA_EXTRA_FONTS", "").split(":"):
        if f:
            QFontDatabase.addApplicationFont(f)

    theme = Theme()
    store = Store()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("theme", theme)
    engine.rootContext().setContextProperty("store", store)
    engine.load(QUrl.fromLocalFile(str(HERE / "qml" / "Main.qml")))
    if not engine.rootObjects():
        sys.exit(1)

    store.start()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
