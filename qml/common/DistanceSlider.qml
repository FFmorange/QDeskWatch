import QtQuick

// 距离滑块：竖直轨道 + 滑动指示块，颜色与三区对应
// 用法示例：
//   DistanceSlider {
//       distanceMin: 250;  distanceMax: 350
//       distance: sensorMgr.distance
//   }
Item {
    id: root

    property real distanceMin: 250
    property real distanceMax: 350
    property real distance:    0

    implicitWidth:  Math.round(10 * PS.scale)
    implicitHeight: Math.round(60 * PS.scale)

    // ── 归一化位置：0.0 = 近端(底)，1.0 = 远端(顶) ───────────────────────────
    readonly property real _t: {
        var span = distanceMax - distanceMin
        return span > 0 ? Math.max(0.0, Math.min(1.0, (distance - distanceMin) / span)) : 0.0
    }

    // ── 三区颜色（与 DistanceBar / BreathLight 一致）──────────────────────────
    readonly property color _color: {
        if      (_t < 2 / 7) return "#007AFE"    // 远端蓝
        else if (_t < 5 / 7) return "#00A17F"    // 中段青绿
        else                  return "#FF8533"   // 近端橙
    }

    // ── 轨道背景 ──────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius:       width / 2
        color:        "#DEE1E3"
    }

    // ── 指示块 ────────────────────────────────────────────────────────────────
    Rectangle {
        id: thumb

        readonly property real _thumbH: Math.round(root.height / 4)

        width:  root.width
        height: _thumbH
        radius: width / 2
        color:  root._color

        // 近端(t=0)在底部，远端(t=1)在顶部；轨道与滑块同 radius，两端自然对齐
        // y 直接跟随 distance 动画，不加 Behavior（否则连续变化时永远追不上端点）
        y: Math.round((1.0 - root._t) * (root.height - _thumbH))

        Behavior on color { ColorAnimation { duration: 300 } }
    }
}
