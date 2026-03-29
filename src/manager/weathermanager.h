#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QTimer>

#include "definevaluehelper.h"

class WeatherManager : public QObject
{
    Q_OBJECT

    // ── QML 可绑定属性（每条生成 getter / setter / Changed 信号）──────────────
    DEFINE_VALUE(bool,    loading,     false)     // 正在请求中
    DEFINE_VALUE(QString, errorMsg,    {})         // 最近一次错误信息
    DEFINE_VALUE(QString, cityName,    {})         // 城市名
    DEFINE_VALUE(double,  temperature, 0.0)        // 当前气温 (°C)
    DEFINE_VALUE(double,  feelsLike,   0.0)        // 体感气温 (°C)
    DEFINE_VALUE(int,     weatherCode, 0)          // WMO 天气代码
    DEFINE_VALUE(QString, weatherDesc, {})         // 天气描述（中文）
    DEFINE_VALUE(double,  windSpeed,   0.0)        // 风速 (km/h)
    DEFINE_VALUE(int,     humidity,    0)          // 相对湿度 (%)
    DEFINE_VALUE(double,  tempMax,     0.0)        // 今日最高气温 (°C)
    DEFINE_VALUE(double,  tempMin,     0.0)        // 今日最低气温 (°C)

public:
    static WeatherManager *instance();

    // QML 可主动调用：立即刷新天气
    Q_INVOKABLE void refresh();

private:
    explicit WeatherManager(QObject *parent = nullptr);
    static WeatherManager *s_instance;

    // ── 两阶段拉取：先定位，再拉天气 ──────────────────────────────────────────
    void fetchLocation();
    void fetchWeather(double lat, double lon);

    static QString codeToDesc(int code);

    QNetworkAccessManager *m_nam   = nullptr;
    QTimer                *m_timer = nullptr;

    double m_cachedLat = 0.0;
    double m_cachedLon = 0.0;
};