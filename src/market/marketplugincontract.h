#pragma once

#include <QObject>

namespace MarketPluginContract {

inline constexpr char AbiVersion[] = "QDeskWatch.Market/1.1";
inline constexpr char AbiFunctionName[] = "qdwMarketPluginAbi";
inline constexpr char CreateFunctionName[] = "qdwCreateMarketService";

#if defined(Q_OS_WIN)
inline constexpr char FileName[] = "QDeskWatchMarket.dll";
#elif defined(Q_OS_MACOS)
inline constexpr char FileName[] = "libQDeskWatchMarket.dylib";
#else
inline constexpr char FileName[] = "libQDeskWatchMarket.so";
#endif

using AbiFn = const char *(*)();
using CreateFn = QObject *(*)(QObject *parent);

}  // namespace MarketPluginContract