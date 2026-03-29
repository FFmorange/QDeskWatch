pragma Singleton
import QtQuick
import QtQuick.Window

QtObject {
    property real scale: Screen.pixelDensity // Screen.pixelDensity 单位为 像素/mm；可在运行时覆写
}