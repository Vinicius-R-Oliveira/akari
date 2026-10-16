import QtQuick

// Item da barra de navegação lateral (como o painel de configurações do Caelestia)
Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property int badge: 0

    signal clicked

    width: 80
    height: 64

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: 4
        width: 56
        height: 32
        radius: 16
        color: root.active ? theme.c.secondaryContainer
             : (area.containsMouse ? theme.c.surfaceContainerHighest : "transparent")
        Behavior on color { ColorAnimation { duration: 160 } }

        Icon {
            anchors.centerIn: parent
            text: root.icon
            filled: root.active
            size: 22
            color: root.active ? theme.c.onSecondaryContainer : theme.c.onSurfaceVariant
        }

        Rectangle {
            visible: root.badge > 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 6
            anchors.topMargin: 2
            width: Math.max(16, badgeTxt.implicitWidth + 8)
            height: 16
            radius: 8
            color: theme.c.primary
            Txt {
                id: badgeTxt
                anchors.centerIn: parent
                text: root.badge
                font.pixelSize: 10
                font.weight: Font.Bold
                color: theme.c.onPrimary
            }
        }
    }

    Txt {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: pill.bottom
        anchors.topMargin: 4
        text: root.label
        font.pixelSize: 12
        font.weight: root.active ? Font.DemiBold : Font.Normal
        color: root.active ? theme.c.onSurface : theme.c.onSurfaceVariant
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
