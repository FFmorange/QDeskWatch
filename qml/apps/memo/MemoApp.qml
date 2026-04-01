import QtQuick

Item {
    id: root

    implicitWidth: Math.round(96 * PS.scale)
    implicitHeight: Math.round(66 * PS.scale)

    MemoList {
        anchors.fill: parent
    }
}
