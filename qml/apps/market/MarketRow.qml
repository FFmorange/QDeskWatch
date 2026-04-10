import QtQuick

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string status: ""
    property string updatedAt: ""
    property string unitText: ""
    property double value: 0
    property double change: 0
    property double changePct: 0
    property bool available: false
    property color accentColor: "#8FD3FF"
    property bool interactive: false

    signal clicked()

    readonly property color _upColor: "#FF5A4F"
    readonly property color _downColor: "#37C878"
    readonly property color _neutralColor: Qt.rgba(1, 1, 1, 0.58)
    readonly property bool _hasMovementData: root.available
                                             && root.change === root.change
                                             && root.changePct === root.changePct
    readonly property color _movementColor: !root._hasMovementData ? root._neutralColor
                                           : root.change > 0.0001 ? root._upColor
                                           : root.change < -0.0001 ? root._downColor
                                           : root._neutralColor
    readonly property bool hovered: hoverHandler.hovered
    readonly property bool pressed: tapHandler.pressed

    implicitWidth: Math.round(96 * PS.scale)
    implicitHeight: Math.round(27 * PS.scale)

    function formatFixed(number, digits) {
        var valueText = Number(number).toFixed(digits)
        var parts = valueText.split(".")
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        return parts.join(".")
    }

    function signedFixed(number, digits, suffix) {
        if (!root.available || number !== number)
            return "--"
        var absText = root.formatFixed(Math.abs(number), digits)
        var sign = number > 0.0001 ? "+" : number < -0.0001 ? "-" : ""
        return sign + absText + (suffix || "")
    }

    Item {
        id: visualRoot
        anchors.fill: parent
        scale: root.pressed ? 0.985 : root.hovered ? 1.01 : 1.0
        opacity: root.pressed ? 0.92 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            radius: Math.round(6 * PS.scale)
            color: root.hovered && root.interactive
                   ? Qt.rgba(1, 1, 1, 0.07)
                   : Qt.rgba(1, 1, 1, 0.045)
            border.width: 1
            border.color: root.pressed && root.interactive
                          ? Qt.rgba(1, 1, 1, 0.16)
                          : Qt.rgba(1, 1, 1, 0.08)
        }

        Rectangle {
            width: Math.round(2 * PS.scale)
            radius: width / 2
            anchors.left: parent.left
            anchors.leftMargin: Math.round(2 * PS.scale)
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: Math.round(4 * PS.scale)
            anchors.bottomMargin: Math.round(4 * PS.scale)
            color: root.accentColor
            opacity: 0.75
        }

        Column {
            anchors.fill: parent
            anchors.leftMargin: Math.round(6 * PS.scale)
            anchors.rightMargin: Math.round(5 * PS.scale)
            anchors.topMargin: Math.round(3 * PS.scale)
            anchors.bottomMargin: Math.round(3 * PS.scale)
            spacing: Math.round(1 * PS.scale)

            Item {
                width: parent.width
                height: Math.round(5 * PS.scale)

                Text {
                    id: titleText
                    text: root.title
                    color: "white"
                    opacity: 0.94
                    font.pixelSize: Math.round(4.2 * PS.scale)
                    font.bold: true
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: subtitleText
                    text: root.subtitle
                    visible: text.length > 0
                    color: Qt.rgba(1, 1, 1, 0.46)
                    font.pixelSize: Math.round(3.4 * PS.scale)
                    anchors.left: titleText.right
                    anchors.leftMargin: Math.round(2 * PS.scale)
                    anchors.baseline: titleText.baseline
                }

                Text {
                    text: root.status
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: Math.round(3.3 * PS.scale)
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item {
                width: parent.width
                height: Math.round(9 * PS.scale)

                Text {
                    id: valueText
                    text: root.available ? root.formatFixed(root.value, 2) : "--"
                    color: root.available ? "white" : Qt.rgba(1, 1, 1, 0.42)
                    font.pixelSize: Math.round(7.1 * PS.scale)
                    font.bold: true
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.unitText
                    visible: text.length > 0
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.pixelSize: Math.round(3.5 * PS.scale)
                    anchors.left: valueText.right
                    anchors.leftMargin: Math.round(2 * PS.scale)
                    anchors.bottom: valueText.bottom
                    anchors.bottomMargin: Math.round(1 * PS.scale)
                }
            }

            Item {
                width: parent.width
                height: Math.round(5 * PS.scale)

                Text {
                    text: root._hasMovementData
                          ? root.signedFixed(root.change, 2, "") + "  " + root.signedFixed(root.changePct, 2, "%")
                          : "--"
                    color: root._movementColor
                    font.pixelSize: Math.round(3.7 * PS.scale)
                    font.bold: true
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.updatedAt
                    color: Qt.rgba(1, 1, 1, 0.44)
                    font.pixelSize: Math.round(3.5 * PS.scale)
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler
        enabled: root.interactive
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.clicked()
    }
}