import QtQuick

Item {
    id: root

    implicitWidth: Math.round(96 * PS.scale)
    implicitHeight: Math.round(66 * PS.scale)

    property string detailKey: ""
    readonly property bool showingDetail: root.detailKey.length > 0

    QtObject {
        id: copy

        readonly property string sseTitle: "上证指数"
        readonly property string goldTitle: "国内金价"
        readonly property string goldUnit: "元/克"
        readonly property string loading: "更新中..."
        readonly property string unavailable: "行情暂不可用"
        readonly property string updatedPrefix: "更新 "
    }

    function openDetail(assetKey) {
        root.detailKey = assetKey
    }

    function closeDetail() {
        root.detailKey = ""
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

    Item {
        anchors.fill: parent
        visible: !root.showingDetail
        opacity: root.showingDetail ? 0.0 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
        }

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
                interactive: true
                onClicked: root.openDetail("sse")
            }

            MarketRow {
                width: parent.width
                title: copy.goldTitle
                subtitle: "Au99.99"
                status: root.goldStatusText($marketMgr.goldStatus)
                updatedAt: $marketMgr.goldUpdatedAt
                unitText: copy.goldUnit
                value: $marketMgr.goldPrice
                change: $marketMgr.goldChange
                changePct: $marketMgr.goldChangePct
                available: $marketMgr.goldAvailable
                accentColor: "#F2C66C"
                interactive: true
                onClicked: root.openDetail("gold")
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(1 * PS.scale)
            text: $marketMgr.loading
                  ? copy.loading
                  : $marketMgr.errorMsg.length > 0 && !$marketMgr.sseAvailable && !$marketMgr.goldAvailable
                    ? copy.unavailable
                    : $marketMgr.lastUpdated.length > 0
                      ? copy.updatedPrefix + $marketMgr.lastUpdated
                      : ""
            color: Qt.rgba(1, 1, 1, 0.28)
            font.pixelSize: Math.round(3.2 * PS.scale)
        }
    }

    MarketDetailView {
        anchors.fill: parent
        visible: root.showingDetail
        opacity: root.showingDetail ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
        }

        title: root.detailKey === "gold" ? copy.goldTitle : copy.sseTitle
        subtitle: root.detailKey === "gold" ? "Au99.99" : "000001"
        status: root.detailKey === "gold"
                ? root.goldStatusText($marketMgr.goldStatus)
                : root.sseStatusText($marketMgr.sseStatus)
        unitText: root.detailKey === "gold" ? copy.goldUnit : ""
        updatedAt: root.detailKey === "gold" ? $marketMgr.goldUpdatedAt : $marketMgr.sseUpdatedAt
        chartUpdatedAt: root.detailKey === "gold" ? $marketMgr.goldChartUpdatedAt : $marketMgr.sseChartUpdatedAt
        price: root.detailKey === "gold" ? $marketMgr.goldPrice : $marketMgr.ssePrice
        change: root.detailKey === "gold" ? $marketMgr.goldChange : $marketMgr.sseChange
        changePct: root.detailKey === "gold" ? $marketMgr.goldChangePct : $marketMgr.sseChangePct
        available: root.detailKey === "gold" ? $marketMgr.goldAvailable : $marketMgr.sseAvailable
        chartAvailable: root.detailKey === "gold" ? $marketMgr.goldChartAvailable : $marketMgr.sseChartAvailable
        chartLoading: $marketMgr.loading
                      && !(root.detailKey === "gold" ? $marketMgr.goldChartAvailable : $marketMgr.sseChartAvailable)
        chartPoints: root.detailKey === "gold" ? $marketMgr.goldChartPoints : $marketMgr.sseChartPoints
        accentColor: root.detailKey === "gold" ? "#F2C66C" : "#8FD3FF"

        onBackRequested: root.closeDetail()
    }
}