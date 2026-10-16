import QtQuick

// Botões de ação de um app: Instalar / Abrir / Remover / progresso
Row {
    id: root

    property string appId: ""
    property bool compact: false

    readonly property var job: store.jobs[appId]
    readonly property bool isInstalled: store.installed[appId] !== undefined
    readonly property bool hasUpdate: {
        for (const u of store.updates)
            if (u.id === appId)
                return true;
        return false;
    }

    spacing: 8

    // Em andamento
    Rectangle {
        visible: !!root.job
        width: root.compact ? 128 : 220
        height: 42
        radius: 21
        color: theme.c.surfaceContainerHighest

        Column {
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 6
            Txt {
                text: !root.job ? "" : (root.job.kind === "install" ? "Instalando" : root.job.kind === "remove" ? "Removendo" : "Atualizando")
                      + (root.job && root.job.progress >= 0 ? "  " + root.job.progress + "%" : "…")
                font.pixelSize: 12
                color: theme.c.onSurfaceVariant
            }
            ProgressLine {
                width: parent.width
                progress: root.job ? root.job.progress : -1
            }
        }
    }

    PillButton {
        visible: !root.job && !root.isInstalled
        text: "Instalar"
        icon: "download"
        onClicked: store.install(root.appId)
    }
    PillButton {
        visible: !root.job && root.isInstalled && root.hasUpdate
        text: root.compact ? "" : "Atualizar"
        icon: "update"
        tonal: true
        filled: false
        onClicked: store.update(root.appId)
    }
    PillButton {
        visible: !root.job && root.isInstalled
        text: "Abrir"
        icon: "open_in_new"
        filled: !root.compact
        tonal: root.compact
        onClicked: store.launch(root.appId)
    }
    PillButton {
        visible: !root.job && root.isInstalled && !root.compact
        text: "Remover"
        icon: "delete"
        filled: false
        onClicked: store.remove(root.appId)
    }
}
