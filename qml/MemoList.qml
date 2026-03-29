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

    // 取当前时间的分钟精度，与 memoTime 对齐
    function nowMinute() {
        var n = new Date()
        n.setSeconds(0, 0)
        return n.getTime()
    }

    // 每 10 秒删除过期条目，并驱动颜色和闪烁状态刷新
    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: {
            var now = root.nowMinute()
            var removed = false
            for (var i = memoModel.count - 1; i >= 0; i--) {
                if (memoModel.get(i).memoTime < now) {
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

    function hasDaySections(rev) {
        void rev
        for (var i = 0; i < memoModel.count; i++) {
            if (root.dayOffset(memoModel.get(i).memoTime) !== 0)
                return true
        }
        return false
    }

    function listRowsHeight(rev) {
        void rev
        var total = 0
        var showSections = root.hasDaySections(rev)
        var prevDay = -999
        for (var i = 0; i < memoModel.count; i++) {
            var day = root.dayOffset(memoModel.get(i).memoTime)
            if (showSections && day !== prevDay)
                total += root._sectionH
            total += root._rowH
            prevDay = day
        }
        return total
    }

    function sortByTime() {
        var arr = []
        for (var i = 0; i < memoModel.count; i++)
            arr.push({ memoTime: memoModel.get(i).memoTime, memoText: memoModel.get(i).memoText })
        arr.sort(function(a, b) { return a.memoTime - b.memoTime })
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
        root._sectionRev++
    }

    function memoEditValid() {
        return root._editMemoText.trim().length > 0
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
                var n = new Date()
                addPanel.openPanel(n.getHours(), n.getMinutes())
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

            // 空状态
            Text {
                visible: memoModel.count === 0
                width:   parent.width
                height:  listFlick.height
                text:    "暂无备忘"
                color:   Qt.rgba(1, 1, 1, 0.18)
                font.pixelSize: Math.round(4.5 * PS.scale)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
            }

            Repeater {
                model: memoModel
                delegate: Item {
                    id: memoRow

                    readonly property bool _blink: root.shouldBlink(model.memoTime, root._tick)
                    readonly property bool _showSections: root.hasDaySections(root._sectionRev)
                    readonly property int _day: root.dayOffset(model.memoTime)
                    readonly property int _prevDay: model.index > 0 ? root.dayOffset(memoModel.get(model.index - 1).memoTime) : -999
                    readonly property bool _showHeader: _showSections && (model.index === 0 || _day !== _prevDay)
                    readonly property bool _editing: root._editMemoIdx === model.index

                    width:  parent.width
                    height: _rowH + (_showHeader ? _sectionH : 0)

                    // 行级 hover 检测，不消耗事件
                    HoverHandler { id: rowHover }

                    Item {
                        id: headerItem
                        visible: memoRow._showHeader
                        width: parent.width
                        height: memoRow._showHeader ? root._sectionH : 0

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
                            color: memoRow._day === 0 ? Qt.rgba(0.32, 0.92, 0.72, 0.12)
                                                      : Qt.rgba(0.40, 0.67, 1.0, 0.13)
                            border.color: memoRow._day === 0 ? Qt.rgba(0.42, 0.95, 0.78, 0.22)
                                                             : Qt.rgba(0.55, 0.77, 1.0, 0.24)
                            border.width: 1

                            Text {
                                id: headerLabel
                                anchors.centerIn: parent
                                text: root.dayHeaderTitle(model.memoTime)
                                color: memoRow._day === 0 ? Qt.rgba(0.74, 1, 0.89, 0.92)
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
                            anchors.left:           parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width:  _timeW
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
                                color:          root.entryDisplayColor(model.memoTime, memoMa.containsMouse, root._tick)
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
                                enabled: !memoRow._editing
                                onEntered: {
                                    if (memoText.truncated) {
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
                            visible: rowHover.hovered && !memoRow._editing
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
                                    root.commitMemoEdit()
                                    root.removeMemo(model.index)
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
                sortByTime()
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

        width:  Math.round(86 * PS.scale)
        height: addPanelCol.implicitHeight + _margin * 2
        anchors.centerIn: parent

        function openPanel(h, m) {
            var next = m + (5 - m % 5)
            root.commitMemoEdit()
            addTime.setTime((h + Math.floor(next / 60)) % 24, next % 60)
            addContent.text = ""
            spinner.visible = false
            visible = true
            addContent.forceActiveFocus()
        }

        function doAdd() {
            var content = addContent.text.trim()
            if (content === "") return
            if (addTime.invalid) return
            addTime.clearSelection()
            var t = root.nextMemoDate(addTime.hour, addTime.minute)
            memoModel.append({ memoTime: t.getTime(), memoText: content })
            sortByTime()
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
                    onActiveFocusChanged: if (activeFocus) addTime.clearSelection()

                    Text {
                        anchors.fill:           parent
                        verticalAlignment:      Text.AlignVCenter
                        text:    "备忘内容..."
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
}
