// ─────────────────────────────────────────────────────────────
//  Genkan 玄関 — tela de login da Akari (tema do SDDM, Qt 6)
//  A flor se desenha, acende, e a senha leva você para a Hajime.
// ─────────────────────────────────────────────────────────────
import QtQuick
import QtQuick.Effects
import "components"

Item {
    id: root

    width: 1920
    height: 1080

    // Escala relativa a uma tela 1080p
    readonly property real u: Math.max(0.6, Math.min(width / 1920, height / 1080))
    readonly property string fontFamily: (config.font && config.font.length) ? config.font : "Google Sans Flex"
    readonly property string iconFont: "Material Symbols Rounded"

    property var users: []
    property var sessions: []
    property int userIndex: 0
    property int sessionIndex: 0
    property bool busy: false
    property bool loggedIn: false
    property date now: new Date()

    function userAt(i) {
        return users.length ? users[Math.max(0, Math.min(i, users.length - 1))] : ({ name: "", realName: "", icon: "" });
    }
    readonly property var currentUser: userAt(userIndex)

    function displayName(u) {
        return (u.realName && u.realName.length) ? u.realName : u.name;
    }

    function pickSession() {
        const pref = (config.preferredSession || "akari").toLowerCase();
        for (let i = 0; i < sessions.length; i++) {
            if ((sessions[i].file || "").toLowerCase().indexOf(pref) !== -1)
                return i;
        }
        return sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0;
    }

    function login() {
        if (busy || loggedIn || !users.length)
            return;
        busy = true;
        errorText.opacity = 0;
        sddm.login(currentUser.name, password.text, sessionIndex);
    }

    // ── Coleta usuários e sessões dos modelos do SDDM ─────────
    Repeater {
        model: userModel
        delegate: Item {
            required property int index
            required property string name
            required property string realName
            required property string icon
            Component.onCompleted: {
                const list = root.users.slice();
                list[index] = { name: name, realName: realName, icon: icon };
                root.users = list;
                if (index === userModel.lastIndex)
                    root.userIndex = index;
            }
        }
    }
    Repeater {
        model: sessionModel
        delegate: Item {
            required property int index
            required property string name
            required property string file
            Component.onCompleted: {
                const list = root.sessions.slice();
                list[index] = { name: name, file: file };
                root.sessions = list;
                root.sessionIndex = root.pickSession();
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            password.text = "";
            errorText.opacity = 1;
            shake.restart();
            password.forceActiveFocus();
        }
        function onLoginSucceeded() {
            root.loggedIn = true;
            outro.start();
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // ── Fundo ─────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }
    Image {
        id: background
        anchors.fill: parent
        source: config.background ? "file://" + config.background : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
    }
    // Vinheta para o centro respirar
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
            GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
        }
    }

    // ── Relógio ───────────────────────────────────────────────
    Item {
        id: ui
        anchors.fill: parent

        Column {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            y: 86 * root.u
            spacing: 6 * root.u
            opacity: 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.now, config.clockFormat || "HH:mm")
                color: "#f2f2f2"
                font.family: root.fontFamily
                font.weight: Font.ExtraLight
                font.pixelSize: 112 * root.u
                font.letterSpacing: 2 * root.u
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.locale(config.locale || "pt_BR").toString(root.now, "dddd · d 'de' MMMM").toUpperCase()
                color: "#a9a9a9"
                font.family: root.fontFamily
                font.weight: Font.Light
                font.pixelSize: 19 * root.u
                font.letterSpacing: 6 * root.u
            }
        }

        // ── Nome ──────────────────────────────────────────────
        Text {
            id: wordmark
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: 8 * root.u
            y: flower.y + flower.height + 26 * root.u
            text: "akari"
            color: "#f4f4f4"
            font.family: root.fontFamily
            font.weight: Font.Light
            font.pixelSize: 30 * root.u
            font.letterSpacing: 16 * root.u
            opacity: 0
        }

        // ── Usuário ───────────────────────────────────────────
        Row {
            id: userRow
            anchors.horizontalCenter: parent.horizontalCenter
            y: wordmark.y + wordmark.height + 30 * root.u
            spacing: 14 * root.u
            opacity: 0

            Text {
                visible: root.users.length > 1
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_left"
                font.family: root.iconFont
                font.pixelSize: 24 * root.u
                color: prevArea.containsMouse ? "#ffffff" : "#8a8a8a"
                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.userIndex = (root.userIndex - 1 + root.users.length) % root.users.length
                }
            }

            Item {
                id: avatar
                width: 46 * root.u
                height: width
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#1f1f1f"
                    border.color: "#4a4a4a"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        visible: avatarImg.status !== Image.Ready
                        text: (root.displayName(root.currentUser) || "?").charAt(0).toUpperCase()
                        color: "#e6e6e6"
                        font.family: root.fontFamily
                        font.pixelSize: 20 * root.u
                    }
                }
                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: root.currentUser.icon ? "file://" + root.currentUser.icon : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: parent
                    visible: avatarImg.status === Image.Ready
                    source: avatarImg
                    maskEnabled: true
                    maskSource: avatarMask
                }
                Item {
                    id: avatarMask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.displayName(root.currentUser)
                color: "#ececec"
                font.family: root.fontFamily
                font.pixelSize: 20 * root.u
                font.letterSpacing: 1 * root.u
            }

            Text {
                visible: root.users.length > 1
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_right"
                font.family: root.iconFont
                font.pixelSize: 24 * root.u
                color: nextArea.containsMouse ? "#ffffff" : "#8a8a8a"
                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.userIndex = (root.userIndex + 1) % root.users.length
                }
            }
        }

        // ── Senha ─────────────────────────────────────────────
        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            y: userRow.y + userRow.height + 24 * root.u
            width: 380 * root.u
            height: 56 * root.u
            radius: height / 2
            color: Qt.rgba(0.08, 0.08, 0.08, 0.78)
            border.width: 1.5
            border.color: password.activeFocus ? "#9a9a9a" : "#3a3a3a"
            opacity: 0

            Behavior on border.color { ColorAnimation { duration: 200 } }

            Text {
                id: lockIcon
                anchors.left: parent.left
                anchors.leftMargin: 22 * root.u
                anchors.verticalCenter: parent.verticalCenter
                text: root.busy ? "progress_activity" : "lock"
                font.family: root.iconFont
                font.pixelSize: 22 * root.u
                color: "#9a9a9a"
                RotationAnimation on rotation {
                    running: root.busy
                    from: 0; to: 360
                    duration: 900
                    loops: Animation.Infinite
                }
                onTextChanged: rotation = 0
            }

            TextInput {
                id: password
                anchors.left: lockIcon.right
                anchors.leftMargin: 14 * root.u
                anchors.right: enterBtn.left
                anchors.rightMargin: 12 * root.u
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                passwordMaskDelay: 0
                color: "#ffffff"
                font.family: root.fontFamily
                font.pixelSize: 17 * root.u
                font.letterSpacing: 3 * root.u
                selectionColor: "#5a5a5a"
                clip: true
                focus: true
                enabled: !root.loggedIn
                onAccepted: root.login()
                Keys.onEscapePressed: text = ""
                Keys.onUpPressed: if (root.users.length > 1) root.userIndex = (root.userIndex - 1 + root.users.length) % root.users.length
                Keys.onDownPressed: if (root.users.length > 1) root.userIndex = (root.userIndex + 1) % root.users.length

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: password.text.length === 0
                    text: "senha"
                    color: "#6c6c6c"
                    font.family: root.fontFamily
                    font.pixelSize: 16 * root.u
                    font.letterSpacing: 1.5 * root.u
                }
            }

            Rectangle {
                id: enterBtn
                anchors.right: parent.right
                anchors.rightMargin: 10 * root.u
                anchors.verticalCenter: parent.verticalCenter
                width: 36 * root.u
                height: width
                radius: width / 2
                color: "#ffffff"
                opacity: password.text.length ? 1 : 0.2
                scale: enterArea.pressed ? 0.85 : 1
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "arrow_forward"
                    font.family: root.iconFont
                    font.pixelSize: 20 * root.u
                    color: "#000000"
                }
                MouseArea {
                    id: enterArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.login()
                }
            }

            SequentialAnimation {
                id: shake
                property real base: 0
                NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -14 * root.u; duration: 50 }
                NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 12 * root.u; duration: 70 }
                NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -8 * root.u; duration: 70 }
                NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 4 * root.u; duration: 60 }
                NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
            }
        }

        Text {
            id: errorText
            anchors.horizontalCenter: parent.horizontalCenter
            y: pill.y + pill.height + 16 * root.u
            text: "Senha incorreta"
            color: "#d0d0d0"
            font.family: root.fontFamily
            font.pixelSize: 14 * root.u
            font.letterSpacing: 2 * root.u
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: errorText.y + (errorText.opacity > 0 ? 26 * root.u : 0)
            visible: typeof keyboard !== "undefined" && keyboard && keyboard.capsLock
            text: "Caps Lock ligado"
            color: "#9a9a9a"
            font.family: root.fontFamily
            font.pixelSize: 13 * root.u
            font.letterSpacing: 2 * root.u
        }

        // ── Rodapé: sessão, teclado e energia ─────────────────
        Row {
            id: footerLeft
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 36 * root.u
            spacing: 22 * root.u
            opacity: 0

            Row {
                spacing: 8 * root.u
                Text {
                    text: "desktop_windows"
                    font.family: root.iconFont
                    font.pixelSize: 18 * root.u
                    color: "#8a8a8a"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.sessions.length ? (root.sessions[root.sessionIndex] || {}).name || "" : ""
                    color: sessArea.containsMouse ? "#ffffff" : "#9a9a9a"
                    font.family: root.fontFamily
                    font.pixelSize: 14 * root.u
                    font.letterSpacing: 1.5 * root.u
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        id: sessArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.sessions.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (root.sessions.length > 1) root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length
                    }
                }
            }
            Row {
                spacing: 8 * root.u
                visible: typeof keyboard !== "undefined" && keyboard && keyboard.layouts && keyboard.layouts.length > 0
                Text {
                    text: "keyboard"
                    font.family: root.iconFont
                    font.pixelSize: 18 * root.u
                    color: "#8a8a8a"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: (typeof keyboard !== "undefined" && keyboard && keyboard.layouts && keyboard.layouts.length)
                          ? (keyboard.layouts[keyboard.currentLayout] || {}).shortName || "" : ""
                    color: "#9a9a9a"
                    font.family: root.fontFamily
                    font.pixelSize: 14 * root.u
                    font.letterSpacing: 1.5 * root.u
                    font.capitalization: Font.AllUppercase
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Row {
            id: footerRight
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 32 * root.u
            spacing: 10 * root.u
            opacity: 0

            Repeater {
                model: [
                    { icon: "bedtime", label: "Suspender", can: sddm.canSuspend, act: () => sddm.suspend() },
                    { icon: "restart_alt", label: "Reiniciar", can: sddm.canReboot, act: () => sddm.reboot() },
                    { icon: "power_settings_new", label: "Desligar", can: sddm.canPowerOff, act: () => sddm.powerOff() }
                ]
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.can
                    width: 44 * root.u
                    height: width
                    radius: width / 2
                    color: btnArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.family: root.iconFont
                        font.pixelSize: 22 * root.u
                        color: btnArea.containsMouse ? "#ffffff" : "#a0a0a0"
                    }
                    MouseArea {
                        id: btnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.act()
                    }
                }
            }
        }
    }

    // ── A flor (fica por cima de tudo e continua na Hajime) ───
    Flower {
        id: flower
        size: 270 * root.u
        x: (root.width - size) / 2
        y: root.height * 0.5 - size * 0.72
        draw: 0
        light: 0

        SequentialAnimation on breath {
            running: flower.light >= 1 && !root.loggedIn
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: 1600; easing.type: Easing.InOutSine }
        }
    }

    // ── Entrada: a flor se desenha, acende e a tela aparece ───
    SequentialAnimation {
        id: intro
        running: true
        PauseAnimation { duration: 250 }
        ParallelAnimation {
            NumberAnimation { target: flower; property: "draw"; from: 0; to: 1; duration: 1700; easing.type: Easing.InOutCubic }
            NumberAnimation { target: clock; property: "opacity"; to: 1; duration: 900; easing.type: Easing.OutCubic }
        }
        NumberAnimation { target: flower; property: "light"; to: 1; duration: 1000; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: wordmark; property: "opacity"; to: 1; duration: 700 }
            SequentialAnimation {
                PauseAnimation { duration: 180 }
                NumberAnimation { target: userRow; property: "opacity"; to: 1; duration: 600 }
            }
            SequentialAnimation {
                PauseAnimation { duration: 320 }
                NumberAnimation { target: pill; property: "opacity"; to: 1; duration: 600 }
            }
            SequentialAnimation {
                PauseAnimation { duration: 500 }
                ParallelAnimation {
                    NumberAnimation { target: footerLeft; property: "opacity"; to: 1; duration: 600 }
                    NumberAnimation { target: footerRight; property: "opacity"; to: 1; duration: 600 }
                }
            }
        }
        ScriptAction { script: password.forceActiveFocus() }
    }

    // ── Saída: some tudo, menos a flor acesa (a Hajime continua daqui) ─
    ParallelAnimation {
        id: outro
        NumberAnimation { target: ui; property: "opacity"; to: 0; duration: 450; easing.type: Easing.InCubic }
        NumberAnimation { target: flower; property: "breath"; to: 1; duration: 450 }
    }

    Component.onCompleted: password.forceActiveFocus()
}
