import QtQuick

// Cartão de conteúdo (usado na página Sistema)
Rectangle {
    default property alias content: col.data
    property alias spacing: col.spacing

    radius: 28
    color: theme.c.surfaceContainerHigh
    implicitHeight: col.implicitHeight + 48

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 24
        spacing: 14
    }
}
