// ─────────────────────────────────────────────────────────────
//  Ichiba 市場 — a loja de apps da Akari
//  Visual no estilo do Caelestia: barra de navegação à esquerda,
//  painel arredondado e as cores do wallpaper (Material You).
// ─────────────────────────────────────────────────────────────
import QtQuick
import QtQuick.Window
import "components"
import "pages"

Window {
    id: win

    width: 1280
    height: 820
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    title: "Ichiba"
    color: theme.c.surface

    // Navegação compartilhada entre as páginas
    QtObject {
        id: navigator

        property string page: "home"
        property string appId: ""
        property string query: ""
        property string category: ""
        property var history: []

        function go(p) {
            if (p === page)
                return;
            history = history.concat([page]);
            page = p;
        }
        function open(id) {
            appId = id;
            go("details");
        }
        function back() {
            if (!history.length) {
                page = "home";
                return;
            }
            const h = history.slice();
            page = h.pop();
            history = h;
        }
    }

    Shortcut {
        sequences: [StandardKey.Back, "Escape"]
        enabled: navigator.page === "details"
        onActivated: navigator.back()
    }
    Shortcut {
        sequences: [StandardKey.Find]
        onActivated: search.focusInput()
    }

    // ── Barra lateral ──────────────────────────────────────
    Column {
        id: rail
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 96
        topPadding: 20
        spacing: 10

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56
            height: 56
            radius: 18
            color: theme.c.primaryContainer

            Image {
                anchors.centerIn: parent
                width: 34
                height: 34
                source: "file:///usr/share/akari/logo/akari-icone-branco.svg"
                sourceSize.width: 68
                sourceSize.height: 68
                visible: status === Image.Ready
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: navigator.go("home")
            }
        }

        Item { width: 1; height: 14 }

        Repeater {
            model: [
                { id: "home", icon: "home", label: "Início" },
                { id: "explore", icon: "explore", label: "Explorar" },
                { id: "installed", icon: "download_done", label: "Instalados" },
                { id: "updates", icon: "update", label: "Atualizar" },
                { id: "system", icon: "memory", label: "Sistema" }
            ]
            NavItem {
                required property var modelData
                anchors.horizontalCenter: parent.horizontalCenter
                icon: modelData.icon
                label: modelData.label
                active: navigator.page === modelData.id || (navigator.page === "details" && modelData.id === navigator.history[navigator.history.length - 1])
                badge: modelData.id === "updates" ? store.updates.length : 0
                onClicked: navigator.go(modelData.id)
            }
        }
    }

    // ── Painel principal ───────────────────────────────────
    Rectangle {
        id: panel
        anchors.left: rail.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.leftMargin: 0
        radius: 28
        color: theme.c.surfaceContainer

        SearchBar {
            id: search
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 20
            width: Math.min(parent.width - 48, 620)
            text: navigator.query
            onEdited: t => {
                navigator.query = t;
                if (t.length && navigator.page !== "explore")
                    navigator.go("explore");
            }
        }

        Loader {
            id: pageLoader
            anchors.top: search.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 24
            anchors.topMargin: 20
            sourceComponent: {
                switch (navigator.page) {
                case "explore": return explorePage;
                case "installed": return installedPage;
                case "updates": return updatesPage;
                case "system": return systemPage;
                case "details": return detailsPage;
                default: return homePage;
                }
            }
            onLoaded: fade.restart()
            NumberAnimation {
                id: fade
                target: pageLoader.item
                property: "opacity"
                from: 0
                to: 1
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Component { id: homePage; HomePage { nav: navigator } }
        Component { id: explorePage; ExplorePage { nav: navigator } }
        Component { id: installedPage; InstalledPage { nav: navigator } }
        Component { id: updatesPage; UpdatesPage { nav: navigator } }
        Component { id: systemPage; SystemPage { nav: navigator } }
        Component { id: detailsPage; DetailsPage { nav: navigator } }

        // Aviso de demonstração (quando o Flatpak não existe, ex.: testes)
        Rectangle {
            visible: store.demo
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 26
            width: demoTxt.implicitWidth + 24
            height: 30
            radius: 15
            color: theme.c.secondaryContainer
            Txt {
                id: demoTxt
                anchors.centerIn: parent
                text: "modo demonstração"
                font.pixelSize: 12
                color: theme.c.onSecondaryContainer
            }
        }
    }

    // ── Avisos rápidos ─────────────────────────────────────
    Rectangle {
        id: toast
        property string text: ""
        anchors.horizontalCenter: panel.horizontalCenter
        y: win.height - (shown ? height + 32 : -10)
        property bool shown: false
        width: toastTxt.implicitWidth + 40
        height: 48
        radius: 24
        color: theme.c.inverseSurface || "#e6e6e6"
        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Txt {
            id: toastTxt
            anchors.centerIn: parent
            text: toast.text
            color: theme.c.inverseOnSurface || "#111111"
            font.pixelSize: 14
        }
        Timer {
            id: toastTimer
            interval: 3200
            onTriggered: toast.shown = false
        }
    }
    Connections {
        target: store
        function onMessage(text) {
            toast.text = text;
            toast.shown = true;
            toastTimer.restart();
        }
    }
}
