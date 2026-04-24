import QtQuick
import "../common"

Item {
    id: root

    readonly property real caseW: 44.0 * 3
    readonly property real caseH: 49.0 * 3
    readonly property real rCorner: 7.5 * 3
    readonly property real compactBodyWidth: Math.round(root.caseW * PS.scale)
    readonly property real compactBodyHeight: Math.round(root.caseH * PS.scale)
    readonly property real _edgeInset: Math.round(8 * PS.scale)
    readonly property real _crownGap: Math.round(2 * PS.scale)
    readonly property real _crownOverlap: Math.round(4.1 * PS.scale)
    readonly property bool launcherIconPressed: appHost.launcherIconPressed
    readonly property bool adaptiveExpandMode: AppShell.activeExpandMode === "adaptive"
    readonly property real compactAppX: faceBody.x + Math.round((faceBody.width - appHost.implicitWidth) / 2)
    readonly property real compactAppY: faceBody.y + Math.round((faceBody.height - appHost.implicitHeight) / 2)
    readonly property real expandedAppWidth: Math.max(appHost.implicitWidth, faceBody.width - root._edgeInset * 2)
    readonly property real expandedAppHeight: Math.max(appHost.implicitHeight, faceBody.height - root._edgeInset * 2)
    readonly property real expandedAppX: faceBody.x + Math.round((faceBody.width - root.expandedAppWidth) / 2)
    readonly property real expandedAppY: faceBody.y + Math.round((faceBody.height - root.expandedAppHeight) / 2)
    readonly property real scaledAppSafeWidth: Math.max(appHost.implicitWidth, faceBody.width - root._edgeInset * 2)
    readonly property real scaledAppSafeHeight: Math.max(appHost.implicitHeight, faceBody.height - root._edgeInset * 2)
    readonly property real expandedAppScale: Math.max(1.0, Math.min(root.scaledAppSafeWidth / appHost.implicitWidth,
                                                                    root.scaledAppSafeHeight / appHost.implicitHeight))
    readonly property bool transitionAnimationsEnabled: !scaleGestureGuard.running

    property real windowX: 0
    property real windowY: 0

    implicitWidth: root.compactBodyWidth + crownButton.width - root._crownOverlap
    implicitHeight: root.compactBodyHeight

    // Watch body
    Rectangle {
        id: faceBody
        x: 0
        y: 0
        width: root.compactBodyWidth
        height: root.compactBodyHeight
        z: 0
        radius: Math.round(root.rCorner * PS.scale)
        color: "black"
        border.width: Math.round(2 * PS.scale)
        border.color: "#C0C0C0"
    }

    Item {
        id: topChrome
        anchors.fill: parent
        z: 3
        opacity: AppShell.expanded ? 0 : 1
        y: AppShell.expanded ? -Math.round(5 * PS.scale) : 0
        enabled: opacity > 0.01

        Behavior on opacity {
            enabled: root.transitionAnimationsEnabled
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            enabled: root.transitionAnimationsEnabled
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        // Location
        LocationLabel {
            visible: false
            x: faceBody.x + root._edgeInset
            y: faceBody.y + root._edgeInset
            cityName: $weatherMgr.cityName
        }

        // Time
        DateTime {
            id: dateTimeBlock
            x: faceBody.x + faceBody.width - width - root._edgeInset - root._crownOverlap - root._crownGap
            y: faceBody.y + root._edgeInset

            Behavior on x {
                enabled: root.transitionAnimationsEnabled
                NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
            }

            Behavior on y {
                enabled: root.transitionAnimationsEnabled
                NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
            }
        }
    }

    // Crown
    CrownButton {
        id: crownButton
        x: faceBody.x + faceBody.width - root._crownOverlap
        y: dateTimeBlock.y + dateTimeBlock.timeRowCenterY - height / 2
        z: -1
        onPressed: AppShell.crownPressed()
    }

    // Center app area
    AppHost {
        id: appHost
        x: AppShell.expanded && root.adaptiveExpandMode ? root.expandedAppX : root.compactAppX
        y: AppShell.expanded && root.adaptiveExpandMode ? root.expandedAppY : root.compactAppY
        z: 1
        width: AppShell.expanded && root.adaptiveExpandMode ? root.expandedAppWidth : implicitWidth
        height: AppShell.expanded && root.adaptiveExpandMode ? root.expandedAppHeight : implicitHeight
        scale: AppShell.expanded && !root.adaptiveExpandMode ? root.expandedAppScale : 1.0
        transformOrigin: Item.Center

        Behavior on x {
            enabled: root.transitionAnimationsEnabled
            NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
        }

        Behavior on y {
            enabled: root.transitionAnimationsEnabled
            NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
        }

        Behavior on width {
            enabled: root.transitionAnimationsEnabled
            NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
        }

        Behavior on height {
            enabled: root.transitionAnimationsEnabled
            NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
        }

        Behavior on scale {
            enabled: root.transitionAnimationsEnabled
            NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
        }
    }

    Item {
        id: bottomChrome
        anchors.fill: parent
        z: 3
        opacity: AppShell.expanded ? 0 : 1
        y: AppShell.expanded ? Math.round(6 * PS.scale) : 0
        enabled: opacity > 0.01

        Behavior on opacity {
            enabled: root.transitionAnimationsEnabled
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            enabled: root.transitionAnimationsEnabled
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        // Temperature
        TemperatureGauge {
            id: tempGauge
            x: faceBody.x + Math.round(15 * PS.scale)
            y: faceBody.y + faceBody.height - height - Math.round(8 * PS.scale)
            width: Math.round(30 * PS.scale)

            tempMin: $weatherMgr.tempMin
            tempMax: $weatherMgr.tempMax
            tempCurrent: $weatherMgr.temperature

            Behavior on x {
                enabled: root.transitionAnimationsEnabled
                NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
            }

            Behavior on y {
                enabled: root.transitionAnimationsEnabled
                NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
            }
        }

        // Weather
        WeatherIcon {
            x: faceBody.x + Math.round((faceBody.width - width) / 2)
            y: tempGauge.y + tempGauge.height - height
            weatherCode: $weatherMgr.weatherCode

            Behavior on x {
                enabled: root.transitionAnimationsEnabled
                NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
            }

            Behavior on y {
                enabled: root.transitionAnimationsEnabled
                NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
            }
        }

        // Eyes
        EyeFace {
            x: faceBody.x + faceBody.width - width - Math.round(15 * PS.scale)
            y: tempGauge.y + tempGauge.height - height
            watchMouseX: $mouseMgr.pos.x - root.windowX
            watchMouseY: $mouseMgr.pos.y - root.windowY
            onDoubleTapped: AppShell.toggleExpanded()

            Behavior on x {
                enabled: root.transitionAnimationsEnabled
                NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
            }

            Behavior on y {
                enabled: root.transitionAnimationsEnabled
                NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
            }
        }
    }

    Timer {
        id: scaleGestureGuard
        interval: 140
        repeat: false
    }

    // Ctrl + wheel zoom
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        acceptedModifiers: Qt.ControlModifier
        onWheel: (event) => {
            scaleGestureGuard.restart()
            var step = event.angleDelta.y / 120
            var newScale = PS.scale + step * 0.3
            PS.scale = Math.max(0.5, Math.min(15.0, newScale))
        }
    }
}
