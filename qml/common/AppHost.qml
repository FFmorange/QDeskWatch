import QtQuick

Item {
    id: root

    property var _loadedApps: ({})
    readonly property bool launcherIconPressed: launcher.iconPressed

    implicitWidth: Math.round(96 * PS.scale)
    implicitHeight: Math.round(66 * PS.scale)
    clip: false

    function _copyLoadedApps() {
        var next = {}
        for (var key in root._loadedApps)
            next[key] = root._loadedApps[key]
        return next
    }

    function markLoaded(appId) {
        if (!appId || root._loadedApps[appId])
            return

        var next = root._copyLoadedApps()
        next[appId] = true
        root._loadedApps = next
    }

    function shouldKeepAlive(appDef) {
        return !appDef || appDef.keepAlive !== false
    }

    Component.onCompleted: markLoaded(AppShell.activeAppId)

    Connections {
        target: AppShell

        function onActiveAppIdChanged() {
            root.markLoaded(AppShell.activeAppId)
        }
    }

    AppLauncher {
        id: launcher
        anchors.fill: parent
        visible: AppShell.mode === "launcher"
    }

    Repeater {
        model: AppShell.apps

        delegate: Loader {
            id: appLoader

            readonly property var appDef: modelData
            readonly property bool keepAlive: root.shouldKeepAlive(appDef)

            anchors.fill: parent
            active: AppShell.activeAppId === appDef.id || (keepAlive && root._loadedApps[appDef.id])
            visible: AppShell.mode === "app" && AppShell.activeAppId === appDef.id
            source: appDef.source
        }
    }
}
