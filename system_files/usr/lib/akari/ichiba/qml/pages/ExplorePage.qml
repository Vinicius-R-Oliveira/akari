import QtQuick
import "../components"

// Explorar: busca e categorias de todo o Flathub
Item {
    id: root

    property var nav

    readonly property var results: {
        store.apps; // recalcula quando o catálogo muda
        return store.search(nav.query, nav.category);
    }
    readonly property int columns: Math.max(2, Math.floor(width / 300))

    Flow {
        id: chips
        width: parent.width
        spacing: 8

        Chip {
            text: "Todos"
            icon: "apps"
            selected: root.nav.category === ""
            onClicked: root.nav.category = ""
        }
        Repeater {
            model: store.categories
            Chip {
                required property var modelData
                text: modelData.name
                icon: modelData.icon
                selected: root.nav.category === modelData.id
                onClicked: root.nav.category = (root.nav.category === modelData.id ? "" : modelData.id)
            }
        }
    }

    Txt {
        id: countTxt
        anchors.top: chips.bottom
        anchors.topMargin: 16
        text: root.results.length === 0
              ? (store.apps.length ? "Nada encontrado. Tente outra palavra." : "Carregando o catálogo…")
              : (root.results.length >= 240 ? "Mostrando os 240 primeiros resultados" : root.results.length + " apps")
        color: theme.c.onSurfaceVariant
        font.pixelSize: 13
    }

    GridView {
        id: grid
        anchors.top: countTxt.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        cellWidth: width / root.columns
        cellHeight: 116
        boundsBehavior: Flickable.StopAtBounds
        model: root.results
        cacheBuffer: 800

        delegate: Item {
            required property var modelData
            width: grid.cellWidth
            height: grid.cellHeight
            AppCard {
                anchors.fill: parent
                anchors.rightMargin: 12
                anchors.bottomMargin: 12
                app: modelData
                onOpen: id => root.nav.open(id)
            }
        }
    }
}
