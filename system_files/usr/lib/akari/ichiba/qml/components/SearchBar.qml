import QtQuick

// Campo de busca em pílula
Rectangle {
    id: root

    property alias text: input.text
    signal edited(string text)

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitHeight: 48
    radius: height / 2
    color: theme.c.surfaceContainerHigh
    border.width: input.activeFocus ? 1.5 : 0
    border.color: theme.c.outline

    Icon {
        id: ico
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        text: "search"
        color: theme.c.onSurfaceVariant
    }

    TextInput {
        id: input
        anchors.left: ico.right
        anchors.leftMargin: 12
        anchors.right: clear.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: theme.c.onSurface
        font.family: "Google Sans Flex"
        font.pixelSize: 15
        selectionColor: theme.c.secondaryContainer
        clip: true
        onTextEdited: root.edited(text)
        Keys.onEscapePressed: { text = ""; root.edited(""); }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length === 0
            text: "Buscar apps no Flathub"
            color: theme.c.onSurfaceVariant
            font.pixelSize: 15
        }
    }

    Icon {
        id: clear
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text.length > 0
        text: "close"
        size: 20
        color: theme.c.onSurfaceVariant
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: { input.text = ""; root.edited(""); }
        }
    }
}
