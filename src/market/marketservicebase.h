#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

#include "definevaluehelper.h"

class MarketServiceBase : public QObject
{
    Q_OBJECT

    DEFINE_VALUE(bool,    loading,      false)
    DEFINE_VALUE(QString, errorMsg,     {})
    DEFINE_VALUE(QString, lastUpdated,  {})

    DEFINE_VALUE(bool,    sseAvailable, false)
    DEFINE_VALUE(QString, sseName,      {})
    DEFINE_VALUE(double,  ssePrice,     0.0)
    DEFINE_VALUE(double,  sseChange,    0.0)
    DEFINE_VALUE(double,  sseChangePct, 0.0)
    DEFINE_VALUE(QString, sseUpdatedAt, {})
    DEFINE_VALUE(QString, sseStatus,    {})
    DEFINE_VALUE(bool,    sseChartAvailable, false)
    DEFINE_VALUE(QVariantList, sseChartPoints, {})
    DEFINE_VALUE(QString, sseChartUpdatedAt, {})

    DEFINE_VALUE(bool,    goldAvailable, false)
    DEFINE_VALUE(QString, goldName,      {})
    DEFINE_VALUE(double,  goldPrice,     0.0)
    DEFINE_VALUE(double,  goldChange,    0.0)
    DEFINE_VALUE(double,  goldChangePct, 0.0)
    DEFINE_VALUE(QString, goldUpdatedAt, {})
    DEFINE_VALUE(QString, goldStatus,    {})
    DEFINE_VALUE(bool,    goldChartAvailable, false)
    DEFINE_VALUE(QVariantList, goldChartPoints, {})
    DEFINE_VALUE(QString, goldChartUpdatedAt, {})

public:
    explicit MarketServiceBase(QObject *parent = nullptr) : QObject(parent) {}
    ~MarketServiceBase() override = default;

    Q_INVOKABLE virtual void refresh() = 0;
};