import QtQuick

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string status: ""
    property string unitText: ""
    property string updatedAt: ""
    property string chartUpdatedAt: ""
    property double price: 0
    property double change: 0
    property double changePct: 0
    property bool available: false
    property bool chartAvailable: false
    property bool chartLoading: false
    property color accentColor: "#8FD3FF"
    property var chartPoints: []

    signal backRequested()

    readonly property color _upColor: "#FF5A4F"
    readonly property color _downColor: "#37C878"
    readonly property color _neutralColor: Qt.rgba(1, 1, 1, 0.64)
    readonly property color _movementColor: !root.available || root.change !== root.change
                                           ? root._neutralColor
                                           : root.change > 0.0001 ? root._upColor
                                           : root.change < -0.0001 ? root._downColor
                                           : root._neutralColor
    readonly property string _effectiveUpdatedAt: root.chartUpdatedAt.length > 0 ? root.chartUpdatedAt : root.updatedAt

    implicitWidth: Math.round(96 * PS.scale)
    implicitHeight: Math.round(66 * PS.scale)

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

    Rectangle {
        anchors.fill: parent
        radius: Math.round(7 * PS.scale)
        color: Qt.rgba(1, 1, 1, 0.018)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.04)
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: Math.round(4 * PS.scale)
        anchors.rightMargin: Math.round(4 * PS.scale)
        anchors.topMargin: Math.round(3 * PS.scale)
        anchors.bottomMargin: Math.round(3 * PS.scale)
        spacing: Math.round(2 * PS.scale)

        Item {
            width: parent.width
            height: Math.round(9 * PS.scale)

            Rectangle {
                id: backButton
                width: Math.round(11 * PS.scale)
                height: Math.round(7 * PS.scale)
                radius: Math.round(3.2 * PS.scale)
                color: backTap.pressed ? Qt.rgba(1, 1, 1, 0.12)
                      : backHover.hovered ? Qt.rgba(1, 1, 1, 0.08)
                      : Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, backTap.pressed ? 0.18 : 0.1)
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "<"
                    color: "white"
                    opacity: 0.86
                    font.pixelSize: Math.round(4.2 * PS.scale)
                    font.bold: true
                }

                HoverHandler {
                    id: backHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    id: backTap
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: root.backRequested()
                }
            }

            Column {
                anchors.left: backButton.right
                anchors.leftMargin: Math.round(3 * PS.scale)
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - backButton.width - Math.round(26 * PS.scale)
                spacing: 0

                Text {
                    text: root.title
                    color: "white"
                    font.pixelSize: Math.round(4.4 * PS.scale)
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: root.subtitle
                    visible: text.length > 0
                    color: Qt.rgba(1, 1, 1, 0.38)
                    font.pixelSize: Math.round(3.1 * PS.scale)
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Text {
                text: root.status
                color: Qt.rgba(1, 1, 1, 0.5)
                font.pixelSize: Math.round(3.2 * PS.scale)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Item {
            width: parent.width
            height: Math.round(12 * PS.scale)

            Text {
                id: priceText
                text: root.available ? root.formatFixed(root.price, 2) : "--"
                color: root.available ? "white" : Qt.rgba(1, 1, 1, 0.42)
                font.pixelSize: Math.round(8.8 * PS.scale)
                font.bold: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.unitText
                visible: text.length > 0
                color: Qt.rgba(1, 1, 1, 0.52)
                font.pixelSize: Math.round(3.5 * PS.scale)
                anchors.left: priceText.right
                anchors.leftMargin: Math.round(2 * PS.scale)
                anchors.bottom: priceText.bottom
                anchors.bottomMargin: Math.round(1 * PS.scale)
            }

            Text {
                text: root.available && root.change === root.change
                      ? root.signedFixed(root.change, 2, "") + "  " + root.signedFixed(root.changePct, 2, "%")
                      : "--"
                color: root._movementColor
                font.pixelSize: Math.round(3.8 * PS.scale)
                font.bold: true
                anchors.right: parent.right
                anchors.bottom: priceText.bottom
                anchors.bottomMargin: Math.round(1 * PS.scale)
            }
        }

        Rectangle {
            width: parent.width
            height: Math.round(31 * PS.scale)
            radius: Math.round(6 * PS.scale)
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            Rectangle {
                width: Math.round(2 * PS.scale)
                radius: width / 2
                anchors.left: parent.left
                anchors.leftMargin: Math.round(2 * PS.scale)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: Math.round(5 * PS.scale)
                anchors.bottomMargin: Math.round(5 * PS.scale)
                color: root.accentColor
                opacity: 0.75
            }

            MarketTrendChart {
                anchors.fill: parent
                anchors.leftMargin: Math.round(6 * PS.scale)
                anchors.rightMargin: Math.round(4 * PS.scale)
                anchors.topMargin: Math.round(4 * PS.scale)
                anchors.bottomMargin: Math.round(3 * PS.scale)
                points: root.chartPoints
                changeValue: root.change
                referenceValue: root.available && root.change === root.change ? root.price - root.change : NaN
                unavailableText: root.chartLoading ? "走势载入中..." : "走势暂不可用"
            }
        }

        Item {
            width: parent.width
            height: Math.round(7 * PS.scale)

            Text {
                text: root._effectiveUpdatedAt.length > 0 ? "更新 " + root._effectiveUpdatedAt : ""
                color: Qt.rgba(1, 1, 1, 0.34)
                font.pixelSize: Math.round(3.2 * PS.scale)
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                width: parent.width * 0.72
            }

            Text {
                text: "日内走势"
                color: Qt.rgba(1, 1, 1, 0.42)
                font.pixelSize: Math.round(3.2 * PS.scale)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}