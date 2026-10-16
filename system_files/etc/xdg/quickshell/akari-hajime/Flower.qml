// ─────────────────────────────────────────────────────────────
//  Flor da Akari em QML (usada pela Genkan e pela Hajime).
//  draw:   0 → 1  as pétalas se desenham uma a uma
//  light:  0 → 1  o centro acende e a luz enche as pétalas
//  breath: 0 → 1  brilho "respirando" do centro
// ─────────────────────────────────────────────────────────────
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

Item {
    id: root

    property real size: 300
    property real draw: 1
    property real light: 1
    property real breath: 0
    property color colour: "#ffffff"

    // Comprimento do contorno de uma pétala, em unidades do desenho (200×200)
    readonly property real petalLength: 171
    readonly property real strokeW: 4.6
    readonly property var petals: [
        "M 100.0 88.0 C 80.0 72.0 74.0 44.0 88.0 26.0 L 100.0 36.0 L 112.0 26.0 C 126.0 44.0 120.0 72.0 100.0 88.0 Z",
        "M 113.315 97.674 C 122.351 73.708 147.127 59.35 168.572 67.102 L 162.77 81.605 L 175.988 89.927 C 163.196 108.804 134.712 111.751 113.315 97.674 Z",
        "M 108.229 113.326 C 133.814 114.515 155.126 133.641 154.38 156.432 L 138.794 155.395 L 134.963 170.539 C 113.057 164.205 101.453 138.026 108.229 113.326 Z",
        "M 91.771 113.326 C 98.547 138.026 86.943 164.205 65.037 170.539 L 61.206 155.395 L 45.62 156.432 C 44.874 133.641 66.186 114.515 91.771 113.326 Z",
        "M 86.685 97.674 C 65.288 111.751 36.804 108.804 24.012 89.927 L 37.23 81.605 L 31.428 67.102 C 52.873 59.35 77.649 73.708 86.685 97.674 Z"
    ]

    // Progresso de cada pétala: começam em sequência e se sobrepõem um pouco
    function petalProgress(i) {
        return Math.max(0, Math.min(1, (draw - i * 0.13) / 0.48));
    }

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    Item {
        id: canvas

        width: 200
        height: 200
        scale: root.size / 200
        transformOrigin: Item.TopLeft

        // Halo suave atrás de tudo
        Shape {
            anchors.fill: parent
            opacity: root.light
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: 100; centerY: 102; centerRadius: 98
                    focalX: 100; focalY: 102; focalRadius: 0
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.32) }
                    GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.08) }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                }
                PathAngleArc { centerX: 100; centerY: 102; radiusX: 98; radiusY: 98; startAngle: 0; sweepAngle: 360 }
            }
        }

        // "Papel" das pétalas iluminado por dentro (efeito lanterna)
        Shape {
            anchors.fill: parent
            opacity: root.light
            layer.enabled: true
            layer.samples: 4

            RadialGradient {
                id: paper
                centerX: 100; centerY: 102; centerRadius: 78
                focalX: 100; focalY: 102; focalRadius: 0
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.7) }
                GradientStop { position: 0.3; color: Qt.rgba(0.95, 0.95, 0.95, 0.3) }
                GradientStop { position: 0.7; color: Qt.rgba(0.74, 0.74, 0.74, 0.08) }
                GradientStop { position: 1; color: Qt.rgba(0.54, 0.54, 0.54, 0.04) }
            }

            ShapePath {
                strokeColor: "transparent"
                fillGradient: paper
                PathSvg { path: root.petals[0] }
            }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: paper
                PathSvg { path: root.petals[1] }
            }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: paper
                PathSvg { path: root.petals[2] }
            }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: paper
                PathSvg { path: root.petals[3] }
            }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: paper
                PathSvg { path: root.petals[4] }
            }
        }

        // Contorno com brilho (bloom) por baixo do traço nítido
        MultiEffect {
            source: outline
            anchors.fill: outline
            autoPaddingEnabled: true
            blurEnabled: true
            blur: 0.55
            blurMax: 14
            brightness: 0.15
            opacity: 0.85
        }

        Item {
            id: outline

            anchors.fill: parent
            layer.enabled: true
            layer.samples: 8

            Repeater {
                model: root.petals

                Shape {
                    id: petal

                    required property string modelData
                    required property int index
                    readonly property real units: root.petalLength / root.strokeW
                    readonly property real t: root.petalProgress(index)

                    anchors.fill: parent
                    visible: t > 0

                    ShapePath {
                        strokeColor: root.colour
                        strokeWidth: root.strokeW
                        fillColor: "transparent"
                        joinStyle: ShapePath.RoundJoin
                        capStyle: ShapePath.RoundCap
                        strokeStyle: ShapePath.DashLine
                        dashPattern: [petal.units + 1, petal.units + 1]
                        dashOffset: (petal.units + 1) * (1 - petal.t)
                        PathSvg { path: petal.modelData }
                    }
                }
            }
        }

        // Luz do centro (brilho difuso que respira)
        Shape {
            anchors.fill: parent
            opacity: root.light * (0.55 + 0.4 * root.breath)
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: 100; centerY: 102; centerRadius: 34
                    focalX: 100; focalY: 102; focalRadius: 0
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.95) }
                    GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.45) }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                }
                PathAngleArc { centerX: 100; centerY: 102; radiusX: 34; radiusY: 34; startAngle: 0; sweepAngle: 360 }
            }
        }

        // O ponto de luz
        Rectangle {
            x: 90; y: 92
            width: 20; height: 20
            radius: 10
            color: "#ffffff"
            scale: Math.min(1, root.light * 1.6)
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0; color: "#ffffff" }
                GradientStop { position: 1; color: "#e2e2e2" }
            }
        }
    }
}
