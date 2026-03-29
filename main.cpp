#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "dumpcatcher.h"
#include "globalmousetracker.h"
#include "logger.h"
#include "manager/weathermanager.h"

static bool contextPropertys(QQmlApplicationEngine &engine)
{
    engine.rootContext()->setContextProperty("$weatherMgr", WeatherManager::instance());
    engine.rootContext()->setContextProperty("$mouseMgr",   GlobalMouseTracker::instance());
    return true;
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("iWatch");
    app.setApplicationVersion("0.1");

#ifdef _WIN32
    DumpCatcher::install();
#endif

    Logger::instance()->install();
    qCInfo(log) << "Application starting";

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    contextPropertys(engine);
    engine.loadFromModule("iWatch", "Main");

    return app.exec();
}
