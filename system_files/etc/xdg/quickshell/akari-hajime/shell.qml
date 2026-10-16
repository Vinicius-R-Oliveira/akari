// Hajime はじめ — transição de boas-vindas da Akari (Quickshell).
// Iniciada pelo Hyprland logo após o login: /usr/libexec/akari/hajime
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: shell

    property bool caelestiaReady: false

    // Espera o Caelestia responder (até ~8 s) para revelar o desktop pronto
    Process {
        running: true
        command: ["sh", "-c", "for i in $(seq 80); do caelestia shell -s >/dev/null 2>&1 && exit 0; sleep 0.1; done; exit 0"]
        onExited: shell.caelestiaReady = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "akari-hajime"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            // Não bloqueia cliques enquanto a animação roda
            mask: Region {}

            HajimeScene {
                anchors.fill: parent
                primary: win.modelData === Quickshell.screens[0]
                userName: Quickshell.env("AKARI_USER_NAME") || ""
                ready: shell.caelestiaReady
                onFinished: Qt.quit()
            }
        }
    }
}
