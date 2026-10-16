import QtQuick
import "../components"

// Instalados: apps Flatpak que estão no computador
Item {
    id: root

    property var nav

    Txt {
        id: title
        text: store.installedList.length === 1 ? "1 app instalado" : store.installedList.length + " apps instalados"
        font.pixelSize: 22
        font.weight: Font.DemiBold
    }
    Txt {
        id: hint
        anchors.top: title.bottom
        anchors.topMargin: 4
        text: "Steam, VS Code, Firefox e os apps do sistema vêm com a Akari e se atualizam junto com ela."
        color: theme.c.onSurfaceVariant
        font.pixelSize: 13
    }

    ListView {
        anchors.top: hint.bottom
        anchors.topMargin: 18
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 8
        boundsBehavior: Flickable.StopAtBounds
        model: store.installedList

        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            height: 76
            radius: 20
            color: rowArea.containsMouse ? theme.c.surfaceContainerHighest : theme.c.surfaceContainerHigh

            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nav.open(modelData.id)
            }

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
                anchors.right: actions.left
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Txt {
                    width: parent.width
                    text: modelData.name
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Txt {
                    width: parent.width
                    text: [modelData.version ? "versão " + modelData.version : "", modelData.installation === "user" ? "só para você" : "para todos"]
                          .filter(s => s).join(" · ")
                    color: theme.c.onSurfaceVariant
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
            AppActions {
                id: actions
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                appId: modelData.id
            }
        }
    }
}
