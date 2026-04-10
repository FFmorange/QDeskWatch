# QDeskWatch 文件结构

更新日期：2026-04-11

本文档按“源码优先、生成物折叠”的方式整理当前仓库结构，便于快速判断代码落点、调用链和职责边界。

- 已展开主工程源码、QML、资源、私有市场插件、打包、CI 与项目内 skill。
- `.qtcreator/` 属于 IDE 本地配置目录，这里不展开。
- `build/` 属于本地编译产物目录，这里不展开。
- `install/` 与 `plugins/market/` 主要作为安装/部署结果目录，仅保留关键层级。
- `.git/` 作为版本库元数据目录，不在本文档中展开。
- `resources/fonts/`、`resources/gifs/`、`resources/images/` 当前目录存在，但未展开具体文件。

```text
QDeskWatch/
|-- .github/
|   `-- workflows/
|       `-- windows-ci.yml                  # Windows CI：dev/PR 构建校验，release 打包与发布
|-- .qtcreator/
|   `-- ...                                 # IDE 本地配置目录，这里不展开
|-- build/
|   `-- Desktop_Qt_6_10_2_MSVC2022_64bit-Release/
|       `-- ...                             # 编译产物目录，这里不展开
|-- docs/
|   `-- project-file-structure.md           # 当前项目结构文档
|-- install/
|   |-- bin/
|   |-- plugins/
|   |-- qml/
|   `-- translations/                      # 安装/部署产物
|-- packaging/
|   `-- windows/
|       |-- QDeskWatch.iss                 # Inno Setup 安装脚本，打包 install/ 并附带 VC++ 运行库安装
|       `-- qdeskwatch.rc.in               # Windows 资源文件模板，注入程序图标
|-- plugins/
|   `-- market/
|       |-- .gitkeep
|       `-- QDeskWatchMarket.dll           # 公共目录中的市场插件产物/回退分发文件
|-- private-modules/
|   `-- market-plugin/
|       |-- CMakeLists.txt                 # 私有市场插件构建、复制到运行目录和 install 目录
|       `-- src/
|           |-- marketmanager.h            # 市场插件服务声明，定义刷新流程和数据解析辅助方法
|           |-- marketmanager.cpp          # 市场插件主实现，拉取上证指数与国内金价并组装图表数据
|           `-- marketpluginentry.cpp      # 插件导出入口，暴露 ABI 与 service 创建函数
|-- qml/
|   |-- apps/
|   |   |-- market/
|   |   |   |-- MarketApp.qml              # 行情应用主视图，负责列表页和详情页切换
|   |   |   |-- MarketDetailView.qml       # 单个资产详情页，展示价格、涨跌和日内走势
|   |   |   |-- MarketRow.qml              # 行情列表卡片组件
|   |   |   `-- MarketTrendChart.qml       # Canvas 趋势图组件，绘制日内折线和填充区域
|   |   `-- memo/
|   |       |-- MemoApp.qml                # 备忘录应用入口，仅承载 MemoList
|   |       |-- MemoList.qml               # 备忘录核心界面，处理列表、分组、编辑、删除、新增和提醒时间
|   |       |-- MoodPicker.qml             # 心情 GIF 选择器组件
|   |       `-- TimeEntryControl.qml       # 时间输入控件，支持键盘/滚轮选择提醒时间
|   |-- common/
|   |   |-- AppHost.qml                    # 应用容器，按 AppShell 状态加载 launcher 或具体 app
|   |   |-- AppLauncher.qml                # 启动器网格，负责应用入口图标和交互动画
|   |   |-- BreathLight.qml                # Canvas 版呼吸灯边框，距离提示实验组件
|   |   |-- CrownButton.qml                # 表冠按钮，支持点击返回 launcher 和滚轮切换应用
|   |   |-- DistanceBar.qml                # 距离分段条组件
|   |   |-- DistanceSlider.qml             # 距离滑块组件
|   |   |-- DistanceTip.qml                # 组合 GlowRing/DistanceSlider/DistanceBar 的距离提示容器
|   |   |-- FlipText.qml                   # 翻页数字组件，用于秒钟翻转动画
|   |   |-- GlowRing.qml                   # SVG 版发光环组件，按距离区间切换光效
|   |   `-- LocationLabel.qml              # 城市标签组件，显示定位城市名和图标
|   |-- singletons/
|   |   |-- AppShell.qml                   # 全局应用状态单例，维护 app 注册表、当前模式和切换逻辑
|   |   |-- PropertySingleton.qml          # 全局缩放单例，CMake 中注册别名为 `PS`
|   |   `-- Theme.qml                      # 主题单例，读取 default.theme 并解析图标资源路径
|   `-- watchface/
|       |-- DateTime.qml                   # 表盘右上角日期/时间组件，含秒钟翻转动画
|       |-- EyeFace.qml                    # 眼睛表情组件，跟随鼠标位置移动
|       |-- TemperatureGauge.qml           # 温度弧形表盘，显示最低/最高/当前温度
|       |-- WatchFace.qml                  # 主表盘布局，组合时间、天气、眼睛、应用区和表冠
|       `-- WeatherIcon.qml                # WMO 天气代码到图标的映射组件
|-- resources/
|   |-- app-icon/
|   |   |-- qdeskwatch.ico                # Windows 应用图标
|   |   |-- qdeskwatch.png                # 位图图标资源
|   |   `-- qdeskwatch.svg                # 矢量图标资源
|   |-- icons/
|   |   |-- glow_far.svg                  # 远端蓝色光环
|   |   |-- glow_mid.svg                  # 中段青绿色光环
|   |   |-- glow_near.svg                 # 近端橙色光环
|   |   |-- location_ground_arrow_classic.svg  # 定位标签图标
|   |   |-- market_board.svg              # 行情应用图标
|   |   |-- memo_alarm.svg                # 备忘录提醒图标
|   |   |-- memo_checklist.svg            # 备忘录列表图标
|   |   |-- memo_note.svg                 # 备忘录便签图标
|   |   |-- resize_normal.svg             # 普通态缩放/拖拽图标
|   |   |-- resize_pressed.svg            # 按下态缩放/拖拽图标
|   |   |-- weather_clear.svg             # 晴天图标
|   |   |-- weather_drizzle.svg           # 毛毛雨图标
|   |   |-- weather_fog.svg               # 雾天图标
|   |   |-- weather_overcast.svg          # 阴天图标
|   |   |-- weather_partly_cloudy.svg     # 晴间多云图标
|   |   |-- weather_rain.svg              # 雨天图标
|   |   |-- weather_shower.svg            # 阵雨图标
|   |   |-- weather_sleet.svg             # 雨夹雪图标
|   |   |-- weather_snow.svg              # 雪天图标
|   |   |-- weather_snow_shower.svg       # 阵雪图标
|   |   `-- weather_thunderstorm.svg      # 雷暴图标
|   `-- default.theme                     # 主题默认配置，声明图标目录与格式
|-- skills/
|   |-- document-sync-review/
|   |   |-- SKILL.md                      # 文档同步审查 skill
|   |   `-- agents/
|   |       `-- openai.yaml               # 文档同步审查 skill 的 UI 元数据
|   |-- project-file-search/
|   |   |-- SKILL.md                      # 项目文件检索 skill
|   |   `-- agents/
|   |       `-- openai.yaml               # 项目文件检索 skill 的 UI 元数据
|   `-- skill-sync-review/
|       |-- SKILL.md                      # skill 同步审查 skill
|       `-- agents/
|           `-- openai.yaml               # skill 同步审查 skill 的 UI 元数据
|-- src/
|   |-- definevaluehelper.h               # Q_PROPERTY 宏辅助，给 QObject 快速生成 getter/setter/signal
|   |-- dumpcatcher.cpp                   # Windows 崩溃转储实现，写出 minidump
|   |-- dumpcatcher.h                     # 崩溃转储接口声明
|   |-- globalmousetracker.cpp            # Windows 低级鼠标钩子实现，向 QML 提供全局鼠标坐标
|   |-- globalmousetracker.h              # 全局鼠标追踪单例声明
|   |-- logger.cpp                        # 日志实现，接管 Qt/QML 输出并写入缓存目录
|   |-- logger.h                          # 日志单例声明，同时暴露给 QML 使用
|   |-- manager/
|   |   |-- weathermanager.cpp            # 天气管理实现：先 IP 定位，再请求 Open-Meteo 天气
|   |   `-- weathermanager.h              # 天气管理声明，暴露表盘所需天气属性
|   `-- market/
|       |-- marketplugincontract.h        # 市场插件 ABI、导出函数名和动态库文件名约定
|       |-- marketpluginloader.cpp        # 市场插件加载器，按候选路径加载插件，失败时回退 stub
|       |-- marketpluginloader.h          # 市场插件加载器声明
|       |-- marketservicebase.h           # 市场服务抽象基类，统一 QML 可绑定属性和 refresh 接口
|       |-- marketstub.cpp                # 市场服务回退实现，插件不可用时返回空状态
|       `-- marketstub.h                  # 市场服务回退声明
|-- .gitignore                            # Git 忽略规则
|-- AGENTS.md                             # 项目协作规范
|-- CMakeLists.txt                        # 主工程构建入口，注册 QML 模块、单例、资源和市场插件接入方式
|-- LICENSE                               # 许可证文件
|-- Main.qml                              # 顶层 QML 窗口，负责无边框窗口和拖拽移动
`-- main.cpp                              # 程序入口，初始化日志/崩溃捕获/系统托盘并注入 QML 上下文对象
```

## 关键链路

- 启动链路：`CMakeLists.txt` 注册 `QDeskWatch` QML 模块与单例，`main.cpp` 创建 `QApplication`、安装日志与崩溃捕获、注入 `$marketMgr` / `$weatherMgr` / `$mouseMgr`，再加载 `Main.qml`，最终进入 `qml/watchface/WatchFace.qml`。
- 表盘链路：`WatchFace.qml` 负责主布局，时间来自 `DateTime.qml`，天气展示由 `TemperatureGauge.qml` 和 `WeatherIcon.qml` 组成，鼠标互动表情由 `EyeFace.qml` 完成。
- 应用切换链路：`qml/singletons/AppShell.qml` 维护应用注册表和当前模式，`qml/common/AppLauncher.qml` 展示入口网格，`qml/common/AppHost.qml` 根据状态加载具体应用。
- 备忘录链路：`qml/apps/memo/MemoApp.qml` 进入 `MemoList.qml`，时间输入依赖 `TimeEntryControl.qml`，心情选择依赖 `MoodPicker.qml`。
- 天气链路：`src/manager/weathermanager.cpp` 先通过 `ipapi.co` 获取定位，再访问 `api.open-meteo.com` 拉取天气数据，结果通过 `$weatherMgr` 提供给 QML。
- 市场链路：`src/market/marketpluginloader.cpp` 按 ABI 约定加载 `QDeskWatchMarket.dll`，成功则进入 `private-modules/market-plugin/src/marketmanager.cpp`，失败则回退到 `src/market/marketstub.cpp`；QML 侧入口是 `qml/apps/market/MarketApp.qml`。
- 打包链路：`packaging/windows/qdeskwatch.rc.in` 为主程序注入图标资源，`packaging/windows/QDeskWatch.iss` 以 `install/` 为输入构建安装包，`.github/workflows/windows-ci.yml` 在 release 分支执行构建、安装、压缩、安装包生成与 GitHub Release 发布。

## 快速定位建议

- 想找程序入口、上下文注入、系统托盘：看 `main.cpp`。
- 想找顶层窗口和表盘布局：看 `Main.qml`、`qml/watchface/WatchFace.qml`。
- 想找应用切换与 launcher：看 `qml/singletons/AppShell.qml`、`qml/common/AppHost.qml`、`qml/common/AppLauncher.qml`。
- 想找天气数据来源和字段：看 `src/manager/weathermanager.*`。
- 想找市场插件协议、加载与降级：看 `src/market/`；想找真实行情抓取逻辑：看 `private-modules/market-plugin/src/marketmanager.cpp`。
- 想找备忘录主要交互：先看 `qml/apps/memo/MemoList.qml`。
- 想找行情 UI：先看 `qml/apps/market/MarketApp.qml`，再看 `MarketDetailView.qml` 和 `MarketTrendChart.qml`。
- 想找图标或主题映射：看 `resources/default.theme` 与 `qml/singletons/Theme.qml`。
- 想找项目内可复用方法：看 `skills/` 下各 skill 的 `SKILL.md`。
