#pragma once

#ifdef _WIN32

#include <QString>
#include <string>

/**
 * @brief Windows 崩溃转储捕获器
 *
 * 在进程发生未处理异常时，自动将 minidump 写入指定目录，
 * 文件名格式：yyyyMMdd_HHmmss.dmp
 *
 * 默认存储路径：
 *   C:/Users/<user>/AppData/Local/<AppName>/cache/<AppName>/crash/
 *
 * C++ 用法（在 main() 中、QGuiApplication 初始化之后调用）：
 *   DumpCatcher::install();
 *
 * 可指定自定义目录：
 *   DumpCatcher::install("D:/MyApp/crash");
 */
class DumpCatcher
{
public:
    // 注册未处理异常过滤器
    // dumpDir: 留空则使用默认 cache 路径下的 crash/ 子目录
    static void install(const QString &dumpDir = {});

private:
    // 预存转储目录（宽字符，避免崩溃时依赖 Qt 堆分配）
    static std::wstring s_dumpDir;

    // Windows 未处理异常回调
    static long __stdcall exceptionFilter(struct _EXCEPTION_POINTERS *ei);
};

#endif // _WIN32