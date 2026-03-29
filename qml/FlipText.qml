import QtQuick

// 带翻转动画的文字组件
// 用法：
//   FlipText { text: "12"; flipEnabled: true; textColor: "white"; pixelSize: 24; bold: true }
Item {
    id: root

    property string text:        ""
    property bool   flipEnabled: true   // false 时直接切换，不播放动画
    property color  textColor:   "white"
    property real   pixelSize:   12
    property bool   bold:        false

    implicitWidth:  label.implicitWidth
    implicitHeight: label.implicitHeight

    // 延迟标记，避免初始化时触发翻转
    property bool _ready: false

    Text {
        id: label
        color:          root.textColor
        font.pixelSize: root.pixelSize
        font.bold:      root.bold
        layer.enabled:  true              // 离屏纹理，3D 旋转更平滑

        transform: Rotation {
            id: rot
            origin.x: label.width  / 2
            origin.y: label.height / 2
            axis { x: 1; y: 0; z: 0 }    // 绕 X 轴翻转（上下翻页效果）
            angle: 0
        }
    }

    // 首次完成初始化后同步文字，不触发动画
    Component.onCompleted: {
        label.text = root.text
        _ready = true
    }

    onTextChanged: {
        if (!_ready) return
        if (!flipEnabled) {
            label.text = root.text
            return
        }
        flipAnim.restart()
    }

    SequentialAnimation {
        id: flipAnim
        // 上半张翻出（旧内容离开）
        NumberAnimation {
            target: rot; property: "angle"
            from: 0; to: -90; duration: 120
            easing.type: Easing.InQuad
        }
        // 切换内容
        ScriptAction { script: label.text = root.text }
        // 下半张翻入（新内容进入）
        NumberAnimation {
            target: rot; property: "angle"
            from: 90; to: 0; duration: 120
            easing.type: Easing.OutQuad
        }
    }
}