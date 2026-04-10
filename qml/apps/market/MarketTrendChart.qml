import QtQuick

Item {
    id: root

    property var points: []
    property double changeValue: 0
    property double referenceValue: NaN
    property color upColor: "#FF5A4F"
    property color downColor: "#37C878"
    property color neutralColor: Qt.rgba(1, 1, 1, 0.68)
    property string unavailableText: "走势暂不可用"

    readonly property int pointCount: root.points && root.points.length ? root.points.length : 0
    readonly property var _values: root.numericValues()
    readonly property double minValue: root._values.length ? Math.min.apply(null, root._values) : 0
    readonly property double maxValue: root._values.length ? Math.max.apply(null, root._values) : 0
    readonly property double valueSpan: Math.max(0.01, root.maxValue - root.minValue)
    readonly property double paddingValue: Math.max(0.08, root.valueSpan * 0.16)
    readonly property double paddedMin: root._values.length ? root.minValue - root.paddingValue : 0
    readonly property double paddedMax: root._values.length ? root.maxValue + root.paddingValue : 1
    readonly property color lineColor: root.changeValue > 0.0001 ? root.upColor
                                     : root.changeValue < -0.0001 ? root.downColor
                                     : root.neutralColor
    readonly property string lineStroke: root.changeValue > 0.0001 ? "#FF5A4F"
                                      : root.changeValue < -0.0001 ? "#37C878"
                                      : "rgba(255,255,255,0.68)"
    readonly property string fillTop: root.changeValue > 0.0001 ? "rgba(255,90,79,0.24)"
                                   : root.changeValue < -0.0001 ? "rgba(55,200,120,0.24)"
                                   : "rgba(255,255,255,0.16)"
    readonly property string fillBottom: root.changeValue > 0.0001 ? "rgba(255,90,79,0.02)"
                                      : root.changeValue < -0.0001 ? "rgba(55,200,120,0.02)"
                                      : "rgba(255,255,255,0.02)"
    readonly property string haloStroke: root.changeValue > 0.0001 ? "rgba(255,90,79,0.28)"
                                      : root.changeValue < -0.0001 ? "rgba(55,200,120,0.28)"
                                      : "rgba(255,255,255,0.24)"
    readonly property string firstLabel: root.pointCount > 0 ? root.labelAt(0) : ""
    readonly property string lastLabel: root.pointCount > 0 ? root.labelAt(root.pointCount - 1) : ""
    readonly property bool canDraw: root.pointCount >= 2

    function numericValues() {
        var values = []
        for (var i = 0; i < root.pointCount; ++i) {
            var point = root.points[i]
            var value = point && point.value !== undefined ? Number(point.value) : NaN
            if (value === value)
                values.push(value)
        }
        return values
    }

    function labelAt(index) {
        if (index < 0 || index >= root.pointCount)
            return ""
        var point = root.points[index]
        return point && point.label !== undefined ? String(point.label) : ""
    }

    function formatValue(number) {
        if (number !== number)
            return "--"
        return Number(number).toFixed(number >= 1000 ? 0 : 2)
    }

    function pointY(value, top, height) {
        if (root.paddedMax <= root.paddedMin)
            return top + height / 2
        var ratio = (value - root.paddedMin) / (root.paddedMax - root.paddedMin)
        ratio = Math.max(0, Math.min(1, ratio))
        return top + (1 - ratio) * height
    }

    Canvas {
        id: chartCanvas
        anchors.fill: parent
        anchors.bottomMargin: Math.round(6 * PS.scale)

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var left = Math.round(2 * PS.scale)
            var top = Math.round(4 * PS.scale)
            var right = Math.round(2 * PS.scale)
            var bottom = Math.round(4 * PS.scale)
            var plotWidth = Math.max(1, width - left - right)
            var plotHeight = Math.max(1, height - top - bottom)

            ctx.strokeStyle = "rgba(255,255,255,0.08)"
            ctx.lineWidth = 1
            for (var g = 0; g < 4; ++g) {
                var gy = top + plotHeight * g / 3
                ctx.beginPath()
                ctx.moveTo(left, gy)
                ctx.lineTo(left + plotWidth, gy)
                ctx.stroke()
            }

            if (!root.canDraw)
                return

            if (root.referenceValue === root.referenceValue
                    && root.referenceValue >= root.paddedMin
                    && root.referenceValue <= root.paddedMax) {
                var refY = root.pointY(root.referenceValue, top, plotHeight)
                ctx.strokeStyle = "rgba(255,255,255,0.18)"
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(left, refY)
                ctx.lineTo(left + plotWidth, refY)
                ctx.stroke()
            }

            var gradient = ctx.createLinearGradient(0, top, 0, top + plotHeight)
            gradient.addColorStop(0, root.fillTop)
            gradient.addColorStop(1, root.fillBottom)

            ctx.beginPath()
            for (var i = 0; i < root.pointCount; ++i) {
                var point = root.points[i]
                var value = Number(point.value)
                if (value !== value)
                    continue

                var x = left + (root.pointCount === 1 ? 0 : (plotWidth * i / (root.pointCount - 1)))
                var y = root.pointY(value, top, plotHeight)
                if (i === 0)
                    ctx.moveTo(x, y)
                else
                    ctx.lineTo(x, y)
            }

            ctx.lineTo(left + plotWidth, top + plotHeight)
            ctx.lineTo(left, top + plotHeight)
            ctx.closePath()
            ctx.fillStyle = gradient
            ctx.fill()

            ctx.beginPath()
            for (var j = 0; j < root.pointCount; ++j) {
                var chartPoint = root.points[j]
                var chartValue = Number(chartPoint.value)
                if (chartValue !== chartValue)
                    continue

                var px = left + (root.pointCount === 1 ? 0 : (plotWidth * j / (root.pointCount - 1)))
                var py = root.pointY(chartValue, top, plotHeight)
                if (j === 0)
                    ctx.moveTo(px, py)
                else
                    ctx.lineTo(px, py)
            }
            ctx.strokeStyle = root.lineStroke
            ctx.lineWidth = Math.max(1.2, 1.3 * PS.scale)
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.stroke()

            var lastPoint = root.points[root.pointCount - 1]
            var lastValue = Number(lastPoint.value)
            if (lastValue === lastValue) {
                var lx = left + plotWidth
                var ly = root.pointY(lastValue, top, plotHeight)
                ctx.beginPath()
                ctx.arc(lx, ly, Math.max(1.5, 1.8 * PS.scale), 0, Math.PI * 2)
                ctx.fillStyle = root.lineStroke
                ctx.fill()
                ctx.beginPath()
                ctx.arc(lx, ly, Math.max(2.8, 3.0 * PS.scale), 0, Math.PI * 2)
                ctx.strokeStyle = root.haloStroke
                ctx.lineWidth = Math.max(1, 1.0 * PS.scale)
                ctx.stroke()
            }
        }

        Connections {
            target: root
            function onPointsChanged() { chartCanvas.requestPaint() }
            function onReferenceValueChanged() { chartCanvas.requestPaint() }
            function onChangeValueChanged() { chartCanvas.requestPaint() }
            function onWidthChanged() { chartCanvas.requestPaint() }
            function onHeightChanged() { chartCanvas.requestPaint() }
        }
    }

    Text {
        visible: root.canDraw
        text: root.formatValue(root.maxValue)
        color: Qt.rgba(1, 1, 1, 0.52)
        font.pixelSize: Math.round(3.2 * PS.scale)
        anchors.top: parent.top
        anchors.right: parent.right
    }

    Text {
        visible: root.canDraw
        text: root.formatValue(root.minValue)
        color: Qt.rgba(1, 1, 1, 0.34)
        font.pixelSize: Math.round(3.2 * PS.scale)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(6 * PS.scale)
        anchors.right: parent.right
    }

    Text {
        visible: root.canDraw
        text: root.firstLabel
        color: Qt.rgba(1, 1, 1, 0.34)
        font.pixelSize: Math.round(3.1 * PS.scale)
        anchors.left: parent.left
        anchors.bottom: parent.bottom
    }

    Text {
        visible: root.canDraw
        text: root.lastLabel
        color: Qt.rgba(1, 1, 1, 0.34)
        font.pixelSize: Math.round(3.1 * PS.scale)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    Text {
        visible: !root.canDraw
        anchors.centerIn: parent
        text: root.unavailableText
        color: Qt.rgba(1, 1, 1, 0.32)
        font.pixelSize: Math.round(3.7 * PS.scale)
    }
}