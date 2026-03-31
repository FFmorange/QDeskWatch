import QtQuick
import QtQuick.Window
import "./qml"

Window {
    id: root

    width:  Math.round(44 * 3 * PS.scale)
    height: Math.round(49 * 3 * PS.scale)
    visible: true
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"

    WatchFace {
        anchors.centerIn: parent
        windowX: root.x
        windowY: root.y

        DragHandler {
            onActiveChanged: if (active) root.startSystemMove()
        }
    }
}
