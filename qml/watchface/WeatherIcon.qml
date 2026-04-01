import QtQuick

// 天气图标控件
// 根据 WMO weatherCode 自动显示对应 SVG 图标
Item {
    id: root

    property int weatherCode: 0

    implicitWidth:  Math.round(30 * PS.scale)
    implicitHeight: implicitWidth

    Image {
        anchors.fill: parent
        source:     Theme.icon(_codeToIcon(root.weatherCode))
        sourceSize: Qt.size(width, height)
        fillMode:   Image.PreserveAspectFit
    }

    function _codeToIcon(code) {
        if (code === 0)                  return "weather_clear"
        if (code <= 2)                   return "weather_partly_cloudy"
        if (code === 3)                  return "weather_overcast"
        if (code === 45 || code === 48)  return "weather_fog"
        if (code >= 51 && code <= 57)    return "weather_drizzle"
        if (code >= 61 && code <= 65)    return "weather_rain"
        if (code === 66 || code === 67)  return "weather_sleet"
        if (code >= 71 && code <= 77)    return "weather_snow"
        if (code >= 80 && code <= 82)    return "weather_shower"
        if (code === 85 || code === 86)  return "weather_snow_shower"
        if (code >= 95)                  return "weather_thunderstorm"
        return "weather_overcast"
    }
}
