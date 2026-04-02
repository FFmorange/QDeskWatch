import QtQuick

Item {
    id: root

    signal pressed()

    readonly property bool launcherMode: AppShell.mode === "launcher"
    readonly property bool hovered: hoverHandler.hovered
    readonly property bool buttonPressed: tapHandler.pressed
    readonly property color _accent: launcherMode ? Qt.rgba(0.56, 0.83, 1.0, 0.95) : Qt.rgba(1, 1, 1, 0.8)
    readonly property real _outerRadius: Math.round(3.1 * PS.scale)
    readonly property real _innerRadius: Math.round(2.5 * PS.scale)
    readonly property real _hoverScale: 1.12
    readonly property real _pressedScale: 0.92

    width: Math.round(8.6 * PS.scale)
    height: Math.round(16.4 * PS.scale)

    Item {
        id: buttonMotion
        anchors.fill: parent
        y: root.buttonPressed ? Math.round(0.7 * PS.scale) : 0
        scale: root.buttonPressed ? root._pressedScale : (root.hovered ? root._hoverScale : 1.0)
        opacity: root.buttonPressed ? 0.94 : 1.0
        transformOrigin: Item.Center

        Behavior on y {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            radius: root._outerRadius
            color: "#1b1b1b"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.round(1 * PS.scale)
            radius: root._innerRadius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.92, 0.92, 0.92, 0.9) }
                GradientStop { position: 0.3; color: Qt.rgba(0.68, 0.68, 0.68, 0.95) }
                GradientStop { position: 0.7; color: Qt.rgba(0.4, 0.4, 0.4, 0.98) }
                GradientStop { position: 1.0; color: Qt.rgba(0.16, 0.16, 0.16, 1.0) }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Math.round(0.75 * PS.scale)
            anchors.rightMargin: Math.round(0.75 * PS.scale)
            height: Math.max(2, Math.round(1.4 * PS.scale))
            radius: height / 2
            color: root._accent
            opacity: 0.9
        }

        Column {
            anchors.centerIn: parent
            spacing: Math.round(1.1 * PS.scale)

            Repeater {
                model: 4

                delegate: Rectangle {
                    width: Math.round(3.2 * PS.scale)
                    height: Math.max(1, Math.round(0.85 * PS.scale))
                    radius: height / 2
                    color: Qt.rgba(0.13, 0.13, 0.13, 0.5)
                }
            }
        }
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler
        onTapped: root.pressed()
    }

    WheelHandler {
        enabled: root.launcherMode
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                AppShell.selectNext()
            else if (event.angleDelta.y > 0)
                AppShell.selectPrevious()

            event.accepted = true
        }
    }
}
