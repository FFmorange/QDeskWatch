import QtQuick

Rectangle {
    id: root

    property string label: ""
    property color baseColor: Qt.rgba(1, 1, 1, 0.07)
    property color hoverColor: Qt.rgba(1, 1, 1, 0.12)
    property color pressedColor: Qt.rgba(1, 1, 1, 0.18)
    property color textColor: "white"
    property bool accent: false

    signal clicked()

    readonly property bool hovered: hoverHandler.hovered
    readonly property bool pressed: tapHandler.pressed

    radius: Math.round(3 * PS.scale)
    color: root.pressed ? root.pressedColor : root.hovered ? root.hoverColor : root.baseColor
    border.width: 1
    border.color: root.accent ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.1)

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.textColor
        font.pixelSize: root.label.length > 1 ? Math.round(4.2 * PS.scale) : Math.round(5.2 * PS.scale)
        font.bold: true
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.clicked()
    }
}
