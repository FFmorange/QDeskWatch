import QtQuick

// 距离提示组合控件：呼吸灯环 + 右侧距离指示条
// 用法示例：
//   DistanceTip {
//       anchors.fill: parent
//       anchors.margins: borderWidth
//       cornerRadius: ...
//       distanceMin: 250; distanceMax: 350
//       distance: sensorMgr.distance   // 正式使用时绑定传感器
//   }
Item {
    id: root

    property real distanceMin:  250
    property real distanceMax:  350
    property real distance:     0
    property real cornerRadius: 0

    // ── 测试用：distance 自动往返，正式接入传感器时删除 ──────────────────────
    SequentialAnimation on distance {
        loops: Animation.Infinite
        running: true
        NumberAnimation { to: root.distanceMax; duration: 1000; easing.type: Easing.InOutSine }
        NumberAnimation { to: root.distanceMin; duration: 1000; easing.type: Easing.InOutSine }
    }

    // ── 呼吸灯环（贴合父项边缘向内发光）────────────────────────────────────
    //BreathLight {
    //    anchors.fill: parent
    //    cornerRadius: root.cornerRadius
    //    distance:     root.distance
    //    distanceMin:  root.distanceMin
    //    distanceMax:  root.distanceMax
    //}

    GlowRing {
        anchors.fill: parent
        distance:     root.distance
        distanceMin:  root.distanceMin
        distanceMax:  root.distanceMax
    }

    // ── 左侧距离滑块（尺寸随控件高度自适应）────────────────────────────────
    DistanceSlider {
        anchors.left:          parent.left
        anchors.leftMargin:    Math.round(parent.height / 20)
        anchors.verticalCenter: parent.verticalCenter

        width:  Math.round(parent.height / 18)
        height: Math.round(parent.height * 0.6)

        distance:     root.distance
        distanceMin:  root.distanceMin
        distanceMax:  root.distanceMax
    }

    // ── 右侧距离指示条（尺寸随控件高度自适应）──────────────────────────────
    DistanceBar {
        readonly property real _bh: Math.round(parent.height / 12)

        anchors.right:          parent.right
        anchors.rightMargin:    Math.round(parent.height / 20)
        anchors.verticalCenter: parent.verticalCenter

        distance:     root.distance
        distanceMin:  root.distanceMin
        distanceMax:  root.distanceMax

        blockHeight:  _bh
        blockWidth:   Math.round(_bh * 0.60)
        blockSpacing: Math.max(2, Math.round(_bh * 0.25))
        blockRadius:  Math.max(1, Math.round(_bh * 0.15))
    }
}
