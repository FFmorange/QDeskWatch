#include "marketstub.h"

#include <QDateTime>
#include <QVariantList>

MarketStub::MarketStub(QObject *parent) : MarketServiceBase(parent)
{
    refresh();
}

void MarketStub::refresh()
{
    set_loading(false);
    set_errorMsg(QStringLiteral("market_plugin_unavailable"));
    set_lastUpdated({});

    set_sseAvailable(false);
    set_sseName(QStringLiteral("上证指数"));
    set_ssePrice(0.0);
    set_sseChange(0.0);
    set_sseChangePct(0.0);
    set_sseUpdatedAt({});
    set_sseStatus(QStringLiteral("invalid"));
    set_sseChartAvailable(false);
    set_sseChartPoints(QVariantList{});
    set_sseChartUpdatedAt({});

    set_goldAvailable(false);
    set_goldName(QStringLiteral("国内金价"));
    set_goldPrice(0.0);
    set_goldChange(0.0);
    set_goldChangePct(0.0);
    set_goldUpdatedAt({});
    set_goldStatus(QStringLiteral("invalid"));
    set_goldChartAvailable(false);
    set_goldChartPoints(QVariantList{});
    set_goldChartUpdatedAt({});
}