#ifdef _WIN32

#include "dumpCatcher.h"

#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>

#include <windows.h>
#include <Dbghelp.h>

// ── 静态成员初始化 ──────────────────────────────────────────────────────────
std::wstring DumpCatcher::s_dumpDir;

// ── 注册异常过滤器 ──────────────────────────────────────────────────────────
void DumpCatcher::install(const QString &dumpDir)
{
    QString dir = dumpDir;
    if (dir.isEmpty()) {
        const QString appName = QCoreApplication::applicationName().isEmpty()
                                    ? QStringLiteral("app")
                                    : QCoreApplication::applicationName();
        dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
              + '/' + appName + "/crash";
    }

    QDir().mkpath(dir);

    // 转为宽字符后存储，崩溃回调中不再依赖 Qt 分配
    s_dumpDir = dir.toStdWString();

    SetUnhandledExceptionFilter(exceptionFilter);
}

// ── 崩溃回调：写入 .dmp 文件 ────────────────────────────────────────────────
long __stdcall DumpCatcher::exceptionFilter(EXCEPTION_POINTERS *ei)
{
    // 使用 Windows API 获取时间，避免在异常上下文中调用 Qt 堆分配
    SYSTEMTIME st;
    GetLocalTime(&st);

    wchar_t filename[32];
    swprintf_s(filename, L"%04d%02d%02d_%02d%02d%02d.dmp",
               st.wYear, st.wMonth, st.wDay,
               st.wHour, st.wMinute, st.wSecond);

    const std::wstring path = s_dumpDir + L'/' + filename;

    HANDLE hFile = CreateFileW(
        path.c_str(),
        GENERIC_WRITE,
        0,
        nullptr,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        nullptr
    );

    if (hFile != INVALID_HANDLE_VALUE) {
        MINIDUMP_EXCEPTION_INFORMATION mdei;
        mdei.ThreadId          = GetCurrentThreadId();
        mdei.ExceptionPointers = ei;
        mdei.ClientPointers    = FALSE;

        MiniDumpWriteDump(
            GetCurrentProcess(),
            GetCurrentProcessId(),
            hFile,
            MiniDumpNormal,
            ei ? &mdei : nullptr,
            nullptr,
            nullptr
        );

        CloseHandle(hFile);
    }

    // 继续向上传递，由系统弹出崩溃对话框
    return EXCEPTION_CONTINUE_SEARCH;
}

#endif // _WIN32
