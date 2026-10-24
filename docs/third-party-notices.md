# 第三方组件与本地包说明

Tilo v0.1及1.0.0-rc.1运行时使用Qt 6.10.2：Core、Gui、Qml、Quick、QuickControls2、Widgets、Sql、Network及其QML运行模块。SQLite由Qt的QSQLITE插件提供，未引入云SDK、遥测或额外业务依赖。MinGW运行时为libgcc、libstdc++、winpthread，随本地Windows包复制所需DLL。

图标由本项目QPainter/QML绘制或使用系统字体中的基础字符，字体由操作系统提供；未复制Things、Apple字体或SF Symbols资源。

在开发者机器上生成的 Windows 候选包可能附带所用 Qt Kit 的 SBOM 副本以便逐项核对；SBOM 的存在不代表许可审查已完成。**公开再分发许可尚未核实，本地验证包不代表已获公开分发授权。** 源码仓库不包含 Qt SDK。

Qt 支持多种许可选项，具体模块及再分发条件必须按实际选择的许可确认，参考[Qt 许可说明](https://doc.qt.io/qt-6/licensing.html)、[Qt 6.10 部署](https://doc.qt.io/qt-6.10/deployment.html)。本项目源码以 [MIT 许可](../LICENSE)发布；该许可不覆盖 Qt 运行库本身。

预备 CI 中的 `actions/checkout` 与 `install-qt-action` 为 MIT 许可，仅用于安装指定 Qt 与构建；决策见 [ADR-011](ADR/011-release-and-recurrence.md)。

UI-12增加Tilo原创日历勾选应用标识，SVG/PNG/ICO/ICNS均由仓库脚本与系统Drawing API生成，无下载素材或新增运行时依赖。与项目源码一并维护，不将资产生成视为公开许可已完成。
