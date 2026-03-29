#include "weathermanager.h"
#include "logger.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>
#include <QUrlQuery>

Q_LOGGING_CATEGORY(logWeather, "WeatherManager")

// ── 静态成员 ─────────────────────────────────────────────────────────────────
WeatherManager *WeatherManager::s_instance = nullptr;

// ── 单例 ─────────────────────────────────────────────────────────────────────
WeatherManager *WeatherManager::instance()
{
    if (!s_instance)
        s_instance = new WeatherManager;
    return s_instance;
}

// ── 构造：启动定时刷新 ────────────────────────────────────────────────────────
WeatherManager::WeatherManager(QObject *parent) : QObject(parent)
{
    m_nam   = new QNetworkAccessManager(this);
    m_timer = new QTimer(this);

    // 每 30 分钟自动刷新一次
    m_timer->setInterval(30 * 60 * 1000);
    connect(m_timer, &QTimer::timeout, this, &WeatherManager::refresh);
    m_timer->start();

    refresh();
}

// ── 公开刷新入口 ──────────────────────────────────────────────────────────────
void WeatherManager::refresh()
{
    if (loading()) return;   // 避免重复请求
    set_errorMsg({});
    fetchLocation();
}

// ── 第一步：IP 定位 → 获取经纬度和城市名 ─────────────────────────────────────
// 使用 ipapi.co（免费，无需 Key）
void WeatherManager::fetchLocation()
{
    set_loading(true);

    QNetworkRequest req(QUrl("https://ipapi.co/json/"));
    req.setHeader(QNetworkRequest::UserAgentHeader, "iWatch/1.0");

    auto *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            qCWarning(logWeather) << "Location error:" << reply->errorString();
            set_errorMsg(reply->errorString());
            set_loading(false);
            return;
        }

        const auto doc = QJsonDocument::fromJson(reply->readAll());
        qCDebug(logWeather) << "Location JSON:\n" << doc.toJson(QJsonDocument::Indented).constData();
        const auto obj = doc.object();
        m_cachedLat    = obj["latitude"].toDouble();
        m_cachedLon    = obj["longitude"].toDouble();
        set_cityName(obj["city"].toString());

        qCInfo(logWeather) << "Location:" << cityName() << m_cachedLat << m_cachedLon;
        fetchWeather(m_cachedLat, m_cachedLon);
    });
}

// ── 第二步：Open-Meteo 拉天气（免费，无需 Key）────────────────────────────────
void WeatherManager::fetchWeather(double lat, double lon)
{
    QUrlQuery q;
    q.addQueryItem("latitude",  QString::number(lat, 'f', 4));
    q.addQueryItem("longitude", QString::number(lon, 'f', 4));
    q.addQueryItem("current",   "temperature_2m,apparent_temperature,"
                                "weather_code,wind_speed_10m,relative_humidity_2m");
    q.addQueryItem("daily",     "temperature_2m_max,temperature_2m_min");
    q.addQueryItem("wind_speed_unit", "kmh");
    q.addQueryItem("timezone",  "auto");

    QUrl url("https://api.open-meteo.com/v1/forecast");
    url.setQuery(q);

    auto *reply = m_nam->get(QNetworkRequest(url));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        set_loading(false);

        if (reply->error() != QNetworkReply::NoError) {
            qCWarning(logWeather) << "Weather error:" << reply->errorString();
            set_errorMsg(reply->errorString());
            return;
        }

        const auto doc     = QJsonDocument::fromJson(reply->readAll());
        qCDebug(logWeather) << "Weather JSON:\n" << doc.toJson(QJsonDocument::Indented).constData();
        const auto current = doc.object()["current"].toObject();

        set_temperature(current["temperature_2m"].toDouble());
        set_feelsLike(current["apparent_temperature"].toDouble());
        set_windSpeed(current["wind_speed_10m"].toDouble());
        set_humidity(current["relative_humidity_2m"].toInt());

        const int code = current["weather_code"].toInt();
        set_weatherCode(code);
        set_weatherDesc(codeToDesc(code));

        const auto daily = doc.object()["daily"].toObject();
        set_tempMax(daily["temperature_2m_max"].toArray().first().toDouble());
        set_tempMin(daily["temperature_2m_min"].toArray().first().toDouble());

        qCInfo(logWeather) << "Weather updated:" << weatherDesc()
                           << temperature() << "°C";
    });
}

// ── WMO 天气代码 → 中文描述 ──────────────────────────────────────────────────
QString WeatherManager::codeToDesc(int code)
{
    switch (code) {
    case 0:            return "晴";
    case 1:            return "晴间多云";
    case 2:            return "多云";
    case 3:            return "阴";
    case 45: case 48:  return "雾";
    case 51: case 53:  return "毛毛雨";
    case 55:           return "细雨";
    case 56: case 57:  return "冻毛毛雨";
    case 61:           return "小雨";
    case 63:           return "中雨";
    case 65:           return "大雨";
    case 66: case 67:  return "冻雨";
    case 71:           return "小雪";
    case 73:           return "中雪";
    case 75:           return "大雪";
    case 77:           return "冰粒";
    case 80:           return "阵雨";
    case 81:           return "中阵雨";
    case 82:           return "强阵雨";
    case 85: case 86:  return "阵雪";
    case 95:           return "雷阵雨";
    case 96: case 99:  return "雷雨伴冰雹";
    default:           return "未知";
    }
}