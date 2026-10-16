import QtQuick

// Ícone do Material Symbols (a mesma fonte de ícones do Caelestia)
Text {
    property real size: 22
    property bool filled: false

    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": 400, "opsz": 24 })
    color: theme.c.onSurface
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
