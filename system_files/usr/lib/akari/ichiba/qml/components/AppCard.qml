import QtQuick

// Cartão de app nas listas da loja
Rectangle {
    id: root

    property var app: ({})
    signal open(string appId)

    readonly property bool isInstalled: store.installed[app.id] !== undefined
    readonly property var job: store.jobs[app.id]

    radius: 24
    color: area.containsMouse ? theme.c.surfaceContainerHighest : theme.c.surfaceContainerHigh
    Behavior on color { ColorAnimation { duration: 140 } }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open(root.app.id)
    }

    Row {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        AppIcon {
            source: root.app.icon || ""
            size: 56
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            width: parent.width - 70
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Row {
                spacing: 6
                width: parent.width
                Txt {
                    text: root.app.name || ""
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, parent.width - 24)
                }
                Icon {
                    visible: !!root.app.verified
                    text: "verified"
                    filled: true
                    size: 16
                    color: theme.c.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Txt {
                width: parent.width
                text: root.app.summary || ""
                color: theme.c.onSurfaceVariant
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Row {
                spacing: 6
                visible: root.isInstalled || !!root.job
                Icon {
                    text: root.job ? "downloading" : "check_circle"
                    filled: true
                    size: 15
                    color: theme.c.onSurfaceVariant
                }
                Txt {
                    text: root.job ? (root.job.kind === "remove" ? "Removendo…" : "Instalando…") : "Instalado"
                    font.pixelSize: 12
                    color: theme.c.onSurfaceVariant
                }
            }
        }
    }
}
