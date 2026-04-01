import QtQuick

// 温度表盘控件
// 240° 圆弧（缺口朝下），左端=最低温，右端=最高温，圆圈指示当前温度
// 颜色随温度渐变（绝对断点）：≤0蓝 → 0-10绿 → 10-22黄 → 22-32橙 → 32-40红
Item {
    id: root

    property real tempMin:     0.0
    property real tempMax:     30.0
    property real tempCurrent: 15.0

    // 归一化单位：以 width=90 为基准，所有内部尺寸等比缩放
    readonly property real _u: width / 90

    property real arcLineWidth:    Math.round(6  * _u)   // 粗一点
    property real dotRadius:       Math.round(5  * _u)
    property real labelFontSize:   Math.round(13 * _u)
    property real currentFontSize: Math.round(30 * _u)

    // 弧线几何
    readonly property real _startAngle: 5 * Math.PI / 6
    readonly property real _sweepAngle: 4 * Math.PI / 3

    readonly property real _r:    Math.max(1, width / 2 - arcLineWidth / 2 - dotRadius)
    readonly property real _cy:   _r + dotRadius + arcLineWidth / 2
    readonly property real _arcH: _cy + _r / 2 + arcLineWidth / 2

    // 弧端点 X（用于对齐最低/最高温度标签）
    // cos(5π/6) = -√3/2, cos(π/6) = √3/2
    readonly property real _leftEndX:  width / 2 - _r * Math.sqrt(3) / 2
    readonly property real _rightEndX: width / 2 + _r * Math.sqrt(3) / 2

    implicitWidth:  Math.round(80 * PS.scale)
    implicitHeight: _arcH + Math.round(4 * _u) + Math.ceil(labelFontSize * 1.4)

    // ── 弧形画布 ──────────────────────────────────────────────────────────────
    Canvas {
        id: arc
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        height: root._arcH

        onPaint: {
            var ctx   = getContext("2d")
            ctx.reset()

            var cx    = width / 2
            var cy    = root._cy
            var r     = root._r
            var lw    = root.arcLineWidth
            var sa    = root._startAngle
            var sweep = root._sweepAngle

            // 背景轨道（半透明，带圆帽）
            ctx.beginPath()
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.12)
            ctx.lineWidth = lw
            ctx.lineCap = "round"
            ctx.arc(cx, cy, r, sa, sa + sweep, false)
            ctx.stroke()

            // 彩色分段弧线（120 段渐变）
            var N = 120
            for (var i = 0; i < N; i++) {
                var t0   = i / N
                var t1   = (i + 1) / N
                var temp = root.tempMin + (t0 + 0.5 / N) * (root.tempMax - root.tempMin)
                ctx.beginPath()
                ctx.strokeStyle = root.tempColor(temp)
                ctx.lineWidth = lw
                ctx.lineCap = "butt"
                ctx.arc(cx, cy, r, sa + t0 * sweep, sa + t1 * sweep, false)
                ctx.stroke()
            }

            // 两端圆帽
            var leftX  = cx + r * Math.cos(sa)
            var leftY  = cy + r * Math.sin(sa)
            var rightX = cx + r * Math.cos(sa + sweep)
            var rightY = cy + r * Math.sin(sa + sweep)

            ctx.beginPath()
            ctx.fillStyle = root.tempColor(root.tempMin)
            ctx.arc(leftX, leftY, lw / 2, 0, 2 * Math.PI)
            ctx.fill()

            ctx.beginPath()
            ctx.fillStyle = root.tempColor(root.tempMax)
            ctx.arc(rightX, rightY, lw / 2, 0, 2 * Math.PI)
            ctx.fill()

            // 当前温度指示圆圈（用取整值与标签一致）
            var rMin = Math.round(root.tempMin)
            var rMax = Math.round(root.tempMax)
            var rCur = Math.round(root.tempCurrent)
            var range = rMax - rMin
            var tp    = range > 0
                ? Math.max(0, Math.min(1, (rCur - rMin) / range))
                : 0.5
            var da = sa + tp * sweep
            var dx = cx + r * Math.cos(da)
            var dy = cy + r * Math.sin(da)
            var dr = root.dotRadius

            // 外圆环：内径 = 弧线宽（lw），外径稍大，白色半透明描边
            var border = Math.max(1.5, lw * 0.5)
            ctx.beginPath()
            ctx.strokeStyle = "rgba(0,0,0,1)"
            ctx.lineWidth = border
            ctx.arc(dx, dy, lw / 2 + border / 2, 0, 2 * Math.PI)
            ctx.stroke()

            // 内圆点：当前温度颜色填充
            ctx.beginPath()
            ctx.fillStyle = root.tempColor(root.tempCurrent)
            ctx.arc(dx, dy, lw * 0.28, 0, 2 * Math.PI)
            ctx.fill()
        }

        Connections {
            target: root
            function onTempMinChanged()     { arc.requestPaint() }
            function onTempMaxChanged()     { arc.requestPaint() }
            function onTempCurrentChanged() { arc.requestPaint() }
            function on_rChanged()          { arc.requestPaint() }
        }
        onWidthChanged:  requestPaint()
        onHeightChanged: requestPaint()
    }

    // ── 当前气温（圆弧圆心位置）────────────────────────────────────────────
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:       arc.top
        anchors.topMargin: root._cy - implicitHeight / 2
        text:           Math.round(root.tempCurrent)
        color:          "white"
        font.pixelSize: root.currentFontSize
        font.bold:      true
    }

    // ── 最低 / 最高温度标签（对齐弧端点正下方）────────────────────────────────
    Item {
        anchors.top:       arc.bottom
        anchors.left:      parent.left
        anchors.right:     parent.right
        anchors.topMargin: Math.round(3 * root._u)
        height: Math.ceil(root.labelFontSize * 1.4)

        Text {
            id: minLabel
            x:              root._leftEndX - implicitWidth / 2 + Math.round(6 * root._u)
            anchors.verticalCenter: parent.verticalCenter
            text:           Math.round(root.tempMin)
            color:          root.tempColor(root.tempMin)
            font.pixelSize: root.labelFontSize
            font.bold:      true
        }
        Text {
            id: maxLabel
            x:              root._rightEndX - implicitWidth / 2 - Math.round(6 * root._u)
            anchors.verticalCenter: parent.verticalCenter
            text:           Math.round(root.tempMax)
            color:          root.tempColor(root.tempMax)
            font.pixelSize: root.labelFontSize
            font.bold:      true
        }
    }

    // ── 颜色映射（绝对温度断点，参考常见天气应用色阶）──────────────────────
    // ≤0蓝 → 0-10绿 → 10-22黄 → 22-32橙 → 32-40红 → >40深红
    function tempColor(temp) {
        if (temp <= 0)   return "#2288FF"
        if (temp <= 10)  return lerp("#2288FF", "#33BB44", temp / 10)
        if (temp <= 22)  return lerp("#33BB44", "#FFCC00", (temp - 10) / 12)
        if (temp <= 32)  return lerp("#FFCC00", "#FF7700", (temp - 22) / 10)
        if (temp <= 40)  return lerp("#FF7700", "#FF1100", (temp - 32) / 8)
        return "#FF1100"
    }

    function lerp(c1, c2, t) {
        var r1 = parseInt(c1.slice(1,3), 16), r2 = parseInt(c2.slice(1,3), 16)
        var g1 = parseInt(c1.slice(3,5), 16), g2 = parseInt(c2.slice(3,5), 16)
        var b1 = parseInt(c1.slice(5,7), 16), b2 = parseInt(c2.slice(5,7), 16)
        return "#"
            + Math.round(r1 + (r2 - r1) * t).toString(16).padStart(2, "0")
            + Math.round(g1 + (g2 - g1) * t).toString(16).padStart(2, "0")
            + Math.round(b1 + (b2 - b1) * t).toString(16).padStart(2, "0")
    }
}
