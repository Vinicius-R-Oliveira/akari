import QtQuick

// Botão em pílula (estilo Material 3 do Caelestia)
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool filled: true
    property bool tonal: false
    property bool enabledState: true

    signal clicked

    implicitWidth: row.implicitWidth + (text ? 40 : 20)
    implicitHeight: 42
    radius: height / 2
    opacity: enabledState ? 1 : 0.4
    color: filled ? theme.c.primary
         : tonal ? theme.c.secondaryContainer
         : (area.containsMouse ? theme.c.surfaceContainerHighest : theme.c.surfaceContainerHigh)
    border.width: filled || tonal ? 0 : 1
    border.color: theme.c.outlineVariant
    scale: area.pressed ? 0.96 : 1

    Behavior on scale { NumberAnimation { duration: 110 } }
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.filled ? theme.c.onPrimary : theme.c.onSurface
        opacity: area.containsMouse ? 0.08 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Icon {
            visible: root.icon !== ""
            text: root.icon
            size: 20
            anchors.verticalCenter: parent.verticalCenter
            color: root.filled ? theme.c.onPrimary : (root.tonal ? theme.c.onSecondaryContainer : theme.c.onSurface)
        }
        Txt {
            visible: root.text !== ""
            text: root.text
            font.pixelSize: 14
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
            color: root.filled ? theme.c.onPrimary : (root.tonal ? theme.c.onSecondaryContainer : theme.c.onSurface)
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabledState ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabledState) root.clicked()
    }
}
