import QtQuick
import "./common"

Item {
    id: root

    readonly property real caseW:   44.0 * 3
    readonly property real caseH:   49.0 * 3
    readonly property real rCorner: 7.5 * 3

    property real windowX: 0
    property real windowY: 0

    implicitWidth:  Math.round(caseW * PS.scale)
    implicitHeight: Math.round(caseH * PS.scale)

    // 表壳
    Rectangle {
        anchors.fill: parent
        radius:       Math.round(rCorner * PS.scale)
        color:        "black"
        border.width: Math.round(2 * PS.scale)
        border.color: "#C0C0C0"
    }

    // 地点
    LocationLabel {
        visible:            false
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.topMargin:  Math.round(8 * PS.scale)
        anchors.leftMargin: Math.round(8 * PS.scale)
        cityName:           $weatherMgr.cityName
    }

    // 时间
    DateTime {
        anchors.top:         parent.top
        anchors.right:       parent.right
        anchors.topMargin:   Math.round(8 * PS.scale)
        anchors.rightMargin: Math.round(8 * PS.scale)
    }

    // 备忘录
    MemoList {
        anchors.centerIn: parent
    }

    // 温度
    TemperatureGauge {
        id: tempGauge
        anchors.left:         parent.left
        anchors.bottom:       parent.bottom
        anchors.leftMargin:   Math.round(15 * PS.scale)
        anchors.bottomMargin: Math.round(8 * PS.scale)
        width: Math.round(30 * PS.scale)

        tempMin:     $weatherMgr.tempMin
        tempMax:     $weatherMgr.tempMax
        tempCurrent: $weatherMgr.temperature
    }

    // 天气
    WeatherIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           tempGauge.bottom
        weatherCode: $weatherMgr.weatherCode
    }

    // 眼睛
    EyeFace {
        anchors.right:       parent.right
        anchors.rightMargin: Math.round(15 * PS.scale)
        anchors.bottom:      tempGauge.bottom
        watchMouseX: $mouseMgr.pos.x - root.windowX
        watchMouseY: $mouseMgr.pos.y - root.windowY
    }

    // Ctrl + 滚轮缩放
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        acceptedModifiers: Qt.ControlModifier
        onWheel: (event) => {
            var step     = event.angleDelta.y / 120
            var newScale = PS.scale + step * 0.3
            PS.scale     = Math.max(0.5, Math.min(15.0, newScale))
        }
    }
}
