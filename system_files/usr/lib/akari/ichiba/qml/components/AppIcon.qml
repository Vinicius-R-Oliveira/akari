import QtQuick

// Ícone de um app do Flathub, com um substituto bonito se não houver imagem
Item {
    id: root

    property string source: ""
    property real size: 56

    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        radius: root.size * 0.26
        color: theme.c.surfaceContainerHighest
        visible: img.status !== Image.Ready

        Icon {
            anchors.centerIn: parent
            text: "apps"
            size: root.size * 0.5
            color: theme.c.onSurfaceVariant
        }
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source === "" ? "" : (root.source.startsWith("/") ? "file://" + root.source : root.source)
        sourceSize.width: 128
        sourceSize.height: 128
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
    }
}
