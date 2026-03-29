pragma Singleton
import QtQuick

// 主题配置单例
// 启动时从 resources/default.theme 读取图标路径和格式
// 用法：source: Theme.icon("resize_normal")  // 无需路径、无需后缀
QtObject {
    id: root

    property string _iconsBase:   "qrc:/qt/qml/iWatch/resources/icons/"
    property string _iconsFormat: "svg"

    // 按名称返回图标 URL
    function icon(name) {
        return _iconsBase + name + "." + _iconsFormat
    }

    // 启动时解析 .theme 文件，覆盖默认配置
    Component.onCompleted: {
        var xhr = new XMLHttpRequest()
        // 同步读取，确保首帧渲染前已就绪
        xhr.open("GET", "qrc:/qt/qml/iWatch/resources/default.theme", false)
        xhr.send()
        if (!xhr.responseText) return
        try {
            var cfg = JSON.parse(xhr.responseText)
            if (cfg.icons) {
                if (cfg.icons.format) _iconsFormat = cfg.icons.format
                if (cfg.icons.path)
                    _iconsBase = "qrc:/qt/qml/iWatch/" + cfg.icons.path
            }
        } catch(e) {
            console.warn("Theme: failed to parse default.theme –", e)
        }
    }
}