#include <QAction>
#include <QApplication>
#include <QIcon>
#include <QMenu>
#include <QPointer>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSystemTrayIcon>
#include <QWindow>

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

static void showAndActivateWindow(QWindow *window)
{
    if (!window)
        return;

    window->show();
    window->raise();
    window->requestActivate();
}

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName(APP_NAME);
    app.setApplicationVersion(APP_VERSION);
    app.setQuitOnLastWindowClosed(false);

    const QIcon appIcon(QStringLiteral(":/qt/qml/QDeskWatch/resources/app-icon/qdeskwatch.ico"));
    app.setWindowIcon(appIcon);

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
    engine.loadFromModule(APP_QML_URI, "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    QPointer<QWindow> rootWindow = qobject_cast<QWindow *>(engine.rootObjects().constFirst());
    if (!rootWindow) {
        qCCritical(log) << "Main QML root object is not a window";
        return -1;
    }

    QSystemTrayIcon trayIcon;
    QMenu trayMenu;
    QAction toggleWindowAction(&trayMenu);
    QAction quitAction(QStringLiteral("Exit"), &trayMenu);

    const auto updateTrayMenu = [&toggleWindowAction, rootWindow]() {
        toggleWindowAction.setText(rootWindow && rootWindow->isVisible()
                                       ? QStringLiteral("Hide QDeskWatch")
                                       : QStringLiteral("Show QDeskWatch"));
    };

    QObject::connect(&toggleWindowAction, &QAction::triggered, &app, [&]() {
        if (!rootWindow)
            return;

        if (rootWindow->isVisible())
            rootWindow->hide();
        else
            showAndActivateWindow(rootWindow);

        updateTrayMenu();
    });
    QObject::connect(&quitAction, &QAction::triggered, &app, &QCoreApplication::quit);

    trayMenu.addAction(&toggleWindowAction);
    trayMenu.addSeparator();
    trayMenu.addAction(&quitAction);

    if (QSystemTrayIcon::isSystemTrayAvailable()) {
        trayIcon.setIcon(appIcon);
        trayIcon.setToolTip(QCoreApplication::applicationName());
        trayIcon.setContextMenu(&trayMenu);

        QObject::connect(rootWindow, &QWindow::visibleChanged, &app, updateTrayMenu);
        QObject::connect(&trayIcon, &QSystemTrayIcon::activated, &app,
                         [&](QSystemTrayIcon::ActivationReason reason) {
                             if (reason != QSystemTrayIcon::Trigger
                                 && reason != QSystemTrayIcon::DoubleClick) {
                                 return;
                             }

                             if (rootWindow && rootWindow->isVisible())
                                 rootWindow->hide();
                             else
                                 showAndActivateWindow(rootWindow);

                             updateTrayMenu();
                         });

        updateTrayMenu();
        trayIcon.show();
    } else {
        qCWarning(log) << "System tray is unavailable";
    }

    return app.exec();
}
