import QtQuick
import "../components"

// Início: destaque da Ichiba e coleções escolhidas para a Akari
Flickable {
    id: root

    property var nav

    contentHeight: col.implicitHeight + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property int columns: Math.max(2, Math.floor(width / 300))

    Column {
        id: col
        width: root.width
        spacing: 28

        // ── Destaque ────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 230
            radius: 28
            color: theme.c.surfaceContainerHigh
            clip: true

            Image {
                anchors.right: parent.right
                anchors.rightMargin: 30
                anchors.verticalCenter: parent.verticalCenter
                width: 260
                height: 260
                source: "file:///usr/share/akari/logo/akari-flor.svg"
                sourceSize.width: 520
                sourceSize.height: 520
                opacity: 0.9
            }
            Txt {
                anchors.right: parent.right
                anchors.rightMargin: 300
                anchors.verticalCenter: parent.verticalCenter
                text: "市場"
                font.family: "Noto Serif CJK JP"
                font.pixelSize: 120
                font.weight: Font.Black
                color: "transparent"
                style: Text.Outline
                styleColor: {
                    const c = Qt.lighter(theme.c.onSurface, 1.0);
                    return Qt.rgba(c.r, c.g, c.b, 0.14);
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 36
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                width: parent.width * 0.5

                Txt {
                    text: "Ichiba"
                    font.pixelSize: 44
                    font.weight: Font.DemiBold
                }
                Txt {
                    width: parent.width
                    text: "A loja da Akari. Milhares de apps do Flathub, cada um na sua caixinha de segurança, sem bagunçar o sistema."
                    wrapMode: Text.WordWrap
                    color: theme.c.onSurfaceVariant
                    font.pixelSize: 15
                    lineHeight: 1.2
                }
                Row {
                    spacing: 10
                    topPadding: 6
                    PillButton {
                        text: "Explorar"
                        icon: "explore"
                        onClicked: root.nav.go("explore")
                    }
                    PillButton {
                        text: "Jogos"
                        icon: "sports_esports"
                        filled: false
                        onClicked: { root.nav.category = "Game"; root.nav.go("explore"); }
                    }
                }
            }
        }

        // ── Carregando ──────────────────────────────────────
        Column {
            visible: store.apps.length === 0
            width: parent.width
            spacing: 14
            topPadding: 30
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Carregando o catálogo do Flathub…"
                color: theme.c.onSurfaceVariant
                font.pixelSize: 15
            }
            ProgressLine {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 240
            }
        }

        // ── Coleções ────────────────────────────────────────
        Repeater {
            model: store.collections

            Column {
                required property var modelData
                width: col.width
                spacing: 14

                Row {
                    spacing: 10
                    Icon {
                        text: modelData.icon
                        color: theme.c.onSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Txt {
                        text: modelData.title
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Grid {
                    columns: root.columns
                    spacing: 12
                    Repeater {
                        model: modelData.apps
                        AppCard {
                            required property var modelData
                            app: modelData
                            width: (col.width - 12 * (root.columns - 1)) / root.columns
                            height: 104
                            onOpen: id => root.nav.open(id)
                        }
                    }
                }
            }
        }
    }
}
