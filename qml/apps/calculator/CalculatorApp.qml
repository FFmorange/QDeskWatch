import QtQuick

FocusScope {
    id: root

    implicitWidth: Math.round(96 * PS.scale)
    implicitHeight: Math.round(66 * PS.scale)
    focus: visible

    readonly property real _pad: Math.round(2 * PS.scale)
    readonly property real _gap: Math.max(1, Math.round(1.2 * PS.scale))
    readonly property real _displayH: Math.round(13 * PS.scale)
    readonly property real _contentW: width - root._pad * 2
    readonly property real _buttonW: Math.floor((root._contentW - root._gap * 3) / 4)
    readonly property real _wideButtonW: root._buttonW * 2 + root._gap
    readonly property real _buttonH: Math.floor((height - root._pad * 2 - root._displayH - root._gap * 5) / 5)

    property string displayText: "0"
    property string expressionText: ""
    property double memoryValue: 0.0
    property string pendingOperator: ""
    property bool clearOnNextInput: false
    property bool errorState: false

    function formatNumber(value) {
        if (!isFinite(value))
            return "Error"

        var normalized = Number(value.toPrecision(12))
        return normalized.toString()
    }

    function setError(message) {
        root.displayText = "Error"
        root.expressionText = message || "计算错误"
        root.pendingOperator = ""
        root.memoryValue = 0.0
        root.clearOnNextInput = true
        root.errorState = true
    }

    function clearAll() {
        root.displayText = "0"
        root.expressionText = ""
        root.memoryValue = 0.0
        root.pendingOperator = ""
        root.clearOnNextInput = false
        root.errorState = false
    }

    function backspace() {
        if (root.errorState) {
            root.clearAll()
            return
        }

        if (root.clearOnNextInput)
            return

        if (root.displayText.length <= 1 || (root.displayText.length === 2 && root.displayText[0] === "-")) {
            root.displayText = "0"
            return
        }

        root.displayText = root.displayText.slice(0, -1)
    }

    function inputDigit(digit) {
        if (root.errorState)
            root.clearAll()

        if (root.clearOnNextInput) {
            root.displayText = digit
            root.clearOnNextInput = false
            return
        }

        if (root.displayText === "0")
            root.displayText = digit
        else if (root.displayText === "-0")
            root.displayText = "-" + digit
        else if (root.displayText.length < 14)
            root.displayText += digit
    }

    function inputDot() {
        if (root.errorState)
            root.clearAll()

        if (root.clearOnNextInput) {
            root.displayText = "0."
            root.clearOnNextInput = false
            return
        }

        if (root.displayText.indexOf(".") === -1)
            root.displayText += "."
    }

    function toggleSign() {
        if (root.errorState) {
            root.clearAll()
            return
        }

        if (root.clearOnNextInput) {
            root.displayText = "-0"
            root.clearOnNextInput = false
            return
        }

        if (root.displayText === "0")
            return

        root.displayText = root.displayText[0] === "-"
                ? root.displayText.slice(1)
                : "-" + root.displayText
    }

    function runOperation(lhs, rhs, op) {
        switch (op) {
        case "+":
            return { ok: true, value: lhs + rhs }
        case "-":
            return { ok: true, value: lhs - rhs }
        case "×":
            return { ok: true, value: lhs * rhs }
        case "÷":
            if (Math.abs(rhs) < 1e-12)
                return { ok: false, message: "除数不能为 0" }
            return { ok: true, value: lhs / rhs }
        default:
            return { ok: true, value: rhs }
        }
    }

    function inputOperator(op) {
        if (root.errorState)
            return

        if (root.pendingOperator !== "" && !root.clearOnNextInput) {
            var result = root.runOperation(root.memoryValue, Number(root.displayText), root.pendingOperator)
            if (!result.ok) {
                root.setError(result.message)
                return
            }

            root.memoryValue = result.value
            root.displayText = root.formatNumber(result.value)
        } else if (root.pendingOperator === "") {
            root.memoryValue = Number(root.displayText)
        }

        root.pendingOperator = op
        root.expressionText = root.formatNumber(root.memoryValue) + " " + op
        root.clearOnNextInput = true
    }

    function inputEquals() {
        if (root.errorState || root.pendingOperator === "" || root.clearOnNextInput)
            return

        var lhs = root.memoryValue
        var rhs = Number(root.displayText)
        var op = root.pendingOperator
        var result = root.runOperation(lhs, rhs, op)
        if (!result.ok) {
            root.setError(result.message)
            return
        }

        root.expressionText = root.formatNumber(lhs) + " " + op + " " + root.formatNumber(rhs) + " ="
        root.displayText = root.formatNumber(result.value)
        root.memoryValue = result.value
        root.pendingOperator = ""
        root.clearOnNextInput = true
    }

    function handleKey(event) {
        if (event.text >= "0" && event.text <= "9") {
            root.inputDigit(event.text)
            event.accepted = true
            return
        }

        switch (event.key) {
        case Qt.Key_Period:
        case Qt.Key_Comma:
            root.inputDot()
            event.accepted = true
            return
        case Qt.Key_Plus:
            root.inputOperator("+")
            event.accepted = true
            return
        case Qt.Key_Minus:
            root.inputOperator("-")
            event.accepted = true
            return
        case Qt.Key_Asterisk:
            root.inputOperator("×")
            event.accepted = true
            return
        case Qt.Key_Slash:
            root.inputOperator("÷")
            event.accepted = true
            return
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Equal:
            root.inputEquals()
            event.accepted = true
            return
        case Qt.Key_Backspace:
            root.backspace()
            event.accepted = true
            return
        case Qt.Key_Delete:
        case Qt.Key_Escape:
            root.clearAll()
            event.accepted = true
            return
        }
    }

    Keys.onPressed: (event) => root.handleKey(event)
    Component.onCompleted: root.forceActiveFocus()
    onVisibleChanged: if (visible) root.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        radius: Math.round(7 * PS.scale)
        color: Qt.rgba(1, 1, 1, 0.018)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.05)
    }

    Column {
        anchors.fill: parent
        anchors.margins: root._pad
        spacing: root._gap

        Rectangle {
            width: parent.width
            height: root._displayH
            radius: Math.round(4 * PS.scale)
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            Column {
                anchors.fill: parent
                anchors.leftMargin: Math.round(2 * PS.scale)
                anchors.rightMargin: Math.round(2 * PS.scale)
                anchors.topMargin: Math.round(1 * PS.scale)
                anchors.bottomMargin: Math.round(1 * PS.scale)
                spacing: 0

                Text {
                    width: parent.width
                    text: root.expressionText
                    color: root.errorState ? "#FF8B70" : Qt.rgba(1, 1, 1, 0.4)
                    font.pixelSize: Math.round(3 * PS.scale)
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

                Text {
                    width: parent.width
                    text: root.displayText
                    color: "white"
                    font.pixelSize: Math.round(6.2 * PS.scale)
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }
        }

        Row {
            spacing: root._gap

            CalcButton {
                width: root._buttonW
                height: root._buttonH
                label: "C"
                textColor: "#FFD27A"
                baseColor: Qt.rgba(0.95, 0.65, 0.25, 0.14)
                hoverColor: Qt.rgba(0.95, 0.65, 0.25, 0.22)
                pressedColor: Qt.rgba(0.95, 0.65, 0.25, 0.3)
                accent: true
                onClicked: root.clearAll()
            }

            CalcButton {
                width: root._buttonW
                height: root._buttonH
                label: "⌫"
                onClicked: root.backspace()
            }

            CalcButton {
                width: root._buttonW
                height: root._buttonH
                label: "÷"
                textColor: "#8FD3FF"
                baseColor: Qt.rgba(0.56, 0.83, 1.0, 0.14)
                hoverColor: Qt.rgba(0.56, 0.83, 1.0, 0.22)
                pressedColor: Qt.rgba(0.56, 0.83, 1.0, 0.3)
                accent: true
                onClicked: root.inputOperator("÷")
            }

            CalcButton {
                width: root._buttonW
                height: root._buttonH
                label: "×"
                textColor: "#8FD3FF"
                baseColor: Qt.rgba(0.56, 0.83, 1.0, 0.14)
                hoverColor: Qt.rgba(0.56, 0.83, 1.0, 0.22)
                pressedColor: Qt.rgba(0.56, 0.83, 1.0, 0.3)
                accent: true
                onClicked: root.inputOperator("×")
            }
        }

        Row {
            spacing: root._gap

            Repeater {
                model: ["7", "8", "9"]

                delegate: CalcButton {
                    width: root._buttonW
                    height: root._buttonH
                    label: modelData
                    onClicked: root.inputDigit(modelData)
                }
            }

            CalcButton {
                width: root._buttonW
                height: root._buttonH
                label: "-"
                textColor: "#8FD3FF"
                baseColor: Qt.rgba(0.56, 0.83, 1.0, 0.14)
                hoverColor: Qt.rgba(0.56, 0.83, 1.0, 0.22)
                pressedColor: Qt.rgba(0.56, 0.83, 1.0, 0.3)
                accent: true
                onClicked: root.inputOperator("-")
            }
        }

        Row {
            spacing: root._gap

            Repeater {
                model: ["4", "5", "6"]

                delegate: CalcButton {
                    width: root._buttonW
                    height: root._buttonH
                    label: modelData
                    onClicked: root.inputDigit(modelData)
                }
            }

            CalcButton {
                width: root._buttonW
                height: root._buttonH
                label: "+"
                textColor: "#8FD3FF"
                baseColor: Qt.rgba(0.56, 0.83, 1.0, 0.14)
                hoverColor: Qt.rgba(0.56, 0.83, 1.0, 0.22)
                pressedColor: Qt.rgba(0.56, 0.83, 1.0, 0.3)
                accent: true
                onClicked: root.inputOperator("+")
            }
        }

        Row {
            spacing: root._gap

            Repeater {
                model: ["1", "2", "3"]

                delegate: CalcButton {
                    width: root._buttonW
                    height: root._buttonH
                    label: modelData
                    onClicked: root.inputDigit(modelData)
                }
            }

            CalcButton {
                width: root._buttonW
                height: root._buttonH
                label: "="
                textColor: "#F2C66C"
                baseColor: Qt.rgba(0.95, 0.78, 0.42, 0.16)
                hoverColor: Qt.rgba(0.95, 0.78, 0.42, 0.24)
                pressedColor: Qt.rgba(0.95, 0.78, 0.42, 0.32)
                accent: true
                onClicked: root.inputEquals()
            }
        }

        Row {
            spacing: root._gap

            CalcButton {
                width: root._wideButtonW
                height: root._buttonH
                label: "0"
                onClicked: root.inputDigit("0")
            }

            CalcButton {
                width: root._buttonW
                height: root._buttonH
                label: "."
                onClicked: root.inputDot()
            }

            CalcButton {
                width: root._buttonW
                height: root._buttonH
                label: "±"
                onClicked: root.toggleSign()
            }
        }
    }
}
