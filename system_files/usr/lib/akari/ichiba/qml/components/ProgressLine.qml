import QtQuick

// Barra de progresso fina (indeterminada quando progress < 0)
Rectangle {
    id: root

    property real progress: -1

    implicitHeight: 4
    radius: 2
    color: theme.c.surfaceContainerHighest
    clip: true

    Rectangle {
        id: bar
        height: parent.height
        radius: 2
        color: theme.c.primary
        width: root.progress >= 0 ? root.width * root.progress / 100 : root.width * 0.3
        Behavior on width { enabled: root.progress >= 0; NumberAnimation { duration: 200 } }

        SequentialAnimation on x {
            running: root.progress < 0 && root.visible
            loops: Animation.Infinite
            NumberAnimation { from: -root.width * 0.3; to: root.width; duration: 1100; easing.type: Easing.InOutQuad }
        }
    }
    onProgressChanged: if (progress >= 0) bar.x = 0
}
