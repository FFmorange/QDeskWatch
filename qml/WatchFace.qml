import QtQuick
import "./common"

Item {
    id: root

    readonly property real caseW: 44.0 * 3
    readonly property real caseH: 49.0 * 3
    readonly property real rCorner: 7.5 * 3
    readonly property real _edgeInset: Math.round(8 * PS.scale)
    readonly property real _crownGap: Math.round(2 * PS.scale)
    readonly property real _crownOverlap: Math.round(4.1 * PS.scale)
    readonly property bool launcherIconPressed: appHost.launcherIconPressed

    property real windowX: 0
    property real windowY: 0

    implicitWidth: faceBody.width + crownButton.width - root._crownOverlap
    implicitHeight: faceBody.height

    Item {
        id: faceBody
        width: Math.round(root.caseW * PS.scale)
        height: Math.round(root.caseH * PS.scale)
    }

    // Watch body
    Rectangle {
        anchors.fill: faceBody
        radius: Math.round(root.rCorner * PS.scale)
        color: "black"
        border.width: Math.round(2 * PS.scale)
        border.color: "#C0C0C0"
    }

    // Location
    LocationLabel {
        visible: false
        anchors.top: faceBody.top
        anchors.left: faceBody.left
        anchors.topMargin: root._edgeInset
        anchors.leftMargin: root._edgeInset
        cityName: $weatherMgr.cityName
    }

    // Time
    DateTime {
        id: dateTimeBlock
        anchors.top: faceBody.top
        anchors.right: faceBody.right
        anchors.topMargin: root._edgeInset
        anchors.rightMargin: root._edgeInset + root._crownOverlap + root._crownGap
    }

    // Crown
    CrownButton {
        id: crownButton
        x: faceBody.width - root._crownOverlap
        y: dateTimeBlock.y + dateTimeBlock.timeRowCenterY - height / 2
        z: -1
        onPressed: AppShell.crownPressed()
    }

    // Center app area
    AppHost {
        id: appHost
        anchors.centerIn: faceBody
        width: implicitWidth
        height: implicitHeight
    }

    // Temperature
    TemperatureGauge {
        id: tempGauge
        anchors.left: faceBody.left
        anchors.bottom: faceBody.bottom
        anchors.leftMargin: Math.round(15 * PS.scale)
        anchors.bottomMargin: Math.round(8 * PS.scale)
        width: Math.round(30 * PS.scale)

        tempMin: $weatherMgr.tempMin
        tempMax: $weatherMgr.tempMax
        tempCurrent: $weatherMgr.temperature
    }

    // Weather
    WeatherIcon {
        anchors.horizontalCenter: faceBody.horizontalCenter
        anchors.bottom: tempGauge.bottom
        weatherCode: $weatherMgr.weatherCode
    }

    // Eyes
    EyeFace {
        anchors.right: faceBody.right
        anchors.rightMargin: Math.round(15 * PS.scale)
        anchors.bottom: tempGauge.bottom
        watchMouseX: $mouseMgr.pos.x - root.windowX
        watchMouseY: $mouseMgr.pos.y - root.windowY
    }

    // Ctrl + wheel zoom
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        acceptedModifiers: Qt.ControlModifier
        onWheel: (event) => {
            var step = event.angleDelta.y / 120
            var newScale = PS.scale + step * 0.3
            PS.scale = Math.max(0.5, Math.min(15.0, newScale))
        }
    }
}
