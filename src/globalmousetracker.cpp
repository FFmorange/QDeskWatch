#include "globalmousetracker.h"

#include <QGuiApplication>
#include <QScreen>

#ifdef _WIN32
#  define WIN32_LEAN_AND_MEAN
#  include <windows.h>

static LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    if (nCode == HC_ACTION) {
        const auto *ms  = reinterpret_cast<MSLLHOOKSTRUCT *>(lParam);
        double       dpr = QGuiApplication::primaryScreen()
                               ? QGuiApplication::primaryScreen()->devicePixelRatio()
                               : 1.0;
        GlobalMouseTracker::instance()->updatePos(ms->pt.x / dpr, ms->pt.y / dpr);
    }
    return CallNextHookEx(nullptr, nCode, wParam, lParam);
}
#endif

// ── 静态成员 ─────────────────────────────────────────────────────────────────
GlobalMouseTracker *GlobalMouseTracker::s_instance = nullptr;

#ifdef _WIN32
void *GlobalMouseTracker::s_hook = nullptr;
#endif

// ── 单例 ─────────────────────────────────────────────────────────────────────
GlobalMouseTracker *GlobalMouseTracker::instance()
{
    if (!s_instance)
        s_instance = new GlobalMouseTracker;
    return s_instance;
}

// ── 构造 ─────────────────────────────────────────────────────────────────────
GlobalMouseTracker::GlobalMouseTracker(QObject *parent) : QObject(parent)
{
#ifdef _WIN32
    installHook();
#endif
}

GlobalMouseTracker::~GlobalMouseTracker()
{
#ifdef _WIN32
    removeHook();
#endif
}

// ── 位置更新（钩子回调调用）──────────────────────────────────────────────────
void GlobalMouseTracker::updatePos(double x, double y)
{
    set_pos(QPointF(x, y));
}

#ifdef _WIN32
void GlobalMouseTracker::installHook()
{
    s_hook = SetWindowsHookEx(
        WH_MOUSE_LL,
        LowLevelMouseProc,
        GetModuleHandle(nullptr),
        0);
}

void GlobalMouseTracker::removeHook()
{
    if (s_hook) {
        UnhookWindowsHookEx(static_cast<HHOOK>(s_hook));
        s_hook = nullptr;
    }
}
#endif
