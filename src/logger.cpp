#include "logger.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QThread>

// ── 日志分类定义 ────────────────────────────────────────────────────────────
Q_LOGGING_CATEGORY(log, "Logger")

// ── 静态成员初始化 ──────────────────────────────────────────────────────────
Logger *Logger::s_instance = nullptr;
QMutex  Logger::s_mutex;

// ── 单例 ────────────────────────────────────────────────────────────────────
Logger *Logger::instance()
{
    if (!s_instance) {
        QMutexLocker lock(&s_mutex);
        if (!s_instance)
            s_instance = new Logger;
    }
    return s_instance;
}

// ── 构造：打开日志文件 ──────────────────────────────────────────────────────
Logger::Logger(QObject *parent) : QObject(parent)
{
    const QString path = buildLogFilePath();
    QDir().mkpath(QFileInfo(path).absolutePath());

    m_file.setFileName(path);
    m_fileOpen = m_file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text);
    if (m_fileOpen) {
        m_stream.setDevice(&m_file);
        m_stream.setEncoding(QStringConverter::Utf8);

        const QString header = QString("─").repeated(80) + '\n'
            + QString("[SESSION START] %1  PID:%2  App:%3  Version:%4\n")
                  .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz"))
                  .arg(QCoreApplication::applicationPid())
                  .arg(QCoreApplication::applicationName())
                  .arg(QCoreApplication::applicationVersion())
            + QString("─").repeated(80);
        m_stream << header << '\n';
        m_stream.flush();
    }
}

// ── 安装为全局 Qt 消息处理器 ────────────────────────────────────────────────
void Logger::install(int retentionDays)
{
    cleanOldLogs(retentionDays);

    qInstallMessageHandler([](QtMsgType type,
                               const QMessageLogContext &ctx,
                               const QString &msg) {
        Logger::instance()->handleMessage(type, ctx, msg);
    });
}

// ── 清理超期日志文件 ────────────────────────────────────────────────────────
void Logger::cleanOldLogs(int retentionDays)
{
    if (retentionDays < 0)
        return;

    const QString appName = QCoreApplication::applicationName().isEmpty()
                                ? QStringLiteral("app")
                                : QCoreApplication::applicationName();

    const QString logDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                           + '/' + appName;

    QDir dir(logDir);
    if (!dir.exists())
        return;

    const auto entries = dir.entryInfoList({"*.log"}, QDir::Files);

    // retentionDays == 0：删除全部日志
    // retentionDays >  0：删除超过 N 天的日志
    const QDateTime cutoff = retentionDays == 0
                                 ? QDateTime::currentDateTime()
                                 : QDateTime::currentDateTime().addDays(-retentionDays);

    for (const QFileInfo &fi : entries) {
        if (retentionDays == 0 || fi.lastModified() < cutoff)
            QFile::remove(fi.absoluteFilePath());
    }
}

// ── Qt 消息处理器回调（捕获 qCDebug / console.log 等所有输出）──────────────
void Logger::handleMessage(QtMsgType type,
                            const QMessageLogContext &ctx,
                            const QString &msg)
{
    write(type,
          ctx.category ? QString::fromUtf8(ctx.category) : QString{},
          ctx.function ? QString::fromUtf8(ctx.function) : QString{},
          ctx.file     ? QString::fromUtf8(ctx.file)     : QString{},
          ctx.line,
          msg);
}

// ── QML 调用方法 ────────────────────────────────────────────────────────────
void Logger::debug(const QString &msg, const QString &func) { write(QtDebugMsg,    "qml", func, {}, -1, msg); }
void Logger::info (const QString &msg, const QString &func) { write(QtInfoMsg,     "qml", func, {}, -1, msg); }
void Logger::warn (const QString &msg, const QString &func) { write(QtWarningMsg,  "qml", func, {}, -1, msg); }
void Logger::error(const QString &msg, const QString &func) { write(QtCriticalMsg, "qml", func, {}, -1, msg); }

// ── 核心写入（线程安全）────────────────────────────────────────────────────
// 格式：[时间戳] [等级] [TID:XXXXXXXX] [Category] [函数签名] [文件:行] 消息
void Logger::write(QtMsgType      type,
                   const QString &category,
                   const QString &func,
                   const QString &file,
                   int            line,
                   const QString &msg)
{
    const QString ts     = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz");
    const quintptr tid   = reinterpret_cast<quintptr>(QThread::currentThreadId());
    const QString tidStr = QString::number(tid, 16).toUpper().rightJustified(8, '0');
    const QString fname  = file.isEmpty() ? QString{} : QFileInfo(file).fileName();

    QString record;
    record.reserve(320);
    record += '['; record += ts;              record += "] ";
    record += '['; record += levelTag(type);  record += "] ";
    record += "[TID:"; record += tidStr;      record += "] ";

    if (!category.isEmpty()) {
        record += '['; record += category;    record += "] ";
    }
    if (!func.isEmpty()) {
        record += '['; record += func;        record += "] ";
    }
    if (!fname.isEmpty()) {
        record += '['; record += fname;
        if (line > 0) { record += ':'; record += QString::number(line); }
        record += "] ";
    }
    record += msg;

    QMutexLocker lock(&s_mutex);

    if (m_fileOpen) {
        m_stream << record << '\n';
        m_stream.flush();
    }

    fprintf(stderr, "%s\n", qUtf8Printable(record));

    if (type == QtFatalMsg)
        abort();
}

// ── 日志等级标签 ────────────────────────────────────────────────────────────
QString Logger::levelTag(QtMsgType type)
{
    switch (type) {
    case QtDebugMsg:    return "DEBUG";
    case QtInfoMsg:     return "INFO ";
    case QtWarningMsg:  return "WARN ";
    case QtCriticalMsg: return "ERROR";
    case QtFatalMsg:    return "FATAL";
    default:            return "     ";
    }
}

// ── 构建日志文件完整路径 ────────────────────────────────────────────────────
// 结构：C:/Users/<user>/AppData/Local/<AppName>/cache/<AppName>/<yyyyMMdd_HHmmss>_<AppName>.log
QString Logger::buildLogFilePath()
{
    const QString appName = QCoreApplication::applicationName().isEmpty()
                                ? QStringLiteral("app")
                                : QCoreApplication::applicationName();

    const QString dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                        + '/' + appName;

    const QString ts = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");

    return dir + '/' + ts + '_' + appName + ".log";
}
