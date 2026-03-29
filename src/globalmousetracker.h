#ifndef GLOBALMOUSETRACKER_H
#define GLOBALMOUSETRACKER_H

#include <QObject>
#include <QPointF>

#include "definevaluehelper.h"

// 全局鼠标位置追踪（Windows WH_MOUSE_LL 低级钩子）
// pos 为逻辑屏幕坐标（已除以 devicePixelRatio）
class GlobalMouseTracker : public QObject
{
    Q_OBJECT

    DEFINE_VALUE(QPointF, pos, {})

public:
    static GlobalMouseTracker *instance();
    ~GlobalMouseTracker();

    // 由钩子回调调用，外部不要直接调用
    void updatePos(double x, double y);

private:
    explicit GlobalMouseTracker(QObject *parent = nullptr);

    static GlobalMouseTracker *s_instance;

#ifdef _WIN32
    void installHook();
    void removeHook();
    static void *s_hook;   // HHOOK，用 void* 避免 windows.h 污染头文件
#endif
};

#endif // GLOBALMOUSETRACKER_H
