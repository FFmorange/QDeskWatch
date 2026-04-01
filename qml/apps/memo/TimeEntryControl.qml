import QtQuick

Item {
    id: root

    signal submitRequested()

    property real scale: 1
    property int hour: 0
    property int minute: 0

    readonly property bool invalid: _hourInvalid || _minInvalid
    readonly property bool isNextDay: !invalid && (hour * 60 + minute) < _nowMinutes
    readonly property int selectedField: _sel
    readonly property string dayHintText: invalid ? "\u65f6\u95f4\u65e0\u6548"
                                                  : (isNextDay ? "\u660e\u5929\u63d0\u9192" : "\u4eca\u5929\u63d0\u9192")

    property int _editStartHour: 0
    property int _editStartMin: 0
    property int _nowMinutes: currentMinutes()
    property int _sel: 0
    property string _hourBuf: ""
    property string _minBuf: ""
    property bool _hourInvalid: false
    property bool _minInvalid: false

    implicitWidth: contentCol.implicitWidth
    implicitHeight: contentCol.implicitHeight

    function setTime(h, m) {
        hour = h
        minute = m
        _editStartHour = h
        _editStartMin = m
        _nowMinutes = currentMinutes()
        _sel = 0
        _hourBuf = ""
        _minBuf = ""
        _hourInvalid = false
        _minInvalid = false
    }

    function pad2(v) {
        return (v < 10 ? "0" : "") + v
    }

    function currentMinutes() {
        var now = new Date()
        return now.getHours() * 60 + now.getMinutes()
    }

    function isFieldValid(field, text) {
        if (text.length === 0)
            return true
        var value = parseInt(text)
        if (field === 1) {
            if (text.length === 1) return value <= 2
            if (text.length === 2) return value <= 23
        } else if (field === 2) {
            if (text.length === 1) return value <= 5
            if (text.length === 2) return value <= 59
        }
        return false
    }

    function displayText(field) {
        var buf = field === 1 ? _hourBuf : _minBuf
        var value = field === 1 ? hour : minute
        return buf.length > 0 ? buf : pad2(value)
    }

    function finishField(field) {
        if (field === 1) {
            if (_hourInvalid)
                hour = _editStartHour
            _hourBuf = ""
            _hourInvalid = false
        } else if (field === 2) {
            if (_minInvalid)
                minute = _editStartMin
            _minBuf = ""
            _minInvalid = false
        }
    }

    function clearSelection() {
        if (_sel > 0)
            finishField(_sel)
        _sel = 0
    }

    function selectField(field) {
        if (_sel > 0 && _sel !== field)
            finishField(_sel)
        _sel = field
        if (field === 1) {
            _editStartHour = hour
            _hourBuf = ""
            _hourInvalid = false
        } else if (field === 2) {
            _editStartMin = minute
            _minBuf = ""
            _minInvalid = false
        }
        forceActiveFocus()
    }

    function stepField(field, delta) {
        if (_sel > 0 && _sel !== field)
            finishField(_sel)
        if (field === 1) {
            hour = (hour + delta + 24) % 24
            _hourBuf = ""
            _hourInvalid = false
            _editStartHour = hour
        } else if (field === 2) {
            minute = (minute + delta + 60) % 60
            _minBuf = ""
            _minInvalid = false
            _editStartMin = minute
        }
    }

    function moveSelection(field) {
        if (field !== 1 && field !== 2)
            return
        selectField(field)
    }

    function handleDigit(digit) {
        if (_sel === 0)
            return false

        var buf = _sel === 1 ? _hourBuf : _minBuf
        if (buf.length >= 2) {
            if (_sel === 1) {
                _editStartHour = hour
                _hourBuf = ""
                _hourInvalid = false
            } else {
                _editStartMin = minute
                _minBuf = ""
                _minInvalid = false
            }
            buf = ""
        }

        var nextBuf = buf + String(digit)
        var valid = isFieldValid(_sel, nextBuf)
        if (_sel === 1) {
            if (!valid) {
                _hourInvalid = true
                return false
            }
            _hourBuf = nextBuf
            _hourInvalid = false
            hour = parseInt(nextBuf)
            if (nextBuf.length === 2)
                selectField(2)
        } else {
            if (!valid) {
                _minInvalid = true
                return false
            }
            _minBuf = nextBuf
            _minInvalid = false
            minute = parseInt(nextBuf)
        }
        return true
    }

    Keys.onPressed: (event) => {
        var k = event.text
        if (k >= "0" && k <= "9" && root.selectedField > 0) {
            root.handleDigit(parseInt(k))
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Left) {
            root.moveSelection(1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Right) {
            root.moveSelection(2)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Up) {
            if (root.selectedField === 0)
                root.moveSelection(1)
            root.stepField(root.selectedField, 1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Down) {
            if (root.selectedField === 0)
                root.moveSelection(1)
            root.stepField(root.selectedField, -1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submitRequested()
            event.accepted = true
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root._nowMinutes = root.currentMinutes()
    }

    Column {
        id: contentCol
        anchors.centerIn: parent
        spacing: Math.round(3 * root.scale)

        Row {
            id: contentRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(6 * root.scale)

            Item {
                id: hourCol
                width: Math.round(16 * root.scale)
                height: hourNum.implicitHeight + Math.round(14 * root.scale)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    text: "\u25B2"
                    color: hourUpMa.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.3)
                    font.pixelSize: Math.round(4.5 * root.scale)
                    MouseArea {
                        id: hourUpMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.stepField(1, 1)
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width + Math.round(4 * root.scale)
                    height: hourNum.implicitHeight + Math.round(2 * root.scale)
                    radius: Math.round(3 * root.scale)
                    color: root._hourInvalid ? Qt.rgba(1, 0.15, 0.15, 0.18)
                                             : (root._sel === 1 ? Qt.rgba(0.3, 0.6, 1, 0.2) : Qt.rgba(1, 1, 1, 0.07))
                    border.color: root._hourInvalid ? "#FF5555"
                                                    : (root._sel === 1 ? Qt.rgba(0.3, 0.6, 1, 0.5) : "transparent")
                    border.width: 1

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectField(1)
                    }
                }

                Text {
                    id: hourNum
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.displayText(1)
                    color: root._sel === 1 ? "#66AAFF" : "white"
                    font.pixelSize: Math.round(10 * root.scale)
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: "\u25BC"
                    color: hourDownMa.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.3)
                    font.pixelSize: Math.round(4.5 * root.scale)
                    MouseArea {
                        id: hourDownMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.stepField(1, -1)
                    }
                }

                WheelHandler {
                    onWheel: (e) => {
                        root.stepField(1, e.angleDelta.y > 0 ? 1 : -1)
                        e.accepted = true
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ":"
                color: Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Math.round(10 * root.scale)
                font.bold: true
            }

            Item {
                id: minCol
                width: Math.round(16 * root.scale)
                height: hourCol.height

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    text: "\u25B2"
                    color: minUpMa.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.3)
                    font.pixelSize: Math.round(4.5 * root.scale)
                    MouseArea {
                        id: minUpMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.stepField(2, 1)
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width + Math.round(4 * root.scale)
                    height: minNum.implicitHeight + Math.round(2 * root.scale)
                    radius: Math.round(3 * root.scale)
                    color: root._minInvalid ? Qt.rgba(1, 0.15, 0.15, 0.18)
                                            : (root._sel === 2 ? Qt.rgba(0.3, 0.6, 1, 0.2) : Qt.rgba(1, 1, 1, 0.07))
                    border.color: root._minInvalid ? "#FF5555"
                                                   : (root._sel === 2 ? Qt.rgba(0.3, 0.6, 1, 0.5) : "transparent")
                    border.width: 1

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectField(2)
                    }
                }

                Text {
                    id: minNum
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.displayText(2)
                    color: root._sel === 2 ? "#66AAFF" : "white"
                    font.pixelSize: Math.round(10 * root.scale)
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: "\u25BC"
                    color: minDownMa.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.3)
                    font.pixelSize: Math.round(4.5 * root.scale)
                    MouseArea {
                        id: minDownMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.stepField(2, -1)
                    }
                }

                WheelHandler {
                    onWheel: (e) => {
                        root.stepField(2, e.angleDelta.y > 0 ? 5 : -5)
                        e.accepted = true
                    }
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: dayHintTextLabel.implicitWidth + Math.round(8 * root.scale)
            height: dayHintTextLabel.implicitHeight + Math.round(4 * root.scale)
            radius: Math.round(4 * root.scale)
            color: root.invalid ? Qt.rgba(1, 0.2, 0.2, 0.14)
                                : (root.isNextDay ? Qt.rgba(0.3, 0.6, 1, 0.16) : Qt.rgba(0.2, 1, 0.7, 0.12))
            border.color: root.invalid ? Qt.rgba(1, 0.35, 0.35, 0.35)
                                       : (root.isNextDay ? Qt.rgba(0.4, 0.7, 1, 0.35) : Qt.rgba(0.4, 1, 0.75, 0.28))
            border.width: 1

            Text {
                id: dayHintTextLabel
                anchors.centerIn: parent
                text: root.dayHintText
                color: root.invalid ? "#FF7777" : (root.isNextDay ? "#8FC8FF" : "#8FF0C8")
                font.pixelSize: Math.round(4.2 * root.scale)
                font.bold: true
            }
        }
    }
}
