import QtQuick

// 卡通眼睛小脸 —— 眼睛跟随鼠标方向
// 使用方：将表盘坐标系下的鼠标位置传入 watchMouseX / watchMouseY
Item {
    id: root

    signal doubleTapped()

    property real watchMouseX: 0
    property real watchMouseY: 0

    implicitWidth:  Math.round(28 * PS.scale)
    implicitHeight: implicitWidth

    // ── 脸部几何（均为本地坐标）──────────────────────────────────────────────
    readonly property real _cx:    width  * 0.5
    readonly property real _cy:    height * 0.5
    readonly property real _faceR: Math.min(width, height) * 0.48

    readonly property real _eyeR:  _faceR * 0.215
    readonly property real _eyeLX: _cx - _faceR * 0.305
    readonly property real _eyeRX: _cx + _faceR * 0.305
    readonly property real _eyeY:  _cy - _faceR * 0.24

    readonly property real _pupilR: _eyeR * 0.52
    readonly property real _maxTravel: _eyeR * 0.22

    // ── 平滑的眼珠位置（相对眼球中心的偏移）─────────────────────────────────
    property real lOffX: 0
    property real lOffY: 0
    property real rOffX: 0
    property real rOffY: 0

    Behavior on lOffX { SmoothedAnimation { duration: 120; velocity: -1 } }
    Behavior on lOffY { SmoothedAnimation { duration: 120; velocity: -1 } }
    Behavior on rOffX { SmoothedAnimation { duration: 120; velocity: -1 } }
    Behavior on rOffY { SmoothedAnimation { duration: 120; velocity: -1 } }

    onLOffXChanged: canvas.requestPaint()
    onLOffYChanged: canvas.requestPaint()
    onROffXChanged: canvas.requestPaint()
    onROffYChanged: canvas.requestPaint()
    onWidthChanged:  { _updatePupils(); canvas.requestPaint() }
    onHeightChanged: { _updatePupils(); canvas.requestPaint() }

    // ── 鼠标变化时更新眼珠目标位置 ───────────────────────────────────────────
    onWatchMouseXChanged: _updatePupils()
    onWatchMouseYChanged: _updatePupils()

    function _calcOffset(eyeX, eyeY, mx, my) {
        var dx = mx - eyeX
        var dy = my - eyeY
        var d  = Math.sqrt(dx * dx + dy * dy)
        if (d < 0.5) return Qt.point(0, 0)
        var s = Math.min(d, _maxTravel) / d
        return Qt.point(dx * s, dy * s)
    }

    function _updatePupils() {
        // 将表盘坐标转为本地坐标
        var mx = watchMouseX - x
        var my = watchMouseY - y
        var l  = _calcOffset(_eyeLX, _eyeY, mx, my)
        var r  = _calcOffset(_eyeRX, _eyeY, mx, my)
        lOffX = l.x;  lOffY = l.y
        rOffX = r.x;  rOffY = r.y
    }

    // ── 画布 ─────────────────────────────────────────────────────────────────
    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            // 贝塞尔椭圆路径
            function ellipsePath(ex, ey, rx, ry) {
                var kx = rx * 0.5522848
                var ky = ry * 0.5522848
                ctx.beginPath()
                ctx.moveTo(ex - rx, ey)
                ctx.bezierCurveTo(ex - rx, ey - ky, ex - kx, ey - ry, ex,      ey - ry)
                ctx.bezierCurveTo(ex + kx, ey - ry, ex + rx, ey - ky, ex + rx, ey     )
                ctx.bezierCurveTo(ex + rx, ey + ky, ex + kx, ey + ry, ex,      ey + ry)
                ctx.bezierCurveTo(ex - kx, ey + ry, ex - rx, ey + ky, ex - rx, ey     )
                ctx.closePath()
            }

            var cx    = root._cx
            var cy    = root._cy
            var fR    = root._faceR
            var eyeLX = root._eyeLX
            var eyeRX = root._eyeRX
            var eyeY  = root._eyeY

            // ── 圆形脸（径向渐变，模拟 emoji 球面反光）
            var grad = ctx.createRadialGradient(
                cx - fR * 0.28, cy - fR * 0.32, fR * 0.05,
                cx + fR * 0.08, cy + fR * 0.08, fR * 1.02
            )
            grad.addColorStop(0.00, "#FFE566")
            grad.addColorStop(0.45, "#FFC83D")
            grad.addColorStop(1.00, "#B86000")
            ctx.beginPath()
            ctx.arc(cx, cy, fR, 0, 2 * Math.PI)
            ctx.fillStyle = grad
            ctx.fill()
            ctx.strokeStyle = "#A05000"
            ctx.lineWidth   = Math.max(1, fR * 0.04)
            ctx.stroke()

            // ── 眼白（圆形，固定不动）
            var wR = fR * 0.250

            ctx.beginPath()
            ctx.arc(eyeLX, eyeY, wR, 0, 2 * Math.PI)
            ctx.fillStyle = "#FFFFFF"
            ctx.fill()

            ctx.beginPath()
            ctx.arc(eyeRX, eyeY, wR, 0, 2 * Math.PI)
            ctx.fillStyle = "#FFFFFF"
            ctx.fill()

            // ── 瞳孔（圆形，跟随鼠标偏移）
            var pR = fR * 0.138

            ctx.beginPath()
            ctx.arc(eyeLX + root.lOffX, eyeY + root.lOffY, pR, 0, 2 * Math.PI)
            ctx.fillStyle = "#1C1200"
            ctx.fill()

            ctx.beginPath()
            ctx.arc(eyeRX + root.rOffX, eyeY + root.rOffY, pR, 0, 2 * Math.PI)
            ctx.fillStyle = "#1C1200"
            ctx.fill()

            // ── 微笑嘴巴（宽弧线，🙂 风格）
            var sL = cx - fR * 0.40
            var sR = cx + fR * 0.40
            var sY = cy + fR * 0.22
            var sD = fR * 0.22

            ctx.beginPath()
            ctx.moveTo(sL, sY)
            ctx.bezierCurveTo(
                cx - fR * 0.13, sY + sD,
                cx + fR * 0.13, sY + sD,
                sR, sY)
            ctx.strokeStyle = "#7C4000"
            ctx.lineWidth   = Math.max(2, fR * 0.10)
            ctx.lineCap     = "round"
            ctx.stroke()
        }
    }

    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onDoubleTapped: root.doubleTapped()
    }
}
