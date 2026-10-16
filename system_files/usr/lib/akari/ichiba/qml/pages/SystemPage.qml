import QtQuick
import "../components"

// Sistema: versão da Akari, atualização da imagem e voltar versão
Flickable {
    id: root

    property var nav
    readonly property var sys: store.system

    contentHeight: col.implicitHeight + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: col
        width: Math.min(root.width, 900)
        spacing: 16

        // ── Sobre ───────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 170
            radius: 28
            color: theme.c.surfaceContainerHigh

            Image {
                id: flor
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                width: 124
                height: 124
                source: "file:///usr/share/akari/logo/akari-flor.svg"
                sourceSize.width: 248
                sourceSize.height: 248
            }
            Column {
                anchors.left: flor.right
                anchors.leftMargin: 20
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Txt {
                    text: "Akari 灯り"
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                }
                Txt {
                    text: root.sys.name || ""
                    color: theme.c.onSurfaceVariant
                    font.pixelSize: 14
                }
                Txt {
                    width: parent.width
                    elide: Text.ElideMiddle
                    text: [root.sys.build ? "imagem de " + root.sys.build : "", root.sys.deployed ? "instalada em " + root.sys.deployed : ""]
                          .filter(s => s).join("  ·  ")
                    color: theme.c.onSurfaceVariant
                    font.pixelSize: 13
                }
                Txt {
                    width: parent.width
                    elide: Text.ElideMiddle
                    text: root.sys.image || ""
                    color: theme.c.outline
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                }
            }
        }

        // ── Atualização ─────────────────────────────────────
        Card {
            width: parent.width

            Row {
                spacing: 12
                Icon {
                    text: root.sys.staged ? "restart_alt" : "system_update"
                    size: 26
                    anchors.verticalCenter: parent.verticalCenter
                }
                Txt {
                    text: "Atualização do sistema"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Txt {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "A Akari se atualiza inteira de uma vez, como uma imagem nova. A versão atual fica guardada: se algo der errado, é só voltar para ela."
                color: theme.c.onSurfaceVariant
                font.pixelSize: 13
                lineHeight: 1.2
            }
            Rectangle {
                width: parent.width
                height: 44
                radius: 14
                color: theme.c.surfaceContainerHighest
                Txt {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.sys.status || "…"
                    font.pixelSize: 14
                }
                ProgressLine {
                    visible: !!root.sys.busy
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                }
            }
            Flow {
                width: parent.width
                spacing: 10
                PillButton {
                    text: "Procurar atualização"
                    icon: "refresh"
                    filled: false
                    enabledState: !root.sys.busy
                    onClicked: store.checkSystemUpdate()
                }
                PillButton {
                    text: "Atualizar agora"
                    icon: "download"
                    enabledState: !root.sys.busy
                    onClicked: store.upgradeSystem()
                }
                PillButton {
                    visible: !!root.sys.staged
                    text: "Reiniciar"
                    icon: "restart_alt"
                    tonal: true
                    filled: false
                    onClicked: store.reboot()
                }
            }
        }

        // ── Voltar versão ───────────────────────────────────
        Card {
            width: parent.width

            Row {
                spacing: 12
                Icon {
                    text: "history"
                    size: 26
                    anchors.verticalCenter: parent.verticalCenter
                }
                Txt {
                    text: "Voltar para a versão anterior"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Txt {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Use se uma atualização quebrou algo. Depois de reiniciar, a Akari volta exatamente como estava. Também dá para escolher a versão anterior no menu de boot."
                color: theme.c.onSurfaceVariant
                font.pixelSize: 13
                lineHeight: 1.2
            }
            PillButton {
                text: "Voltar versão"
                icon: "undo"
                filled: false
                enabledState: !root.sys.busy
                onClicked: store.rollbackSystem()
            }
        }

        // ── Apps ────────────────────────────────────────────
        Card {
            width: parent.width

            Row {
                spacing: 12
                Icon {
                    text: "apps"
                    size: 26
                    anchors.verticalCenter: parent.verticalCenter
                }
                Txt {
                    text: "Apps da loja"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Txt {
                text: (store.installedList.length === 1 ? "1 app instalado" : store.installedList.length + " apps instalados") + " · " + (store.updates.length ? store.updates.length + " com atualização" : "todos em dia")
                color: theme.c.onSurfaceVariant
                font.pixelSize: 13
            }
            Row {
                spacing: 10
                PillButton {
                    text: "Ver atualizações"
                    icon: "update"
                    filled: false
                    onClicked: root.nav.go("updates")
                }
                PillButton {
                    text: "Atualizar catálogo"
                    icon: "cloud_sync"
                    filled: false
                    onClicked: store.refresh_appstream()
                }
            }
        }
    }
}
