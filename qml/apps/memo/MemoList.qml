import QtQuick

// 备忘录控件
// 每行包含：左侧时间、右侧备忘内容、悬停时显示的删除按钮
// 点击顶部加号弹出新增面板
Item {
    id: root

    readonly property real _pad:   Math.round(3 * PS.scale)
    readonly property real _rowH:  Math.round(15 * PS.scale)
    readonly property real _timeW: Math.round(22 * PS.scale)
    readonly property real _delW:  Math.round(10 * PS.scale)
    readonly property real _sectionH: Math.round(7 * PS.scale)

    implicitWidth:  Math.round(96 * PS.scale)
    implicitHeight: Math.round(66 * PS.scale)

    ListModel { id: memoModel }
    property int _sectionRev: 0
    property int _editMemoIdx: -1
    property string _editMemoText: ""
    property string _editMemoOrig: ""
    property var _editFieldItem: null
    property var _editCancelItem: null
    readonly property bool _tooltipBlocked: addChooser.opened || addPanel.visible || spinner.visible
    property bool _headerOverlayVisible: false
    property string _headerOverlayGroupKey: ""
    property string _headerOverlayText: ""
    property bool _headerOverlayIsNote: false
    property int _headerOverlayDay: -999
    property real _headerOverlayX: 0
    property real _headerOverlayY: 0
    property real _headerOverlayWidth: 0
    property real _headerOverlayHeight: 0

    // 用于驱动与时间相关的绑定刷新
    // Date.now() 不是可跟踪的 QML 属性，所以通过定时递增 _tick 来触发重算
    property int _tick: 0

    // 全局闪烁透明度，供 5 分钟内的条目使用
    property real _blinkOpacity: 1.0
    SequentialAnimation on _blinkOpacity {
        loops: Animation.Infinite
        NumberAnimation { to: 0.2; duration: 380; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 380; easing.type: Easing.InOutSine }
    }

    on_TooltipBlockedChanged: {
        if (_tooltipBlocked)
            ttip.hide()
    }

    function showHeaderOverlay(groupKey, title, isNote, day, item) {
        if (!item)
            return
        var p = item.mapToItem(root, 0, 0)
        root._headerOverlayGroupKey = groupKey
        root._headerOverlayText = title
        root._headerOverlayIsNote = isNote
        root._headerOverlayDay = day
        root._headerOverlayX = p.x
        root._headerOverlayY = p.y
        root._headerOverlayWidth = item.width
        root._headerOverlayHeight = item.height
        headerOverlayHideTimer.stop()
        root._headerOverlayVisible = true
    }

    function hideHeaderOverlay() {
        root._headerOverlayVisible = false
        root._headerOverlayGroupKey = ""
        root._headerOverlayText = ""
    }

    function hideHeaderOverlayLater() {
        if (root._headerOverlayVisible)
            headerOverlayHideTimer.restart()
    }

    // 取当前时间的分钟精度，与 memoTime 对齐
    function nowMinute() {
        var n = new Date()
        n.setSeconds(0, 0)
        return n.getTime()
    }

    function entryType(entry) {
        return entry && entry.entryType === "note" ? "note" : "scheduled"
    }

    function isNoteEntry(entry) {
        return root.entryType(entry) === "note"
    }

    // 每 10 秒删除过期条目，并驱动颜色和闪烁状态刷新
    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: {
            var now = root.nowMinute()
            var removed = false
            for (var i = memoModel.count - 1; i >= 0; i--) {
                var entry = memoModel.get(i)
                if (!root.isNoteEntry(entry) && entry.memoTime < now) {
                    memoModel.remove(i)
                    removed = true
                }
            }
            if (removed)
                root._sectionRev++
            root._tick++
        }
    }

    function urgencyColor(ms, tick) {
        void tick
        var diff = ms - root.nowMinute()
        if (diff <= 5  * 60 * 1000)  return "#FF3300"
        if (diff <= 15 * 60 * 1000)  return "#FF8800"
        if (diff <= 60 * 60 * 1000)  return "#FFCC00"
        return Qt.rgba(1, 1, 1, 0.7)
    }

    function shouldBlink(ms, tick) {
        void tick
        var diff = ms - root.nowMinute()
        return diff >= 0 && diff <= 5 * 60 * 1000
    }

    function urgencyBg(ms, tick) {
        void tick
        var diff = ms - Date.now()
        if (diff < 5  * 60 * 1000) return Qt.rgba(1, 0.2, 0, 0.15)
        if (diff < 15 * 60 * 1000) return Qt.rgba(1, 0.5, 0, 0.08)
        return "transparent"
    }

    function urgencyLevel(ms, tick) {
        void tick
        var diff = ms - root.nowMinute()
        if (diff <= 5  * 60 * 1000) return 3
        if (diff <= 15 * 60 * 1000) return 2
        if (diff <= 60 * 60 * 1000) return 1
        return 0
    }

    function entryDisplayColor(ms, hovered, tick) {
        var level = root.urgencyLevel(ms, tick)
        if (level === 3) return hovered ? "#FF8B70" : "#FF3300"
        if (level === 2) return hovered ? "#FFB266" : "#FF8800"
        if (level === 1) return hovered ? "#FFE47A" : "#FFCC00"
        return hovered ? Qt.rgba(1, 1, 1, 0.98) : Qt.rgba(1, 1, 1, 0.8)
    }

    function fmtTime(ms) {
        var d = new Date(ms)
        var h = d.getHours(), m = d.getMinutes()
        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
    }

    function dayOffset(ms) {
        var d = new Date(ms)
        var today = new Date()
        var startToday = new Date(today.getFullYear(), today.getMonth(), today.getDate())
        var startTarget = new Date(d.getFullYear(), d.getMonth(), d.getDate())
        return Math.round((startTarget.getTime() - startToday.getTime()) / (24 * 60 * 60 * 1000))
    }

    function dayHeaderTitle(ms) {
        var d = new Date(ms)
        var days = root.dayOffset(ms)
        if (days === 0) return "\u4eca\u5929"
        if (days === 1) return "\u660e\u5929"
        return (d.getMonth() + 1) + "/" + d.getDate()
    }

    function groupKeyForEntry(entry) {
        if (root.isNoteEntry(entry))
            return "note"
        return "day:" + root.dayOffset(entry.memoTime)
    }

    function hasGroupEntries(groupKey) {
        if (!groupKey)
            return false
        for (var i = 0; i < memoModel.count; i++) {
            if (root.groupKeyForEntry(memoModel.get(i)) === groupKey)
                return true
        }
        return false
    }

    function headerTitleForEntry(entry) {
        return root.isNoteEntry(entry) ? "\u5907\u5fd8\u5f55" : root.dayHeaderTitle(entry.memoTime)
    }

    function hasSectionHeaders(rev) {
        void rev
        return memoModel.count > 0
    }

    function listRowsHeight(rev) {
        void rev
        var total = 0
        var showSections = root.hasSectionHeaders(rev)
        var prevGroupKey = ""
        for (var i = 0; i < memoModel.count; i++) {
            var groupKey = root.groupKeyForEntry(memoModel.get(i))
            if (showSections && (i === 0 || groupKey !== prevGroupKey))
                total += root._sectionH
            total += root._rowH
            prevGroupKey = groupKey
        }
        return total
    }

    function sortEntries() {
        var arr = []
        for (var i = 0; i < memoModel.count; i++) {
            var entry = memoModel.get(i)
            arr.push({
                entryType: root.entryType(entry),
                memoTime: entry.memoTime !== undefined ? entry.memoTime : -1,
                memoText: entry.memoText,
                createdAt: entry.createdAt !== undefined ? entry.createdAt : 0
            })
        }
        arr.sort(function(a, b) {
            var aNote = a.entryType === "note"
            var bNote = b.entryType === "note"
            if (aNote !== bNote)
                return aNote ? -1 : 1
            if (aNote && bNote)
                return b.createdAt - a.createdAt
            if (a.memoTime !== b.memoTime)
                return a.memoTime - b.memoTime
            return a.createdAt - b.createdAt
        })
        memoModel.clear()
        for (var j = 0; j < arr.length; j++)
            memoModel.append(arr[j])
        root._sectionRev++
    }

    function removeMemo(idx) {
        if (idx < 0 || idx >= memoModel.count)
            return
        if (idx === root._editMemoIdx)
            root.cancelMemoEdit()
        else if (idx < root._editMemoIdx)
            root._editMemoIdx--
        memoModel.remove(idx)
        if (root._headerOverlayVisible && !root.hasGroupEntries(root._headerOverlayGroupKey))
            root.hideHeaderOverlay()
        root._sectionRev++
    }

    function memoEditValid() {
        return root._editMemoText.trim().length > 0
    }

    Timer {
        id: headerOverlayHideTimer
        interval: 240
        repeat: false
        onTriggered: root.hideHeaderOverlay()
    }

    function startMemoEdit(idx) {
        if (idx < 0 || idx >= memoModel.count)
            return
        if (root._editMemoIdx === idx)
            return
        root.cancelMemoEdit()
        root._editMemoOrig = memoModel.get(idx).memoText
        root._editMemoText = root._editMemoOrig
        root._editMemoIdx = idx
        ttip.hide()
        spinner.visible = false
        addPanel.visible = false
    }

    function cancelMemoEdit() {
        root._editMemoIdx = -1
        root._editMemoText = ""
        root._editMemoOrig = ""
        root._editFieldItem = null
        root._editCancelItem = null
    }

    function commitMemoEdit() {
        if (root._editMemoIdx < 0 || root._editMemoIdx >= memoModel.count) {
            root.cancelMemoEdit()
            return
        }
        var content = root._editMemoText.trim()
        if (content === "") {
            root.cancelMemoEdit()
            return
        }
        memoModel.setProperty(root._editMemoIdx, "memoText", content)
        root.cancelMemoEdit()
    }

    // 根据当前时间计算下一次触发的绝对时间
    function nextMemoDate(hour, minute) {
        var now = new Date()
        var target = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hour, minute, 0, 0)
        var nowHM = now.getHours() * 60 + now.getMinutes()
        var tgtHM = hour * 60 + minute
        if (tgtHM < nowHM)
            target.setDate(target.getDate() + 1)
        return target
    }

    function pointInItem(item, x, y, margin) {
        if (!item || !item.visible)
            return false
        var m = margin || 0
        var p = item.mapFromItem(root, x, y)
        return p.x >= -m && p.x <= item.width + m && p.y >= -m && p.y <= item.height + m
    }

    TapHandler {
        enabled: root._editMemoIdx >= 0
        onTapped: (eventPoint) => {
            if (root._editMemoIdx < 0)
                return
            var x = eventPoint.position.x
            var y = eventPoint.position.y
            if (root.pointInItem(root._editFieldItem, x, y, 0))
                return
            if (root.pointInItem(root._editCancelItem, x, y, Math.round(2 * PS.scale)))
                return
            root.commitMemoEdit()
        }
    }

    // 顶部新增按钮
    Rectangle {
        id: addBtn
        z: 100
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:              parent.top
        anchors.topMargin:        -Math.round(4 * PS.scale)
        width:  Math.round(10 * PS.scale)
        height: width
        radius: width / 2
        color:  "transparent"
        border.color: "transparent"
        border.width: 0

        Text {
            anchors.centerIn: parent
            text:  "+"
            color: addBtnMa.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.25)
            font.pixelSize: Math.round(7 * PS.scale)
            font.bold: true
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: addBtnMa
            anchors.fill:    parent
            anchors.margins: -Math.round(2 * PS.scale)
            hoverEnabled:    true
            cursorShape:     Qt.PointingHandCursor
            onClicked: {
                root.commitMemoEdit()
                spinner.visible = false
                addPanel.visible = false
                addChooser.toggle()
            }
        }
    }

    MouseArea {
        visible: addChooser.opened
        z: 149
        anchors.fill: parent
        onClicked: addChooser.close()
    }

    Item {
        id: addChooser
        z: 150
        anchors.horizontalCenter: addBtn.horizontalCenter
        y: opened ? addBtn.y + addBtn.height + Math.round(3 * PS.scale)
                  : addBtn.y + addBtn.height + Math.round(1 * PS.scale)
        width: Math.round(74 * PS.scale)
        height: opened ? chooserCard.implicitHeight : 0
        clip: true
        visible: opacity > 0 || height > 0
        opacity: opened ? 1.0 : 0.0
        scale: opened ? 1.0 : 0.94
        transformOrigin: Item.Top

        property bool opened: false

        function open() {
            opened = true
        }

        function close() {
            opened = false
        }

        function toggle() {
            opened = !opened
        }

        function choose(mode) {
            var n = new Date()
            close()
            addPanel.openPanel(mode, n.getHours(), n.getMinutes())
        }

        Behavior on opacity {
            NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
        }

        Behavior on height {
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: chooserCard
            width: parent.width
            height: implicitHeight
            implicitHeight: Math.round(34 * PS.scale)
            radius: Math.round(8 * PS.scale)
            color: Qt.rgba(0.08, 0.08, 0.08, 0.94)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.round(11 * PS.scale)
                radius: chooserCard.radius
                color: Qt.rgba(1, 1, 1, 0.035)
                opacity: 0.9
            }

            Row {
                anchors.centerIn: parent
                spacing: Math.round(7 * PS.scale)

                Item {
                    id: noteOption
                    width: Math.round(23 * PS.scale)
                    height: Math.round(24 * PS.scale)

                    readonly property bool hovered: noteOptionMa.containsMouse
                    readonly property bool pressed: noteOptionMa.pressed

                    Item {
                        id: noteMotion
                        width: Math.round(15 * PS.scale)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: noteOption.pressed ? Math.round(0.7 * PS.scale) : 0
                        scale: noteOption.pressed ? 0.9 : noteOption.hovered ? 1.1 : 0.96
                        opacity: noteOption.pressed ? 0.94 : noteOption.hovered ? 1.0 : 0.78

                        Behavior on y {
                            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                        }

                        Image {
                            anchors.fill: parent
                            source: Theme.icon("memo_note")
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            cache: true
                            sourceSize.width: Math.round(width * 4)
                            sourceSize.height: Math.round(height * 4)
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        text: "\u5907\u5fd8\u5f55"
                        color: "white"
                        opacity: 0.92
                        font.pixelSize: Math.round(3.7 * PS.scale)
                        font.bold: true
                    }

                    MouseArea {
                        id: noteOptionMa
                        anchors.fill: parent
                        anchors.margins: -Math.round(2 * PS.scale)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addChooser.choose("note")
                    }
                }

                Item {
                    width: 1
                    height: Math.round(24 * PS.scale)

                    Rectangle {
                        anchors.centerIn: parent
                        width: 1
                        height: Math.round(18 * PS.scale)
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }
                }

                Item {
                    id: timedOption
                    width: Math.round(23 * PS.scale)
                    height: Math.round(24 * PS.scale)

                    readonly property bool hovered: timedOptionMa.containsMouse
                    readonly property bool pressed: timedOptionMa.pressed

                    Item {
                        id: timedMotion
                        width: Math.round(15 * PS.scale)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: timedOption.pressed ? Math.round(0.7 * PS.scale) : 0
                        scale: timedOption.pressed ? 0.9 : timedOption.hovered ? 1.1 : 0.96
                        opacity: timedOption.pressed ? 0.94 : timedOption.hovered ? 1.0 : 0.78

                        Behavior on y {
                            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                        }

                        Image {
                            anchors.fill: parent
                            source: Theme.icon("memo_alarm")
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            cache: true
                            sourceSize.width: Math.round(width * 4)
                            sourceSize.height: Math.round(height * 4)
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        text: "\u5b9a\u65f6\u63d0\u9192"
                        color: "white"
                        opacity: 0.92
                        font.pixelSize: Math.round(3.4 * PS.scale)
                        font.bold: true
                    }

                    MouseArea {
                        id: timedOptionMa
                        anchors.fill: parent
                        anchors.margins: -Math.round(2 * PS.scale)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addChooser.choose("scheduled")
                    }
                }
            }

            Rectangle {
                width: Math.round(7 * PS.scale)
                height: Math.round(2 * PS.scale)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Math.round(3 * PS.scale)
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1
                border.color: "transparent"
            }
        }
    }

    // 列表区域
    Flickable {
        id: listFlick
        anchors {
            fill:        parent
            topMargin:   _pad
            leftMargin:  _pad
            rightMargin: _pad
            bottomMargin: _pad
        }
        clip:           true
        interactive:    false
        contentHeight:  memoCol.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: memoCol
            width:   parent.width
            spacing: 0

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            // 空状态
            Text {
                visible: memoModel.count === 0
                width:   parent.width
                height:  listFlick.height
                text:    "记下一件事吧"
                color:   Qt.rgba(1, 1, 1, 0.18)
                font.pixelSize: Math.round(4.5 * PS.scale)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
            }

            Repeater {
                model: memoModel
                delegate: Item {
                    id: memoRow

                    readonly property bool _isNote: root.isNoteEntry(model)
                    readonly property bool _blink: !memoRow._isNote && root.shouldBlink(model.memoTime, root._tick)
                    readonly property bool _showSections: root.hasSectionHeaders(root._sectionRev)
                    readonly property int _day: memoRow._isNote ? -999 : root.dayOffset(model.memoTime)
                    readonly property string _groupKey: root.groupKeyForEntry(model)
                    readonly property string _prevGroupKey: model.index > 0 ? root.groupKeyForEntry(memoModel.get(model.index - 1)) : ""
                    readonly property string _nextGroupKey: model.index < memoModel.count - 1 ? root.groupKeyForEntry(memoModel.get(model.index + 1)) : ""
                    readonly property bool _showHeader: _showSections && (model.index === 0 || _groupKey !== _prevGroupKey)
                    readonly property bool _preserveHeaderOnRemove: memoRow._showHeader && memoRow._nextGroupKey === memoRow._groupKey
                    readonly property bool _inlineHeaderSuppressed: root._headerOverlayVisible && memoRow._groupKey === root._headerOverlayGroupKey
                    readonly property bool _editing: root._editMemoIdx === model.index
                    readonly property real _fullHeight: root._rowH + (memoRow._showHeader ? root._sectionH : 0)
                    property real _animatedHeight: _fullHeight
                    property real _removeOffset: 0
                    property real _removeOpacity: 1.0
                    property bool _removing: false

                    width:  parent.width
                    height: _animatedHeight
                    clip: true

                    on_FullHeightChanged: {
                        if (!memoRow._removing)
                            memoRow._animatedHeight = memoRow._fullHeight
                    }

                    function startRemove() {
                        if (memoRow._removing)
                            return
                        memoRow._removing = true
                        root.commitMemoEdit()
                        ttip.hide()
                        if (memoRow._preserveHeaderOnRemove)
                            root.showHeaderOverlay(memoRow._groupKey, root.headerTitleForEntry(model), memoRow._isNote, memoRow._day, headerItem)
                        else
                            root.hideHeaderOverlay()
                        removeAnim.restart()
                    }

                    ParallelAnimation {
                        id: removeAnim

                        NumberAnimation {
                            target: memoRow
                            property: "_removeOffset"
                            to: Math.round(14 * PS.scale)
                            duration: 210
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            target: memoRow
                            property: "_removeOpacity"
                            to: 0.0
                            duration: 170
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            target: memoRow
                            property: "_animatedHeight"
                            to: memoRow._preserveHeaderOnRemove ? root._sectionH : 0
                            duration: 220
                            easing.type: Easing.InOutCubic
                        }

                        onStopped: {
                            if (memoRow._removing) {
                                root.removeMemo(model.index)
                                if (memoRow._preserveHeaderOnRemove)
                                    root.hideHeaderOverlayLater()
                            }
                        }
                    }

                    // 行级 hover 检测，不消耗事件
                    HoverHandler {
                        id: rowHover
                        enabled: !memoRow._removing
                    }

                    Item {
                        id: headerItem
                        visible: memoRow._showHeader && !memoRow._inlineHeaderSuppressed
                        width: parent.width
                        height: memoRow._showHeader ? root._sectionH : 0
                        opacity: memoRow._preserveHeaderOnRemove ? 1.0 : memoRow._removeOpacity
                        transform: Translate {
                            x: memoRow._preserveHeaderOnRemove ? 0 : memoRow._removeOffset
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            width: Math.max(0, (parent.width - headerLabel.implicitWidth - Math.round(10 * PS.scale)) / 2)
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.08)
                        }

                        Rectangle {
                            id: headerChip
                            anchors.centerIn: parent
                            width: headerLabel.implicitWidth + Math.round(8 * PS.scale)
                            height: Math.max(Math.round(5 * PS.scale), headerLabel.implicitHeight + Math.round(1 * PS.scale))
                            radius: height / 2
                            color: memoRow._isNote ? Qt.rgba(1, 1, 1, 0.08)
                                                   : memoRow._day === 0 ? Qt.rgba(0.32, 0.92, 0.72, 0.12)
                                                      : Qt.rgba(0.40, 0.67, 1.0, 0.13)
                            border.color: memoRow._isNote ? Qt.rgba(1, 1, 1, 0.16)
                                                          : memoRow._day === 0 ? Qt.rgba(0.42, 0.95, 0.78, 0.22)
                                                              : Qt.rgba(0.55, 0.77, 1.0, 0.24)
                            border.width: 1

                            Text {
                                id: headerLabel
                                anchors.centerIn: parent
                                text: root.headerTitleForEntry(model)
                                color: memoRow._isNote ? Qt.rgba(1, 1, 1, 0.88)
                                                       : memoRow._day === 0 ? Qt.rgba(0.74, 1, 0.89, 0.92)
                                                          : Qt.rgba(0.78, 0.88, 1, 0.92)
                                font.pixelSize: Math.round(3.6 * PS.scale)
                                font.bold: true
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            width: Math.max(0, (parent.width - headerLabel.implicitWidth - Math.round(10 * PS.scale)) / 2)
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.08)
                        }
                    }

                    Item {
                        id: rowBody
                        y: memoRow._showHeader ? root._sectionH : 0
                        width: parent.width
                        height: root._rowH
                        opacity: memoRow._removeOpacity
                        transform: Translate { x: memoRow._removeOffset }

                        // 分隔线
                        Rectangle {
                            visible: model.index > 0 && !memoRow._showHeader
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: 1
                            color:  Qt.rgba(1, 1, 1, 0.06)
                        }

                        // 时间，点击后弹出编辑面板
                        Item {
                            id: timeItem
                            visible: !memoRow._isNote
                            anchors.left:           parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width:  memoRow._isNote ? 0 : _timeW
                            height: parent.height

                            Text {
                                id: timeText
                                anchors.centerIn: parent
                                text:           root.fmtTime(model.memoTime)
                                color:          root.entryDisplayColor(model.memoTime, timeMa.containsMouse, root._tick)
                                opacity:        memoRow._blink ? root._blinkOpacity : 1.0
                                font.pixelSize: Math.round(5.8 * PS.scale)
                                font.bold:      true
                            }

                            MouseArea {
                                id: timeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !memoRow._isNote && !memoRow._removing
                                onClicked: {
                                    root.commitMemoEdit()
                                    var d = new Date(model.memoTime)
                                    spinner.openFor(model.index, d.getHours(), d.getMinutes())
                                }
                            }
                        }

                        // 备忘文字
                        Item {
                            id: memoItem
                            anchors {
                                left:           timeItem.right
                                right:          parent.right
                                rightMargin:    memoRow._editing ? Math.round(10 * PS.scale)
                                                                 : (rowHover.hovered ? _delW : Math.round(2 * PS.scale))
                                top:            parent.top
                                bottom:         parent.bottom
                            }

                            Text {
                                id: memoText
                                visible: !memoRow._editing
                                anchors {
                                    left:           parent.left
                                    right:          parent.right
                                    leftMargin:     Math.round(2 * PS.scale)
                                    rightMargin:    Math.round(2 * PS.scale)
                                    verticalCenter: parent.verticalCenter
                                }
                                text:           model.memoText
                                color:          memoRow._isNote
                                                ? (memoMa.containsMouse ? Qt.rgba(1, 1, 1, 0.98) : Qt.rgba(1, 1, 1, 0.82))
                                                : root.entryDisplayColor(model.memoTime, memoMa.containsMouse, root._tick)
                                opacity:        memoRow._blink ? root._blinkOpacity : 1.0
                                font.pixelSize: Math.round(5.5 * PS.scale)
                                font.bold:      true
                                elide:          Text.ElideRight
                                clip:           true
                            }

                            Rectangle {
                                visible: memoRow._editing
                                anchors.fill: parent
                                anchors.margins: Math.round(1 * PS.scale)
                                radius: Math.round(4 * PS.scale)
                                color: Qt.rgba(1, 1, 1, 0.08)
                                border.color: root.memoEditValid() ? Qt.rgba(1, 1, 1, 0.55)
                                                                    : Qt.rgba(1, 0.35, 0.35, 0.7)
                                border.width: 1
                            }

                            TextInput {
                                id: memoEditInput
                                visible: memoRow._editing
                                anchors {
                                    left:           parent.left
                                    right:          parent.right
                                    leftMargin:     Math.round(4 * PS.scale)
                                    rightMargin:    Math.round(2 * PS.scale)
                                    verticalCenter: parent.verticalCenter
                                }
                                text: ""
                                color: "white"
                                font.pixelSize: Math.round(5.5 * PS.scale)
                                font.bold: true
                                clip: true
                                selectByMouse: true
                                maximumLength: 30
                                selectionColor: Qt.rgba(0.35, 0.62, 1, 0.35)
                                selectedTextColor: "white"

                                onTextEdited: root._editMemoText = text
                                onActiveFocusChanged: {
                                    if (activeFocus)
                                        selectAll()
                                }
                                Keys.onReturnPressed: root.commitMemoEdit()
                                Keys.onEnterPressed: root.commitMemoEdit()
                                Keys.onEscapePressed: root.cancelMemoEdit()
                                Component.onCompleted: if (visible) forceActiveFocus()
                                onVisibleChanged: {
                                    if (visible) {
                                        root._editFieldItem = memoItem
                                        root._editCancelItem = editActions
                                        text = root._editMemoOrig
                                        root._editMemoText = text
                                        forceActiveFocus()
                                        selectAll()
                                    } else if (root._editFieldItem === memoItem) {
                                        root._editFieldItem = null
                                        root._editCancelItem = null
                                    }
                                }
                            }

                            MouseArea {
                                id: memoMa
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !memoRow._editing && !memoRow._removing && !root._tooltipBlocked
                                onEntered: {
                                    if (!root._tooltipBlocked && memoText.truncated) {
                                        var pos = memoText.mapToItem(root, 0, memoText.height + Math.round(2 * PS.scale))
                                        ttip.show(model.memoText, pos.x, pos.y)
                                    }
                                }
                                onExited: ttip.hide()
                                onDoubleClicked: root.startMemoEdit(model.index)
                            }
                        }

                        Item {
                            id: editActions
                            visible: memoRow._editing
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            width: Math.round(7 * PS.scale)
                            height: parent.height

                            Text {
                                id: memoCancelBtn
                                anchors.centerIn: parent
                                width: Math.round(7 * PS.scale)
                                text: "\u00D7"
                                horizontalAlignment: Text.AlignHCenter
                                color: memoCancelMa.containsMouse ? "#FF7777" : Qt.rgba(1, 1, 1, 0.45)
                                font.pixelSize: Math.round(5.8 * PS.scale)

                                MouseArea {
                                    id: memoCancelMa
                                    anchors.fill: parent
                                    anchors.margins: -Math.round(1 * PS.scale)
                                    hoverEnabled: true
                                    onClicked: root.cancelMemoEdit()
                                }
                            }
                        }

                        // 删除按钮，仅在 hover 时显示
                        Text {
                            id: delBtn
                            visible: rowHover.hovered && !memoRow._editing && !memoRow._removing
                            anchors {
                                right:          parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            width:          _delW
                            text:           "×"
                            horizontalAlignment: Text.AlignHCenter
                            color:          delMa.containsMouse ? "#FF5555" : Qt.rgba(1, 1, 1, 0.35)
                            font.pixelSize: Math.round(6 * PS.scale)

                            MouseArea {
                                id: delMa
                                anchors.fill:    parent
                                anchors.margins: -Math.round(1 * PS.scale)
                                hoverEnabled:    true
                                onClicked: {
                                    memoRow.startRemove()
                                }
                            }
                        }
                    }
                }
            }

            // 底部补白
            Item {
                width:  parent.width
                height: Math.max(0, listFlick.height - root.listRowsHeight(root._sectionRev))
            }
        }

        WheelHandler {
            enabled: memoModel.count > 0
            onWheel: (event) => {
                var d = -event.angleDelta.y / 3
                listFlick.contentY = Math.max(0,
                    Math.min(listFlick.contentHeight - listFlick.height,
                             listFlick.contentY + d))
                event.accepted = true
                scrollBar.show()
            }
        }
    }

    // 滚动条，仅滚动时显示
    Rectangle {
        id: scrollBar
        visible: false
        z: 50
        anchors.right:       parent.right
        anchors.rightMargin: Math.round(1 * PS.scale)
        width:  Math.round(2 * PS.scale)
        radius: width / 2
        color:  Qt.rgba(1, 1, 1, 0.3)

        readonly property real _viewRatio: listFlick.height / listFlick.contentHeight
        readonly property real _trackH:    listFlick.height
        y:      _pad + (listFlick.contentY / listFlick.contentHeight) * _trackH
        height: Math.max(Math.round(6 * PS.scale), _viewRatio * _trackH)

        function show() {
            visible = listFlick.contentHeight > listFlick.height
            scrollHideTimer.restart()
        }

        Timer {
            id: scrollHideTimer
            interval: 800
            onTriggered: scrollBar.visible = false
        }
    }

    // 时间编辑弹窗
    Item {
        id: spinner
        visible: false
        z:       200

        readonly property real _margin: Math.round(5 * PS.scale)
        property int _idx:  -1
        property int _origHour: 0
        property int _origMin:  0

        width:  Math.round(78 * PS.scale)
        height: spinnerCol.implicitHeight + _margin * 2
        anchors.centerIn: parent

        function openFor(idx, h, m) {
            _idx  = idx
            _origHour = h
            _origMin = m
            root.commitMemoEdit()
            spinnerTime.setTime(h, m)
            addChooser.close()
            addPanel.visible = false
            visible = true
        }

        function cancel() {
            spinnerTime.setTime(_origHour, _origMin)
            visible = false
        }

        function commit() {
            if (spinnerTime.invalid)
                return
            spinnerTime.clearSelection()
            if (_idx >= 0 && _idx < memoModel.count) {
                var d = root.nextMemoDate(spinnerTime.hour, spinnerTime.minute)
                memoModel.setProperty(_idx, "memoTime", d.getTime())
                sortEntries()
            }
            visible = false
        }

        MouseArea {
            width: 10000; height: 10000; x: -5000; y: -5000; z: -1
            onClicked: (mouse) => {
                var px = mouse.x + (-5000)
                var py = mouse.y + (-5000)
                if (px < 0 || px > spinner.width || py < 0 || py > spinner.height)
                    spinner.cancel()
            }
        }

        Rectangle {
            anchors.fill: parent
            color:        Qt.rgba(0.08, 0.08, 0.08, 0.93)
            radius:       Math.round(8 * PS.scale)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
        }

        Column {
            id: spinnerCol
            anchors.centerIn: parent
            width: parent.width - spinner._margin * 2
            spacing: Math.round(4 * PS.scale)

            TimeEntryControl {
                id: spinnerTime
                anchors.horizontalCenter: parent.horizontalCenter
                scale: PS.scale
                onSubmitRequested: spinner.commit()
            }

            Rectangle {
                id: spinnerOkBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width:  Math.round(10 * PS.scale)
                height: Math.round(9 * PS.scale)
                radius: Math.round(3 * PS.scale)
                color:  spinnerOkMa.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                border.color: spinnerOkMa.containsMouse ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.15)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text:  "OK"
                    color: "white"
                    font.pixelSize: Math.round(4 * PS.scale)
                    font.bold: true
                }

                MouseArea {
                    id: spinnerOkMa
                    anchors.fill: parent
                    anchors.margins: -Math.round(2 * PS.scale)
                    hoverEnabled: true
                    onClicked: spinner.commit()
                }
            }
        }
    }

    // 新增面板
    Item {
        id: addPanel
        visible: false
        z:       200

        readonly property real _margin: Math.round(6 * PS.scale)
        property string entryType: "scheduled"
        readonly property bool noteMode: entryType === "note"

        width:  Math.round(86 * PS.scale)
        height: addPanelCol.implicitHeight + _margin * 2
        anchors.centerIn: parent

        function openPanel(mode, h, m) {
            root.commitMemoEdit()
            entryType = mode || "scheduled"
            if (!noteMode) {
                var next = m + (5 - m % 5)
                addTime.setTime((h + Math.floor(next / 60)) % 24, next % 60)
            } else {
                addTime.clearSelection()
            }
            addContent.text = ""
            addChooser.close()
            spinner.visible = false
            visible = true
            addContent.forceActiveFocus()
        }

        function doAdd() {
            var content = addContent.text.trim()
            if (content === "") return
            var createdAt = Date.now()
            if (noteMode) {
                memoModel.append({
                    entryType: "note",
                    memoTime: -1,
                    memoText: content,
                    createdAt: createdAt
                })
            } else {
                if (addTime.invalid) return
                addTime.clearSelection()
                var t = root.nextMemoDate(addTime.hour, addTime.minute)
                memoModel.append({
                    entryType: "scheduled",
                    memoTime: t.getTime(),
                    memoText: content,
                    createdAt: createdAt
                })
            }
            sortEntries()
            addContent.focus = false
            visible = false
        }

        MouseArea {
            width: 10000; height: 10000; x: -5000; y: -5000; z: -1
            onClicked: (mouse) => {
                var px = mouse.x + (-5000)  // 将 MouseArea 本地坐标换算到 addPanel 坐标
                var py = mouse.y + (-5000)
                if (px < 0 || px > addPanel.width || py < 0 || py > addPanel.height) {
                    addContent.focus = false
                    addPanel.visible = false
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color:        Qt.rgba(0.08, 0.08, 0.08, 0.93)
            radius:       Math.round(8 * PS.scale)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
        }

        Column {
            id: addPanelCol
            anchors.centerIn: parent
            width: parent.width - addPanel._margin * 2
            spacing: Math.round(5 * PS.scale)

            // 内容输入框和确认按钮
            Rectangle {
                width:  parent.width
                height: Math.round(13 * PS.scale)
                color:  Qt.rgba(1, 1, 1, 0.06)
                radius: Math.round(4 * PS.scale)
                border.color: addContent.activeFocus ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.12)
                border.width: 1

                TextInput {
                    id: addContent
                    anchors {
                        left:           parent.left
                        right:          confirmTick.left
                        top:            parent.top
                        bottom:         parent.bottom
                        leftMargin:     Math.round(4 * PS.scale)
                        rightMargin:    Math.round(2 * PS.scale)
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    clip:           true
                    color:          "white"
                    font.pixelSize: Math.round(5 * PS.scale)
                    maximumLength:  30
                    selectByMouse:  true
                    Keys.onReturnPressed: { if (addPanel.visible) addPanel.doAdd() }
                    Keys.onEnterPressed: { if (addPanel.visible) addPanel.doAdd() }
                    onActiveFocusChanged: if (activeFocus && !addPanel.noteMode) addTime.clearSelection()

                    Text {
                        anchors.fill:           parent
                        verticalAlignment:      Text.AlignVCenter
                        text:    addPanel.noteMode ? "备忘内容..." : "提醒内容..."
                        color:   Qt.rgba(1, 1, 1, 0.2)
                        font:    addContent.font
                        visible: addContent.text.length === 0 && !addContent.activeFocus
                    }
                }

                // 确认按钮
                Rectangle {
                    id: confirmTick
                    anchors {
                        right:          parent.right
                        rightMargin:    Math.round(2 * PS.scale)
                        verticalCenter: parent.verticalCenter
                    }
                    width:  Math.round(10 * PS.scale)
                    height: Math.round(9 * PS.scale)
                    radius: Math.round(3 * PS.scale)
                    color:  tickMa.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                    border.color: tickMa.containsMouse ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text:  "OK"
                        color: tickMa.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: Math.round(4 * PS.scale)
                        font.bold: true
                    }

                    MouseArea {
                        id: tickMa
                        anchors.fill:    parent
                        anchors.margins: -Math.round(2 * PS.scale)
                        hoverEnabled:    true
                        onClicked:       addPanel.doAdd()
                    }
                }
            }

            TimeEntryControl {
                id: addTime
                visible: !addPanel.noteMode
                anchors.horizontalCenter: parent.horizontalCenter
                scale: PS.scale
                onSubmitRequested: addPanel.doAdd()
            }

        }
    }

    // 提示气泡
    Rectangle {
        id: ttip
        visible: false
        z:       400

        width:  ttipText.implicitWidth + Math.round(8 * PS.scale)
        height: ttipText.implicitHeight + Math.round(5 * PS.scale)
        color:  Qt.rgba(0.08, 0.08, 0.08, 0.93)
        radius: Math.round(4 * PS.scale)
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1

        function show(text, px, py) {
            ttipText.text = text
            x = Math.max(0, Math.min(root.width - width, px))
            y = Math.max(0, Math.min(root.height - height, py))
            visible = true
        }
        function hide() { visible = false }

        Text {
            id: ttipText
            anchors.centerIn: parent
            color:          Qt.rgba(1, 1, 1, 0.9)
            font.pixelSize: Math.round(4.5 * PS.scale)
        }
    }

    Item {
        visible: root._headerOverlayVisible
        z: 380
        x: root._headerOverlayX
        y: root._headerOverlayY
        width: root._headerOverlayWidth
        height: root._headerOverlayHeight

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            width: Math.max(0, (parent.width - overlayHeaderLabel.implicitWidth - Math.round(10 * PS.scale)) / 2)
            height: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        Rectangle {
            anchors.centerIn: parent
            width: overlayHeaderLabel.implicitWidth + Math.round(8 * PS.scale)
            height: Math.max(Math.round(5 * PS.scale), overlayHeaderLabel.implicitHeight + Math.round(1 * PS.scale))
            radius: height / 2
            color: root._headerOverlayIsNote ? Qt.rgba(1, 1, 1, 0.08)
                                             : root._headerOverlayDay === 0 ? Qt.rgba(0.32, 0.92, 0.72, 0.12)
                                                 : Qt.rgba(0.40, 0.67, 1.0, 0.13)
            border.color: root._headerOverlayIsNote ? Qt.rgba(1, 1, 1, 0.16)
                                                    : root._headerOverlayDay === 0 ? Qt.rgba(0.42, 0.95, 0.78, 0.22)
                                                        : Qt.rgba(0.55, 0.77, 1.0, 0.24)
            border.width: 1

            Text {
                id: overlayHeaderLabel
                anchors.centerIn: parent
                text: root._headerOverlayText
                color: root._headerOverlayIsNote ? Qt.rgba(1, 1, 1, 0.88)
                                                 : root._headerOverlayDay === 0 ? Qt.rgba(0.74, 1, 0.89, 0.92)
                                                     : Qt.rgba(0.78, 0.88, 1, 0.92)
                font.pixelSize: Math.round(3.6 * PS.scale)
                font.bold: true
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            width: Math.max(0, (parent.width - overlayHeaderLabel.implicitWidth - Math.round(10 * PS.scale)) / 2)
            height: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }
    }
}
