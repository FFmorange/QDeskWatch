#include "marketpluginloader.h"

#include <QByteArray>
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QLibrary>
#include <QLoggingCategory>
#include <QStringList>

#include "market/marketplugincontract.h"
#include "market/marketstub.h"

Q_LOGGING_CATEGORY(logMarketPluginLoader, "MarketPluginLoader")

namespace {

QStringList candidatePluginPaths()
{
    const QDir appDir(QCoreApplication::applicationDirPath());
    QStringList paths;
    paths << QDir::cleanPath(appDir.filePath(QStringLiteral("../plugins/market/")
                                             + QString::fromLatin1(MarketPluginContract::FileName)));
    paths << appDir.filePath(QStringLiteral("plugins/market/")
                             + QString::fromLatin1(MarketPluginContract::FileName));
    paths << appDir.filePath(QString::fromLatin1(MarketPluginContract::FileName));
    paths.removeDuplicates();
    return paths;
}

}  // namespace

MarketPluginLoader &MarketPluginLoader::instance()
{
    static MarketPluginLoader loader;
    return loader;
}

MarketPluginLoader::~MarketPluginLoader()
{
    delete m_library;
    m_library = nullptr;
}

QObject *MarketPluginLoader::service(QObject *parent)
{
    if (!m_service)
        loadPlugin(parent);

    if (m_service && !m_service->parent() && parent)
        m_service->setParent(parent);

    return m_service;
}

bool MarketPluginLoader::pluginLoaded() const
{
    return m_pluginLoaded;
}

QString MarketPluginLoader::pluginPath() const
{
    return m_pluginPath;
}

QString MarketPluginLoader::errorString() const
{
    return m_errorString;
}

void MarketPluginLoader::loadPlugin(QObject *parent)
{
    QString lastError = QStringLiteral("market_plugin_not_found");

    for (const QString &path : candidatePluginPaths()) {
        if (!QFileInfo::exists(path))
            continue;

        auto *library = new QLibrary(path);
        if (!library->load()) {
            lastError = library->errorString();
            qCWarning(logMarketPluginLoader) << "Failed to load market plugin:" << path << lastError;
            delete library;
            continue;
        }

        const auto abiFn =
            reinterpret_cast<MarketPluginContract::AbiFn>(library->resolve(MarketPluginContract::AbiFunctionName));
        const auto createFn =
            reinterpret_cast<MarketPluginContract::CreateFn>(library->resolve(MarketPluginContract::CreateFunctionName));

        if (!abiFn || !createFn) {
            lastError = QStringLiteral("market_plugin_exports_missing");
            qCWarning(logMarketPluginLoader) << "Market plugin exports are missing:" << path;
            library->unload();
            delete library;
            continue;
        }

        const QByteArray abi = abiFn() ? QByteArray(abiFn()) : QByteArray();
        if (abi != QByteArray(MarketPluginContract::AbiVersion)) {
            lastError = QStringLiteral("market_plugin_abi_mismatch");
            qCWarning(logMarketPluginLoader) << "Market plugin ABI mismatch:" << path << abi;
            library->unload();
            delete library;
            continue;
        }

        QObject *serviceObject = createFn(parent);
        if (!serviceObject) {
            lastError = QStringLiteral("market_plugin_create_failed");
            qCWarning(logMarketPluginLoader) << "Market plugin returned a null service:" << path;
            library->unload();
            delete library;
            continue;
        }

        m_library = library;
        m_service = serviceObject;
        m_pluginLoaded = true;
        m_pluginPath = path;
        m_errorString.clear();

        qCInfo(logMarketPluginLoader) << "Market plugin loaded:" << path;
        return;
    }

    m_errorString = lastError;
    m_service = createStub(parent);
    m_pluginLoaded = false;
    m_pluginPath.clear();

    qCWarning(logMarketPluginLoader) << "Market plugin unavailable, fallback to stub:" << lastError;
}

QObject *MarketPluginLoader::createStub(QObject *parent)
{
    return new MarketStub(parent);
}
