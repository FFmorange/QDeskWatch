#pragma once

#include <QObject>
#include <QString>

class QLibrary;

class MarketPluginLoader
{
public:
    static MarketPluginLoader &instance();

    QObject *service(QObject *parent = nullptr);
    bool pluginLoaded() const;
    QString pluginPath() const;
    QString errorString() const;

private:
    MarketPluginLoader() = default;
    ~MarketPluginLoader();

    MarketPluginLoader(const MarketPluginLoader &) = delete;
    MarketPluginLoader &operator=(const MarketPluginLoader &) = delete;

    void loadPlugin(QObject *parent);
    QObject *createStub(QObject *parent);

    QLibrary *m_library = nullptr;
    QObject *m_service = nullptr;
    bool m_pluginLoaded = false;
    QString m_pluginPath;
    QString m_errorString;
};
