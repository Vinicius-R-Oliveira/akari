import QtQuick

// Filtro em formato de chip
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool selected: false
    signal clicked

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 36
    radius: 12
    color: selected ? theme.c.secondaryContainer : (area.containsMouse ? theme.c.surfaceContainerHighest : "transparent")
    border.width: selected ? 0 : 1
    border.color: theme.c.outlineVariant
    Behavior on color { ColorAnimation { duration: 140 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Icon {
            visible: root.icon !== ""
            text: root.selected ? "check" : root.icon
            size: 18
            anchors.verticalCenter: parent.verticalCenter
            color: root.selected ? theme.c.onSecondaryContainer : theme.c.onSurfaceVariant
        }
        Txt {
            text: root.text
            font.pixelSize: 13
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
            color: root.selected ? theme.c.onSecondaryContainer : theme.c.onSurface
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
