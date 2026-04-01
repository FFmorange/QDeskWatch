import QtQuick

Item {
    id: root

    property string cityName: ""

    readonly property bool _hasCity: root.cityName.length > 0
    readonly property int _iconSize: Math.round(7.2 * PS.scale)
    readonly property int _iconGap: Math.round(1.4 * PS.scale)

    visible: root._hasCity
    implicitWidth: iconItem.width + root._iconGap + cityText.implicitWidth
    implicitHeight: Math.max(iconItem.height, cityText.implicitHeight)

    Image {
        id: iconItem
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: root._iconSize
        height: root._iconSize
        source: Theme.icon("location_ground_arrow_classic")
        sourceSize: Qt.size(Math.round(width * 3), Math.round(height * 3))
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        opacity: 0.96
    }

    Text {
        id: cityText
        anchors.left: iconItem.right
        anchors.leftMargin: root._iconGap
        anchors.verticalCenter: parent.verticalCenter
        text: root.cityName
        color: "#8FD3FF"
        opacity: 0.92
        font.pixelSize: Math.round(4.6 * PS.scale)
        font.bold: true
        font.letterSpacing: 0.3
    }
}
