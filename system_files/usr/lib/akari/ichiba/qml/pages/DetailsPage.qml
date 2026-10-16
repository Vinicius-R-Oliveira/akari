import QtQuick
import QtQuick.Effects
import "../components"

// Detalhes de um app
Flickable {
    id: root

    property var nav
    readonly property var app: { store.apps; return store.app(nav.appId); }

    contentHeight: col.implicitHeight + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: col
        width: root.width
        spacing: 22

        PillButton {
            text: "Voltar"
            icon: "arrow_back"
            filled: false
            onClicked: root.nav.back()
        }

        // Cabeçalho
        Row {
            width: parent.width
            spacing: 22

            AppIcon {
                source: root.app.icon || ""
                size: 104
            }
            Column {
                width: parent.width - 126
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Txt {
                    width: parent.width
                    text: root.app.name || ""
                    font.pixelSize: 32
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Row {
                    spacing: 6
                    Txt {
                        text: root.app.developer || ""
                        color: theme.c.onSurfaceVariant
                        font.pixelSize: 14
                    }
                    Icon {
                        visible: !!root.app.verified
                        text: "verified"
                        filled: true
                        size: 17
                        color: theme.c.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                AppActions {
                    topPadding: 8
                    appId: root.app.id || ""
                }
            }
        }

        Txt {
            width: parent.width
            text: root.app.summary || ""
            font.pixelSize: 18
            wrapMode: Text.WordWrap
        }

        // Capturas de tela
        ListView {
            id: shots
            visible: (root.app.screenshots || []).length > 0
            width: parent.width
            height: 300
            orientation: ListView.Horizontal
            spacing: 14
            clip: true
            model: root.app.screenshots || []
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                required property string modelData
                height: shots.height
                width: shotImg.status === Image.Ready ? height * shotImg.implicitWidth / Math.max(1, shotImg.implicitHeight) : height * 16 / 10

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: theme.c.surfaceContainerHigh
                    visible: shotImg.status !== Image.Ready
                    ProgressLine {
                        anchors.centerIn: parent
                        width: 120
                        visible: shotImg.status === Image.Loading
                    }
                }
                Image {
                    id: shotImg
                    anchors.fill: parent
                    source: modelData
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: parent
                    source: shotImg
                    visible: shotImg.status === Image.Ready
                    maskEnabled: true
                    maskSource: shotMask
                }
                Item {
                    id: shotMask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                    }
                }
            }
        }

        // Descrição
        Txt {
            width: parent.width
            text: root.app.description || ""
            color: theme.c.onSurfaceVariant
            font.pixelSize: 14
            wrapMode: Text.WordWrap
            lineHeight: 1.25
        }

        // Informações
        Flow {
            width: parent.width
            spacing: 10

            Repeater {
                model: [
                    { icon: "tag", text: root.app.version ? "Versão " + root.app.version : "" },
                    { icon: "gavel", text: root.app.license || "" },
                    { icon: "fingerprint", text: root.app.id || "" }
                ].filter(i => i.text)
                Chip {
                    required property var modelData
                    icon: modelData.icon
                    text: modelData.text
                }
            }
            Chip {
                visible: !!root.app.homepage
                icon: "open_in_new"
                text: "Site oficial"
                onClicked: store.openUrl(root.app.homepage)
            }
        }
    }
}
