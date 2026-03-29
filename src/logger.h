#pragma once

#include <QFile>
#include <QLoggingCategory>
#include <QMutex>
#include <QObject>
#include <QTextStream>
#include <QtQml/qqml.h>

/**
 * @brief 全局日志单例
 *
 * 功能：
 *  - 通过 qInstallMessageHandler 接管所有 Qt / QML 输出
 *  - 日志写入 C:/Users/<user>/AppData/Local/<AppName>/cache/<AppName>/<ts>_<AppName>.log
 *  - 同时镜像到 stderr（Qt Creator 输出面板仍可见）
 *  - 线程安全
 *  - 可在 QML 中以单例访问：import iWatch → Logger.info("msg")
 *
 * 日志格式：
 *  [yyyy-MM-dd HH:mm:ss.zzz] [LEVEL] [TID:XXXXXXXX] [Category] [func] [file:line] message
 *
 * C++ 用法（Qt 原生，自动携带位置信息）：
 *  qCDebug(logApp)    << "调试信息";
 *  qCInfo(logApp)     << "普通信息";
 *  qCWarning(logApp)  << "警告";
 *  qCCritical(logApp) << QString("连接失败：%1").arg(err);
 *
 * QML 用法：
 *  Logger.info("message")     // C++ 单例方法
 *  console.log("message")     // 同样被捕获
 */
class Logger : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static Logger *instance();

    // QML 引擎单例工厂
    static Logger *create(QQmlEngine *, QJSEngine *) { return instance(); }

    // 在 main() 中、QML 引擎创建之前调用，接管全局消息输出
    // retentionDays: 保留最近 N 天的日志，超期文件自动删除（默认 7 天）
    void install(int retentionDays = 7);

    // Qt 消息处理器回调（内部使用）
    void handleMessage(QtMsgType type,
                       const QMessageLogContext &ctx,
                       const QString &msg);

    // QML 可直接调用的日志方法
    Q_INVOKABLE void debug(const QString &msg, const QString &func = {});
    Q_INVOKABLE void info (const QString &msg, const QString &func = {});
    Q_INVOKABLE void warn (const QString &msg, const QString &func = {});
    Q_INVOKABLE void error(const QString &msg, const QString &func = {});

private:
    explicit Logger(QObject *parent = nullptr);

    void write(QtMsgType      type,
               const QString &category,
               const QString &func,
               const QString &file,
               int            line,
               const QString &msg);

    static QString levelTag(QtMsgType type);
    static QString buildLogFilePath();
    static void    cleanOldLogs(int retentionDays);

    static Logger *s_instance;
    static QMutex  s_mutex;

    QFile       m_file;
    QTextStream m_stream;
    bool        m_fileOpen = false;
};

// ── 日志分类声明（在 Logger.cpp 中定义）────────────────────────────────────
// 使用：qCInfo(log) << "message";
Q_DECLARE_LOGGING_CATEGORY(log)