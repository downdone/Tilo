# Tilo

离线优先的跨平台任务管理与日历桌面应用。C++20 + Qt 6.10.2 / Qt Quick + SQLite，Windows 与 macOS。

无账号、无云端、无遥测；所有核心操作在断网时可用，数据保存在本机。

## 功能

- **收集与规划**：收集箱、今天、即将到来、随时可做、以后再说、已完成六视图；持续关注今天、今晚分组、独立的列表排序。
- **组织**：领域、项目、分组（Heading）、标签、检查清单；项目与领域互斥归属，删除项目保留任务。
- **日历**：月/周视图与当天议程，任务开始/截止标记合并与拆分，跨日连续日程色条，独立桌面日历窗口。
- **事件**：本地全天或定时事件、循环规则、提醒；事件与任务多对多关联。
- **重复**：按天/周/月/年在指定星期、日序或固定月日重复，完成后 N 天；幂等实例与手改保护。
- **提醒**：任务与事件提醒，应用内提醒中心与系统通知，持久化去重。
- **桌面组件**：透明浮窗与 Mini 模式、置顶、锁定、鼠标穿透（可经托盘或设置恢复）。
- **数据保护**：WAL 一致快照备份、JSON/CSV 导出、验证预览后的事务导入、软删与撤销。
- **界面**：浅/深/跟随系统主题、100%–200% 文字、增强对比度、完整键盘通路；设计依据 Apple HIG，实现与资源均为本项目独创。

## 构建

前置：CMake ≥ 3.24、Ninja、Qt 6.10.2（含 Quick、QuickControls2、Sql、Test）。

```bash
# Windows（PowerShell 7）
$env:TILO_QT = '<Qt根目录>/6.10.2/mingw_64'
$env:TILO_MINGW = '<Qt根目录>/Tools/mingw1310_64'
./scripts/build-windows.ps1              # 或 -Preset windows-release
./scripts/test-windows.ps1

# macOS
export TILO_QT='<Qt安装目录>/6.10.2/macos'
bash scripts/build-macos.sh macos-debug
```

也可直接使用 CMake 预设：`cmake --preset windows-debug`、`cmake --build --preset windows-debug`、`ctest --preset windows-debug`。

详细环境、脚本与诊断说明见[环境与构建](docs/environment.md)。

## 测试

17 个 CTest 目标覆盖 SQLite 运行时、任务/目录/日历/事件/重复/提醒服务、数据导入导出、性能、单实例、窗口状态与 QML 启动流程。全部自动测试使用 `QTemporaryDir`，不接触用户数据库。

```bash
ctest --preset windows-debug
cmake --build --preset windows-debug --target tilo_qmllint
python scripts/check-ui-colors.py
```

## 文档

- [文档导航](docs/README.md)、[当前进度](docs/PROGRESS.md)、[里程碑](docs/milestones.md)
- [产品规格](docs/01_PRODUCT_SPEC.md)、[技术设计](docs/02_TECHNICAL_DESIGN.md)、[实施计划](docs/03_IMPLEMENTATION_PLAN.md)
- [架构决策记录](docs/ADR/README.md)、[平台验证矩阵](docs/platform-test-matrix.md)
- [使用说明](docs/user-guide.md)、[交付与校验](docs/delivery-guide.md)、[第三方组件](docs/third-party-notices.md)

## 状态与边界

Windows 已通过自动化测试与本机原生环境验证；**macOS 尚未在实机完成构建与人工验收**，相关项目在[平台矩阵](docs/platform-test-matrix.md)中保持 `UNVERIFIED`。真实系统通知送达、物理输入设备、读屏、多屏与 DPI 切换、8 小时连续运行与独立干净机部署同样需要人工验收，自动化测试不能替代。

## 许可

源码以 [MIT 许可](LICENSE)发布。运行时使用的 Qt 6.10.2 有独立许可条款，再分发前请阅读[第三方组件说明](docs/third-party-notices.md)。