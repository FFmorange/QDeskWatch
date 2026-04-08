import QtQuick

Item {
    id: root

    readonly property int _tileWidth: Math.round(28 * PS.scale)
    readonly property int _tileHeight: Math.round(31 * PS.scale)
    readonly property int _iconSize: Math.round(16 * PS.scale)
    readonly property int _labelSize: Math.round(4.3 * PS.scale)
    readonly property int _gap: Math.round(6 * PS.scale)
    property string pressedIconAppId: ""
    readonly property bool iconPressed: root.pressedIconAppId !== ""

    Grid {
        id: iconGrid
        anchors.centerIn: parent
        columns: Math.max(1, Math.min(3, AppShell.appCount))
        rowSpacing: root._gap
        columnSpacing: root._gap

        Repeater {
            model: AppShell.apps

            delegate: Item {
                id: tileRoot

                readonly property var appDef: modelData
                readonly property bool selected: AppShell.selectedAppId === appDef.id
                readonly property bool hovered: iconHover.hovered
                readonly property bool pressed: iconTap.pressed
                readonly property real _restScale: 0.94
                readonly property real _selectedScale: 1.06
                readonly property real _hoverScale: 1.12
                readonly property real _pressedScale: 0.92

                width: root._tileWidth
                height: root._tileHeight

                Item {
                    id: visualRoot
                    anchors.fill: parent

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(2.6 * PS.scale)

                        Item {
                            id: iconMotion
                            width: root._iconSize
                            height: root._iconSize
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: tileRoot.pressed ? Math.round(0.7 * PS.scale) : 0
                            scale: tileRoot.pressed ? tileRoot._pressedScale
                                                    : tileRoot.hovered ? tileRoot._hoverScale
                                                    : tileRoot.selected ? tileRoot._selectedScale
                                                    : tileRoot._restScale
                            opacity: tileRoot.pressed ? 0.94 : (tileRoot.selected || tileRoot.hovered ? 1.0 : 0.72)
                            transformOrigin: Item.Center

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
                                anchors.centerIn: parent
                                visible: !!tileRoot.appDef.icon
                                width: parent.width
                                height: parent.height
                                source: tileRoot.appDef.icon ? Theme.icon(tileRoot.appDef.icon) : ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                cache: true
                                sourceSize.width: Math.round(width * 4)
                                sourceSize.height: Math.round(height * 4)
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !tileRoot.appDef.icon
                                text: tileRoot.appDef.symbol || "?"
                                color: "white"
                                font.pixelSize: Math.round(7.5 * PS.scale)
                                font.bold: true
                            }
                        }

                        Text {
                            width: tileRoot.width + Math.round(2 * PS.scale)
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tileRoot.appDef.title || ""
                            color: "white"
                            font.pixelSize: root._labelSize
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                HoverHandler {
                    id: iconHover
                    parent: iconMotion
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    id: iconTap
                    parent: iconMotion
                    gesturePolicy: TapHandler.ReleaseWithinBounds

                    onPressedChanged: {
                        if (pressed)
                            root.pressedIconAppId = tileRoot.appDef.id
                        else if (root.pressedIconAppId === tileRoot.appDef.id)
                            root.pressedIconAppId = ""
                    }

                    onTapped: {
                        AppShell.openApp(tileRoot.appDef.id)
                    }
                }
            }
        }
    }
}
