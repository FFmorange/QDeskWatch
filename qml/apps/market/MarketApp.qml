import QtQuick

Item {
    id: root

    implicitWidth: Math.round(96 * PS.scale)
    implicitHeight: Math.round(66 * PS.scale)

    QtObject {
        id: copy

        readonly property string sseTitle: "上证指数"
        readonly property string goldTitle: "国内金价"
        readonly property string goldUnit: "元/克"
        readonly property string loading: "更新中..."
        readonly property string unavailable: "行情暂不可用"
        readonly property string updatedPrefix: "更新 "
    }

    function sseStatusText(statusKey) {
        switch (statusKey) {
        case "invalid":
            return "已失效"
        case "weekend_closed":
            return "休市"
        case "pre_open":
            return "未开盘"
        case "trading":
            return "交易中"
        case "lunch_break":
            return "午间休市"
        case "closed":
            return "收盘"
        default:
            return ""
        }
    }

    function goldStatusText(statusKey) {
        switch (statusKey) {
        case "invalid":
            return "已失效"
        case "delayed_quote":
            return "延时行情"
        case "daily_quote":
            return "日行情"
        default:
            return ""
        }
    }

    Component.onCompleted: $marketMgr.refresh()
    onVisibleChanged: if (visible) $marketMgr.refresh()

    Column {
        anchors.fill: parent
        spacing: Math.round(4 * PS.scale)

        MarketRow {
            width: parent.width
            title: copy.sseTitle
            subtitle: "000001"
            status: root.sseStatusText($marketMgr.sseStatus)
            updatedAt: $marketMgr.sseUpdatedAt
            unitText: ""
            value: $marketMgr.ssePrice
            change: $marketMgr.sseChange
            changePct: $marketMgr.sseChangePct
            available: $marketMgr.sseAvailable
            accentColor: "#8FD3FF"
        }

        MarketRow {
            width: parent.width
            title: copy.goldTitle
            subtitle: "AU9999"
            status: root.goldStatusText($marketMgr.goldStatus)
            updatedAt: $marketMgr.goldUpdatedAt
            unitText: copy.goldUnit
            value: $marketMgr.goldPrice
            change: $marketMgr.goldChange
            changePct: $marketMgr.goldChangePct
            available: $marketMgr.goldAvailable
            accentColor: "#F2C66C"
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(1 * PS.scale)
        text: $marketMgr.loading ? copy.loading
              : $marketMgr.errorMsg.length > 0 && !$marketMgr.sseAvailable && !$marketMgr.goldAvailable
                ? copy.unavailable
                : $marketMgr.lastUpdated.length > 0
                  ? copy.updatedPrefix + $marketMgr.lastUpdated
                  : ""
        color: Qt.rgba(1, 1, 1, 0.28)
        font.pixelSize: Math.round(3.2 * PS.scale)
    }
}
