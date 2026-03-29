import QtQuick

// 心情选择控件
// 平时显示当前心情 GIF，点击后弹出网格选择面板，超出高度可滚轮滚动
Item {
    id: root

    property string currentMood: "happy-face.gif"

    readonly property var _moods: [
        { file: "happy-face.gif",   label: "开心" },
        { file: "neutral.gif",      label: "平静" },
        { file: "boring.gif",       label: "无聊" },
        { file: "disappointed.gif", label: "失望" },
        { file: "embarrassed.gif",  label: "尴尬" },
        { file: "happyToSad.gif",   label: "忧郁" },
        { file: "sleeping.gif",     label: "困倦" },
    ]

    readonly property real _cellSize: Math.round(35 * PS.scale)
    readonly property int  _cols:     3
    readonly property real _maxPopH:  Math.round(90 * PS.scale)
    readonly property real _gap:      Math.round(4 * PS.scale)

    implicitWidth:  Math.round(30 * PS.scale)
    implicitHeight: implicitWidth

    // ── 当前心情图标（点击切换弹窗）──────────────────────────────────────────
    AnimatedImage {
        anchors.fill: parent
        source:   "qrc:/qt/qml/iWatch/resources/gifs/" + root.currentMood
        playing:  true
        fillMode: Image.PreserveAspectFit
    }

    MouseArea {
        anchors.fill: parent
        onClicked:    popup.visible = !popup.visible
    }

    // ── 选择弹出层 ────────────────────────────────────────────────────────────
    Item {
        id: popup
        visible: false
        z:       100

        width:  _cols * _cellSize
        height: Math.min(Math.ceil(_moods.length / _cols) * _cellSize, _maxPopH)

        // 弹出在按钮正上方，右边缘与按钮对齐
        x: root.width - width
        y: -height - _gap

        // 点击弹窗外部时关闭
        MouseArea {
            width:   10000
            height:  10000
            x:       -5000
            y:       -5000
            z:       -1
            visible: popup.visible
            onClicked: popup.visible = false
        }

        // 背景板
        Rectangle {
            anchors.fill: parent
            color:        Qt.rgba(0.08, 0.08, 0.08, 0.93)
            radius:       Math.round(8 * PS.scale)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
        }

        // 可滚动心情格
        Flickable {
            id: flick
            anchors {
                fill:    parent
                margins: Math.round(4 * PS.scale)
            }
            clip:           true
            contentWidth:   _cols * _cellSize
            contentHeight:  moodGrid.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Grid {
                id: moodGrid
                columns: _cols
                spacing: 0

                Repeater {
                    model: root._moods
                    delegate: Item {
                        id: cell
                        width:  _cellSize
                        height: _cellSize

                        readonly property bool _selected: root.currentMood === modelData.file

                        // 选中高亮背景
                        Rectangle {
                            anchors.fill:    parent
                            anchors.margins: Math.round(3 * PS.scale)
                            radius:          Math.round(6 * PS.scale)
                            color:           cell._selected
                                             ? Qt.rgba(1, 1, 1, 0.18)
                                             : "transparent"
                        }

                        // GIF
                        AnimatedImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top:              parent.top
                            anchors.topMargin:        Math.round(4 * PS.scale)
                            width:   Math.round(_cellSize * 0.58)
                            height:  width
                            source:  "qrc:/qt/qml/iWatch/resources/gifs/" + modelData.file
                            playing: popup.visible
                            fillMode: Image.PreserveAspectFit
                        }

                        // 标签
                        Text {
                            anchors.bottom:           parent.bottom
                            anchors.bottomMargin:     Math.round(4 * PS.scale)
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           modelData.label
                            color:          cell._selected ? "white" : Qt.rgba(1, 1, 1, 0.55)
                            font.pixelSize: Math.max(8, Math.round(5 * PS.scale))
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.currentMood = modelData.file
                                popup.visible    = false
                            }
                        }
                    }
                }
            }

            // 滚轮支持
            WheelHandler {
                onWheel: (event) => {
                    var delta = -event.angleDelta.y / 3
                    flick.contentY = Math.max(0,
                        Math.min(flick.contentHeight - flick.height,
                                 flick.contentY + delta))
                    event.accepted = true
                }
            }
        }
    }
}
