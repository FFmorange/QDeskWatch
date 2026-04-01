pragma Singleton
import QtQuick

QtObject {
    id: root

    property var apps: [
        {
            "id": "memo",
            "title": "Memo",
            "symbol": "M",
            "icon": "memo_checklist",
            "accent": "#8FD3FF",
            "source": "qrc:/qt/qml/QDeskWatch/qml/apps/MemoApp.qml",
            "keepAlive": true
        }
    ]

    property string mode: "launcher"
    property string activeAppId: "memo"
    property string selectedAppId: "memo"

    readonly property int appCount: root.apps.length
    readonly property var activeApp: root.appById(root.activeAppId)
    readonly property var selectedApp: root.appById(root.selectedAppId)

    function appById(appId) {
        for (var i = 0; i < root.apps.length; ++i) {
            if (root.apps[i].id === appId)
                return root.apps[i]
        }
        return null
    }

    function appAt(index) {
        if (index < 0 || index >= root.apps.length)
            return null
        return root.apps[index]
    }

    function indexOfApp(appId) {
        for (var i = 0; i < root.apps.length; ++i) {
            if (root.apps[i].id === appId)
                return i
        }
        return -1
    }

    function selectApp(appId) {
        if (!root.appById(appId))
            return
        root.selectedAppId = appId
    }

    function selectNext() {
        if (root.appCount === 0)
            return

        var index = root.indexOfApp(root.selectedAppId)
        if (index < 0)
            index = Math.max(0, root.indexOfApp(root.activeAppId))

        root.selectedAppId = root.apps[(index + 1) % root.appCount].id
    }

    function selectPrevious() {
        if (root.appCount === 0)
            return

        var index = root.indexOfApp(root.selectedAppId)
        if (index < 0)
            index = Math.max(0, root.indexOfApp(root.activeAppId))

        root.selectedAppId = root.apps[(index - 1 + root.appCount) % root.appCount].id
    }

    function showLauncher() {
        if (root.appCount === 0)
            return

        if (!root.appById(root.selectedAppId))
            root.selectedAppId = root.activeAppId || root.apps[0].id

        root.mode = "launcher"
    }

    function openApp(appId) {
        var app = root.appById(appId || root.selectedAppId)
        if (!app)
            return

        root.activeAppId = app.id
        root.selectedAppId = app.id
        root.mode = "app"
    }

    function openSelectedApp() {
        root.openApp(root.selectedAppId)
    }

    function crownPressed() {
        if (root.mode === "launcher")
            root.openSelectedApp()
        else
            root.showLauncher()
    }

    Component.onCompleted: {
        if (root.appCount === 0)
            return

        if (!root.appById(root.activeAppId))
            root.activeAppId = root.apps[0].id

        if (!root.appById(root.selectedAppId))
            root.selectedAppId = root.activeAppId
    }
}
