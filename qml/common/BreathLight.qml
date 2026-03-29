import QtQuick

// 呼吸灯环：围绕表盘四周的发光方形环
// 颜色与 DistanceBar 三区对应：近端橙→中段青绿→远端蓝
// 用法示例：
//   BreathLight {
//       anchors.fill: parent
//       cornerRadius: ...
//       distanceMin: 250;  distanceMax: 350
//       distance: sensorMgr.distance
//       glowWidth: 30
//   }
Item {
    id: root

    // ── 外部可配置属性 ────────────────────────────────────────────────────────
    property real cornerRadius: 0

    property real distanceMin: 250
    property real distanceMax: 350
    property real distance:    0

    // 光晕向内扩散的像素宽度
    property real glowWidth: 10

    // 层数：越多越平滑，80 层基本消除条纹
    property int  glowLayers: 20

    // 衰减曲线偏移量，可取负值
    //   正值（0~1）：外侧保持满亮度的占比，0.5 = 前半段全亮后半段渐隐
    //   0.0        ：从外边缘即开始二次衰减（默认）
    //   负值       ：衰减更猛，外边缘已部分变暗；-1 ≈ 外边缘 75%，-2 ≈ 外边缘 56%
    property real brightRatio: -2

    // ── 呼吸振幅 ──────────────────────────────────────────────────────────────
    // 仅用于驱动 Canvas 的 opacity，不触发重绘，嵌入式友好
    property real _breath: 1

    SequentialAnimation on _breath {
        loops: Animation.Infinite
        running: true
        NumberAnimation { to: 1.0;  duration: 1200; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.6; duration: 1200; easing.type: Easing.InOutSine }
    }

    // ── 颜色计算：与 DistanceBar 三区对应（2+3+2 分组）────────────────────────
    // 近端(0~2/7):#FF8533  中段(2/7~5/7):#00A17F  远端(5/7~1):#007AFE
    function glowColor(alpha) {
        var span = distanceMax - distanceMin
        var t    = span > 0 ? (distance - distanceMin) / span : 0.5
        var c
        if      (t < 2 / 7) c = Qt.color("#007AFE")
        else if (t < 5 / 7) c = Qt.color("#00A17F")
        else                 c = Qt.color("#FF8533")
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }

    // ── Canvas 描边光晕 ───────────────────────────────────────────────────────
    // 呼吸效果通过 opacity 实现，Canvas 本身只在几何参数变化时重绘（偶发）。
    // opacity 变化由合成器处理（对已有位图做 alpha 缩放），嵌入式 CPU 开销极小。
    Canvas {
        id: glowCanvas
        anchors.fill: parent

        // 呼吸动画：仅改 opacity，不触发 requestPaint
        opacity: root._breath

        function rrCW(ctx, x, y, w, h, r) {
            r = Math.max(0, Math.min(r, w / 2, h / 2))
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.arcTo(x + w, y,     x + w, y + r,     r)
            ctx.lineTo(x + w, y + h - r)
            ctx.arcTo(x + w, y + h, x + w - r, y + h, r)
            ctx.lineTo(x + r, y + h)
            ctx.arcTo(x,     y + h, x,         y + h - r, r)
            ctx.lineTo(x, y + r)
            ctx.arcTo(x,     y,     x + r,     y,     r)
            ctx.closePath()
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var w  = width
            var h  = height
            var r  = root.cornerRadius
            var gw = root.glowWidth
            var N  = root.glowLayers

            // 裁剪至控件外边界，防止最外层描边向外溢出
            ctx.beginPath()
            rrCW(ctx, 0, 0, w, h, r)
            ctx.clip()

            ctx.lineJoin = "round"
            ctx.lineCap  = "square"

            // 描边宽度：单层理论厚度 + 1px 重叠（利用 AA 平滑层间边界）
            var lw = gw / N + 1.0
            var br = Math.min(0.999, root.brightRatio)

            // 从内（暗）向外（亮）绘制，使亮层在重叠区域自然覆盖暗层
            for (var i = N - 1; i >= 0; i--) {
                var midRatio = (i + 0.5) / N
                var midInset = midRatio * gw

                // brightRatio 内保持满亮度，之后做二次衰减至透明；负值使外边缘也参与衰减
                var fadeRatio = Math.max(0, (midRatio - br) / (1.0 - br))
                var alpha = 1.0 - fadeRatio * fadeRatio   // _breath 已由 opacity 统一处理
                if (alpha < 0.004) continue

                var mw  = w - midInset * 2
                var mh  = h - midInset * 2
                var mrr = Math.max(0, r - midInset)
                if (mw <= 0 || mh <= 0) continue

                ctx.beginPath()
                rrCW(ctx, midInset, midInset, mw, mh, mrr)
                ctx.strokeStyle = root.glowColor(alpha)
                ctx.lineWidth   = lw
                ctx.stroke()
            }
        }

        // _breath 已通过 opacity 绑定，不需要出现在 _deps 里
        property var _deps: [root.glowWidth, root.glowLayers,
                             root.distance, root.distanceMin, root.distanceMax,
                             root.cornerRadius, root.brightRatio,
                             width, height]
        on_DepsChanged: requestPaint()
    }
}
