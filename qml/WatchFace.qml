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

    // ── 表壳背景 ─────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius:       Math.round(rCorner * PS.scale)
        color:        "black"
        border.width: Math.round(2 * PS.scale)
        border.color: "#C0C0C0"
    }

    // ── 右上角时间区域 ────────────────────────────────────────────────────────
    DateTime {
        anchors.top:         parent.top
        anchors.right:       parent.right
        anchors.topMargin:   Math.round(8 * PS.scale)
        anchors.rightMargin: Math.round(8 * PS.scale)
    }

    // ── 顶部中央：缩放模式切换按钮 ───────────────────────────────────────────
    //Item {
    //    id: scaleBtn
    //    anchors.top:              parent.top
    //    anchors.topMargin:        Math.round(8 * PS.scale)
    //    anchors.horizontalCenter: parent.horizontalCenter
    //    width:  Math.round(12 * PS.scale)
    //    height: Math.round(12 * PS.scale)

    //    property bool scaleMode: false

    //    Image {
    //        anchors.fill: parent
    //        source:       Theme.icon(scaleBtn.scaleMode ? "resize_pressed" : "resize_normal")
    //        sourceSize:   Qt.size(width, height)
    //        fillMode:     Image.PreserveAspectFit
    //    }

    //    MouseArea {
    //        anchors.fill: parent
    //        onClicked:    scaleBtn.scaleMode = !scaleBtn.scaleMode
    //    }
    //}

    // ── 中央：备忘录 ──────────────────────────────────────────────────────────
    MemoList {
        anchors.centerIn: parent
    }

    // ── 左下角：温度表盘 ──────────────────────────────────────────────────────
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

    // ── 底部居中：天气图标 ────────────────────────────────────────────────────
    WeatherIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           tempGauge.bottom
        weatherCode: $weatherMgr.weatherCode
    }

    // ── 右下角：跟踪鼠标的卡通眼睛 ───────────────────────────────────────────
    EyeFace {
        anchors.right:       parent.right
        anchors.rightMargin: Math.round(15 * PS.scale)
        anchors.bottom:      tempGauge.bottom
        watchMouseX: $mouseMgr.pos.x - root.windowX
        watchMouseY: $mouseMgr.pos.y - root.windowY
    }

    // ── 滚轮缩放（仅在缩放模式激活时响应）────────────────────────────────────
    WheelHandler {
        enabled:         scaleBtn.scaleMode
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            var step     = event.angleDelta.y / 120
            var newScale = PS.scale + step * 0.3
            PS.scale     = Math.max(0.5, Math.min(15.0, newScale))
        }
    }

    // ── 呼吸灯 + 距离指示条（位于灰白边框内侧）──────────────────────────────
    //DistanceTip {
    //    readonly property real _bw: Math.round(2 * PS.scale)
    //    anchors.fill:    parent
    //    anchors.margins: _bw
    //    cornerRadius:    Math.max(0, rCorner * PS.scale - _bw)
    //}
}
