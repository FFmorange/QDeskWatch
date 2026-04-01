import QtQuick
import "../common"

Item {
    id: root

    property bool flipEnabled: true

    readonly property real timeRowCenterY: timeRow.y + timeRow.height / 2

    function dateString(date) {
        var weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return date.getDate() + " " + weekdays[date.getDay()]
    }

    implicitWidth: Math.max(timeRow.implicitWidth, dateText.implicitWidth)
    implicitHeight: dateText.height + Math.round(1 * PS.scale) + timeRow.implicitHeight

    // 日期
    Text {
        id: dateText
        anchors.top: parent.top
        anchors.topMargin: Math.round(5 * PS.scale)
        anchors.right: parent.right
        anchors.rightMargin: Math.round(5 * PS.scale)
        text: root.dateString(new Date())
        color: "#ed7676"
        font.bold: true
        font.pixelSize: Math.round(5 * PS.scale)
    }

    FontMetrics {
        id: fm
        font.pixelSize: Math.round(12 * PS.scale)
        font.bold: true
    }

    // 时间
    Item {
        id: timeRow
        anchors.top: dateText.bottom
        anchors.topMargin: Math.round(1 * PS.scale)
        anchors.right: parent.right
        anchors.rightMargin: Math.round(5 * PS.scale)
        implicitWidth: hourText.implicitWidth + colonText.implicitWidth
                       + minText.implicitWidth + Math.round(2 * PS.scale)
                       + secTens.implicitWidth + secUnits.implicitWidth
        implicitHeight: hourText.implicitHeight

        Text {
            id: hourText
            anchors.right: colonText.left
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(new Date(), "hh")
            color: "white"
            font.pixelSize: Math.round(12 * PS.scale)
            font.bold: true
        }

        Text {
            id: colonText
            anchors.right: minText.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -fm.descent / 2
            text: ":"
            color: "white"
            font.pixelSize: Math.round(12 * PS.scale)
            font.bold: true

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.1; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
            }
        }

        Text {
            id: minText
            anchors.right: secTens.left
            anchors.rightMargin: Math.round(2 * PS.scale)
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(new Date(), "mm")
            color: "white"
            font.pixelSize: Math.round(12 * PS.scale)
            font.bold: true
        }

        FlipText {
            id: secTens
            anchors.right: secUnits.left
            anchors.bottom: parent.bottom
            text: Qt.formatTime(new Date(), "ss")[0]
            flipEnabled: root.flipEnabled
            textColor: "white"
            pixelSize: Math.round(7 * PS.scale)
            bold: true
        }

        FlipText {
            id: secUnits
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: Qt.formatTime(new Date(), "ss")[1]
            flipEnabled: root.flipEnabled
            textColor: "white"
            pixelSize: Math.round(7 * PS.scale)
            bold: true
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            var ss = Qt.formatTime(now, "ss")
            hourText.text = Qt.formatTime(now, "hh")
            minText.text = Qt.formatTime(now, "mm")
            secTens.text = ss[0]
            secUnits.text = ss[1]
            dateText.text = root.dateString(now)
        }
    }
}
