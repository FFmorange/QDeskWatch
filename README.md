# QDeskWatch

⌚ 一个参考 Apple Watch / iWatch 视觉语言的 PC 端桌面助手项目，基于 `Qt 6`、`QML / Qt Quick`、`C++17` 与 `CMake` 构建。

## ✨ 项目简介

`QDeskWatch` 以桌面常驻小部件的形式运行，采用无边框、置顶、接近表盘式的交互布局，目标是在 PC 端复现类似 Apple Watch 的视觉语言与轻应用体验。

当前版本主要包含这些能力：

- 🕒 表盘主界面与桌面悬浮窗口
- 🌤 日期、时间、天气与动态表情展示
- 📝 备忘录与提醒输入
- 📈 行情展示与趋势图
- 🖥 系统托盘显示、隐藏与退出控制
- 📦 Windows 打包与 CI 流程

## 🛠 技术栈

- `Qt 6`
- `QML / Qt Quick`
- `C++17`
- `CMake`
- `Inno Setup`
- `GitHub Actions`

## 🚀 本地编译

推荐环境：

- Windows 10 / 11
- Visual Studio 2022
- Qt `6.10.2` MSVC 64-bit Kit
- CMake `3.16+`

项目最低要求：

- `Qt 6.8+`
- `C++17`

获取源码并进入项目目录后，执行：

```powershell
git clone git@github.com:FFmorange/QDeskWatch.git
cd QDeskWatch

cmake -S . -B build
cmake --build build --config Release --parallel
cmake --install build --config Release --prefix "$((Get-Location).Path)/install"
```

安装完成后，可从下面的位置启动：

```powershell
.\install\bin\QDeskWatch.exe
```

## 📦 打包与 CI

- `dev` 分支和针对 `dev` 的 Pull Request 会触发 Windows 构建校验
- `release` 分支会触发 Release 打包流程
- Windows 安装包基于 `Inno Setup` 生成
- 当前 CI 主要承担构建、安装与产物发布流程

相关文件：

- [packaging/windows/QDeskWatch.iss](packaging/windows/QDeskWatch.iss)
- [packaging/windows/qdeskwatch.rc.in](packaging/windows/qdeskwatch.rc.in)
- [.github/workflows/windows-ci.yml](.github/workflows/windows-ci.yml)

## 📚 文档

如果你想继续了解项目结构和协作规则，可以查看：

- [docs/project-file-structure.md](docs/project-file-structure.md)
- [AGENTS.md](AGENTS.md)
- [skills/](skills/)

## ⚠️ 法律与合规说明

- 本项目主要用于学习、研究与技术交流。
- 本项目不构成任何投资建议、商业承诺或合规背书。
- 使用、修改、分发、部署或基于本项目开展二次开发时，请自行确保符合你所在地区适用的法律法规，以及相关平台规则、第三方服务条款、数据来源授权和知识产权要求。
- 若将本项目用于商业、生产或公开服务场景，使用者应自行评估并承担由此产生的合规、数据、隐私、安全及其他法律责任。
- 项目作者不鼓励将本项目用于任何违法、违规或侵害第三方合法权益的用途。
- 本说明仅用于阐明项目定位与使用边界，不构成法律意见，也不当然免除实际使用者依法应承担的责任。

## 📄 License

本项目采用 `MIT License` 许可协议。

在保留原始许可声明的前提下，你几乎可以自由地使用、修改、分发、再发布，或用于其他你想要的用途。

见 [LICENSE](LICENSE)。
