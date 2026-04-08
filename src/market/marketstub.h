#pragma once

#include "market/marketservicebase.h"

class MarketStub final : public MarketServiceBase
{
    Q_OBJECT

public:
    explicit MarketStub(QObject *parent = nullptr);

    Q_INVOKABLE void refresh() override;
};
