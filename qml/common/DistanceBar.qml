import QtQuick

// 距离指示条：7块竖直排列，近端橙色(下)→中间青绿→远端蓝色(上)
// 用法示例：
//   DistanceBar {
//       anchors.right: parent.right
//       anchors.verticalCenter: parent.verticalCenter
//       distanceMin: 250; distanceMax: 350
//       distance: sensorMgr.distance
//   }
Item {
    id: root

    property real distanceMin: 250
    property real distanceMax: 350
    property real distance:    0

    property real blockWidth:   8 * PS.scale
    property real blockHeight:  10 * PS.scale
    property real blockSpacing:  3 * PS.scale
    property real blockRadius:   2 * PS.scale
    property real borderWidth:   1 * PS.scale

    implicitWidth:  blockWidth
    implicitHeight: 7 * blockHeight + 6 * blockSpacing

    // 7块颜色：索引 0~1 橙(近端)，2~4 青绿(中段)，5~6 蓝(远端)
    readonly property var fillColors: [
        "#007AFE", "#007AFE",
        "#00A17F", "#00A17F", "#00A17F",
        "#FF8533", "#FF8533"
    ]
    readonly property var borderColors: [
        "#66B0FF", "#66B0FF",
        "#4FC4AB", "#4FC4AB", "#4FC4AB",
        "#FEA900", "#FEA900"
    ]

    // 当前激活块索引（0 = 最近端，6 = 最远端）
    readonly property int activeIndex: {
        var span = distanceMax - distanceMin
        if (span <= 0) return 0
        var idx = Math.floor((distance - distanceMin) / span * 7)
        return Math.max(0, Math.min(6, idx))
    }

    // Column 从上到下：远端蓝色在顶，近端橙色在底
    Column {
        anchors.fill: parent
        spacing: root.blockSpacing

        Repeater {
            model: 7
            delegate: Rectangle {
                // 翻转索引：Column[0] → barIdx=6(顶/远端蓝)，Column[6] → barIdx=0(底/近端橙)
                readonly property int barIdx: 6 - index

                width:  root.blockWidth
                height: root.blockHeight
                radius: root.blockRadius

                // 激活块显示填充色，非激活块仅显示边框
                color:        barIdx === root.activeIndex
                              ? root.fillColors[barIdx]
                              : Qt.rgba(1, 1, 1, 0.05)
                border.color: root.borderColors[barIdx]
                border.width: root.borderWidth

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }
}
