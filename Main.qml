import QtQuick
import QtQuick.Window
import "./qml"

Window {
    id: root

    width:  watchFace.implicitWidth
    height: watchFace.implicitHeight
    visible: true
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"

    WatchFace {
        id: watchFace
        anchors.centerIn: parent
        windowX: root.x
        windowY: root.y

        DragHandler {
            enabled: AppShell.mode !== "launcher" || !watchFace.launcherIconPressed
            onActiveChanged: if (active) root.startSystemMove()
        }
    }
}
