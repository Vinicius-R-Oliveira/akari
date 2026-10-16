import QtQuick
import "../components"

// Atualizações dos apps Flatpak
Item {
    id: root

    property var nav

    Row {
        id: headerRow
        width: parent.width
        spacing: 16

        Column {
            width: parent.width - btn.width - 16
            spacing: 4
            Txt {
                text: store.updates.length ? store.updates.length + " atualizações disponíveis" : "Tudo em dia"
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
            Txt {
                text: store.updates.length ? "Os apps continuam funcionando enquanto atualizam." : "Seus apps estão na versão mais recente."
                color: theme.c.onSurfaceVariant
                font.pixelSize: 13
            }
        }
        PillButton {
            id: btn
            visible: store.updates.length > 0
            text: "Atualizar tudo"
            icon: "system_update_alt"
            anchors.verticalCenter: parent.verticalCenter
            onClicked: store.updateAll()
        }
    }

    Column {
        anchors.centerIn: parent
        visible: store.updates.length === 0
        spacing: 12
        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "task_alt"
            size: 64
            color: theme.c.onSurfaceVariant
        }
        PillButton {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Verificar de novo"
            icon: "refresh"
            filled: false
            onClicked: store.refresh_installed()
        }
    }

    ListView {
        anchors.top: headerRow.bottom
        anchors.topMargin: 18
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 8
        model: store.updates

        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            height: 76
            radius: 20
            color: theme.c.surfaceContainerHigh

            AppIcon {
                id: ic
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                source: modelData.icon || ""
                size: 44
            }
            Column {
                anchors.left: ic.right
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Txt {
                    text: modelData.name
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                Txt {
                    text: modelData.version ? "nova versão " + modelData.version : "nova versão disponível"
                    color: theme.c.onSurfaceVariant
                    font.pixelSize: 12
                }
            }
            AppActions {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                appId: modelData.id
                compact: true
            }
        }
    }
}
