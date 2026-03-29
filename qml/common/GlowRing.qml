import QtQuick

// 呼吸灯环（SVG 版）：通过预渲染 SVG 替代 Canvas 绘制，嵌入式友好
// 三区颜色与 DistanceBar/BreathLight 一致：近端橙→中段青绿→远端蓝
// 用法示例：
//   GlowRing {
//       anchors.fill: parent
//       distanceMin: 250;  distanceMax: 350
//       distance: sensorMgr.distance
//   }
Item {
    id: root

    property real distanceMin: 250
    property real distanceMax: 350
    property real distance:    0

    // 供外部读取当前区域（0=远端蓝, 1=中段青绿, 2=近端橙）
    readonly property int zone: {
        var span = distanceMax - distanceMin
        var t    = span > 0 ? (distance - distanceMin) / span : 0.5
        if      (t < 2 / 7) return 0   // 远端蓝
        else if (t < 5 / 7) return 1   // 中段青绿
        else                 return 2   // 近端橙
    }

    // ── 呼吸振幅（驱动外层容器 opacity，与区域切换完全解耦）─────────────────
    property real _breath: 1.0

    SequentialAnimation on _breath {
        loops:   Animation.Infinite
        running: true
        NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.3; duration: 1200; easing.type: Easing.InOutSine }
    }

    // ── 外层容器：统一承载呼吸 opacity，不受 Behavior 干扰 ────────────────
    Item {
        anchors.fill: parent
        opacity: root._breath   // 持续变化，无 Behavior，直接绑定

        // zone 切换用 visible 瞬切，不用 opacity 渐变
        // 原因：opacity 淡入从 0 开始，会打断呼吸节奏；
        //       visible 切换是瞬时的，呼吸由外层 _breath 统一管理，不受影响

        // ── 远端蓝（zone 0）─────────────────────────────────────────────────
        Image {
            anchors.fill: parent
            source:       Theme.icon("glow_far")
            fillMode:     Image.Stretch
            visible:      root.zone === 0
        }

        // ── 中段青绿（zone 1）────────────────────────────────────────────────
        Image {
            anchors.fill: parent
            source:       Theme.icon("glow_mid")
            fillMode:     Image.Stretch
            visible:      root.zone === 1
        }

        // ── 近端橙（zone 2）─────────────────────────────────────────────────
        Image {
            anchors.fill: parent
            source:       Theme.icon("glow_near")
            fillMode:     Image.Stretch
            visible:      root.zone === 2
        }
    }
}
