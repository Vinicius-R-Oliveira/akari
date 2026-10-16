// ─────────────────────────────────────────────────────────────
//  Hajime はじめ — a cena da transição (QtQuick puro, testável fora
//  do Quickshell). Começa exatamente como a Genkan terminou: fundo
//  desfocado e a flor acesa. Então a flor desabrocha, a luz toma a
//  tela, "おかえり" aparece e tudo se dissolve revelando o desktop.
// ─────────────────────────────────────────────────────────────
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property bool primary: true          // só a tela principal mostra a flor e o texto
    property string userName: ""
    property bool ready: false           // o Caelestia já está de pé?
    property string background: "file:///usr/share/akari/genkan/fundo.jpg"
    property string fontFamily: "Google Sans Flex"

    signal finished

    readonly property real u: Math.max(0.6, Math.min(width / 1920, height / 1080))

    // Etapas da animação (0 → 1)
    property real bloom: 0       // a flor gira e cresce
    property real flood: 0       // a luz enche a tela
    property real greet: 0       // texto de boas-vindas
    property real reveal: 0      // tudo some, mostrando o desktop
    property bool waitedEnough: false

    opacity: 1 - reveal

    // Fundo igual ao da Genkan (some quando a luz cobre a tela)
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.flood < 0.98 ? 1 : 0
    }
    Image {
        anchors.fill: parent
        source: root.background
        fillMode: Image.PreserveAspectCrop
        opacity: root.flood < 0.98 ? 1 : 0
    }
    Rectangle {
        anchors.fill: parent
        opacity: root.flood < 0.98 ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
            GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
        }
    }

    Flower {
        id: flower
        visible: root.primary
        size: 270 * root.u
        x: (root.width - size) / 2
        y: root.height * 0.5 - size * 0.72
        draw: 1
        light: 1
        breath: 1 - root.bloom * 0.3
        rotation: 40 * root.bloom
        scale: 1 + 1.6 * root.bloom
        opacity: 1 - Math.max(0, (root.flood - 0.6) / 0.4)
    }

    // A luz que nasce do centro da flor
    Shape {
        id: light
        readonly property real cx: flower.x + flower.width / 2
        readonly property real cy: flower.y + flower.height * 0.51
        readonly property real maxR: Math.hypot(Math.max(cx, root.width - cx), Math.max(cy, root.height - cy)) * 1.5
        readonly property real r: Math.max(1, maxR * root.flood)
        anchors.fill: parent
        visible: root.flood > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: light.cx; centerY: light.cy; centerRadius: light.r
                focalX: light.cx; focalY: light.cy; focalRadius: 0
                GradientStop { position: 0.0; color: "#fafafa" }
                GradientStop { position: 0.55; color: Qt.rgba(0.965, 0.965, 0.965, 0.97) }
                GradientStop { position: 1.0; color: Qt.rgba(0.965, 0.965, 0.965, 0) }
            }
            PathAngleArc { centerX: light.cx; centerY: light.cy; radiusX: light.r; radiusY: light.r; startAngle: 0; sweepAngle: 360 }
        }
    }
    // Brilho radial suave por cima (deixa a borda da luz difusa)
    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
        opacity: Math.max(0, (root.flood - 0.55) / 0.45)
    }

    // Boas-vindas
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20 * root.u
        spacing: 22 * root.u
        visible: root.primary
        opacity: root.greet

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "おかえり"
            color: "#151515"
            font.family: "Noto Serif CJK JP"
            font.weight: Font.Light
            font.pixelSize: 64 * root.u
            font.letterSpacing: 22 * root.u
            leftPadding: 22 * root.u
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ("Bem-vindo de volta" + (root.userName ? ", " + root.userName : "")).toUpperCase()
            color: "#4a4a4a"
            font.family: root.fontFamily
            font.weight: Font.Light
            font.pixelSize: 19 * root.u
            font.letterSpacing: 8 * root.u
            leftPadding: 8 * root.u
        }
    }

    SequentialAnimation {
        id: timeline
        running: true

        PauseAnimation { duration: 250 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "bloom"; to: 1; duration: 2100; easing.type: Easing.InOutCubic }
            SequentialAnimation {
                PauseAnimation { duration: 600 }
                NumberAnimation { target: root; property: "flood"; to: 1; duration: 1400; easing.type: Easing.InCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 1450 }
                NumberAnimation { target: root; property: "greet"; to: 1; duration: 500; easing.type: Easing.OutCubic }
            }
        }
        PauseAnimation { duration: 650 }
        ScriptAction { script: root.waitedEnough = true }
    }

    // Só revela o desktop quando o Caelestia estiver pronto (ou depois de um tempo)
    readonly property bool canReveal: waitedEnough && ready
    onCanRevealChanged: if (canReveal) outro.start()

    SequentialAnimation {
        id: outro
        NumberAnimation { target: root; property: "greet"; to: 0; duration: 380; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "reveal"; to: 1; duration: 1100; easing.type: Easing.InOutSine }
        ScriptAction { script: root.finished() }
    }

    // Segurança: nunca prender a tela por mais de 12 s
    Timer {
        interval: 12000
        running: true
        onTriggered: if (!outro.running && root.reveal < 1) outro.start()
    }
}
