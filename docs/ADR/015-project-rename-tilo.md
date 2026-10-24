# ADR-015：项目更名为 Tilo

日期：2026-10-24。状态：已接受，用户明确要求全面改名。

## 背景和决策

项目此前使用暂定代号 Daymark（PRD 亦注明为暂当代号）。用户要求将整个项目更名为 Tilo。本轮执行一次性整体改名，不保留代码层的旧品牌别名：

| 范围 | 旧 | 新 |
|---|---|---|
| 产品名/文档标题 | Daymark | Tilo |
| CMake 项目与目标 | `daymark`、`daymark_core`、`daymark_style` | `tilo`、`tilo_core`、`tilo_style` |
| QML 模块 URI | `Daymark`、`DaymarkStyle` | `Tilo`、`TiloStyle` |
| C++ 命名空间 | `daymark` | `tilo` |
| Kit 环境变量 | `DAYMARK_QT`、`DAYMARK_MINGW` | `TILO_QT`、`TILO_MINGW` |
| 可执行文件/图标/资源 | `daymark.exe`、`daymark-*.png`、`/daymark/icons` | `tilo.exe`、`tilo-*.png`、`/tilo/icons` |
| 用户数据目录 | `%APPDATA%/Daymark/Daymark` | `%APPDATA%/Tilo/Tilo` |
| 数据库文件 | `daymark.sqlite` | `tilo.sqlite` |
| 设置文件 | `ui.ini` | 不变 |

QML 内部 `objectName`（原 `daymarkScrollView`、`daymarkScrollPhysics`、`daymarkIcon`）与任务属性 `showTodayMarker` 是控件查找键；这些查找键一并改为 `tilo*`，并在同一提交内同步 C++ 侧查找字符串，避免残留旧品牌标识。

## 数据目录：新建，不迁移

`QStandardPaths::AppDataLocation` 由 applicationName/organizationName 决定，改名后即为全新的 `Tilo/Tilo` 目录。用户明确决定 **不做旧库迁移**：

- Tilo 首次启动在 `Tilo/Tilo` 下新建 `tilo.sqlite`（schema001 起走既有迁移链）与 `ui.ini`，相当于全新安装。
- 程序不读取、不复制、不移动 `Daymark/Daymark`；不显示迁移提示，也不因旧库存在而改变启动流程。
- 旧目录由用户自行决定保留或删除。需要旧数据时，可在退出两版程序后手工把旧库复制到新目录（旧库文件名需改为 `tilo.sqlite`），或使用旧版导出的 JSON 再导入。
- 两版程序的数据目录、锁文件与本地套接字名都不同，因此可能同时运行；这是有意为之，不是缺陷。

## 后果

- 历史候选包名称中的旧品牌、以及它们当时的校验和，属于既有证据，文档中保持原样不改写；具体的包文件名与校验值只保留在开发者本地记录中，不进入版本库。
- 不新增依赖、不改变业务行为、schema 与 SQL 不变；本轮只做改名。
- 仓库名称与托管地址在版本控制平台侧维护，不属于源码内容。