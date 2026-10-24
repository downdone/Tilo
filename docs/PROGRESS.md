# Tilo 实施进度

> 本文件只记录当前状态与可复现结论。本机路径、交付包文件名与校验和、构建目录、提交哈希等仅对单台机器有意义的证据保存在开发者本地的 `local/` 目录（已被 `.gitignore` 排除），不进入版本库。

## 当前目标与范围

当前目标是 **V1.0 正式版**：Windows/macOS 双平台可用、离线、无账号的本地任务与日历应用。V1.0 发布前必须完成的功能范围见 [产品规格](01_PRODUCT_SPEC.md)、[里程碑](milestones.md) 与 [需求审计](v1-feature-matrix.md)；平台验收状态见 [平台矩阵](platform-test-matrix.md)；发布范围与验收口径见 [ADR-016](ADR/016-v1-release-scope.md)。

### V1.0 独立评审与修复（DONE；平台门禁见下）

对 `1.0.0-rc.2` 状态做了一次只读独立评审（功能定义、UI/UX 对 HIG 的符合度、发布就绪性），结论为：作为 Windows 本地预览可通过，按 PRD 的 V1.0 定义不合格。评审报告不进入版本库，结论与处置记录在本节。

已修复（本轮）：

- **事件删除确认不可执行**：`EventDialog.qml` 的删除确认声明了 `onAccepted` 却没有按钮，用户无法完成删除。改为显式「保留日程 / 删除日程」页脚，删除按钮使用危险色。
- **破坏性确认的默认动作不安全**：所有删除、替换数据、恢复快照、停止规则、移动日期的确认框原先使用 `Ok|Cancel` 标准按钮，接受按钮既是最醒目样式又是回车默认动作，与 `ui-baseline` 的“破坏性操作不作为默认 Enter 动作”冲突。全部改为显式页脚：默认焦点与回车落在安全选项上，破坏动作使用危险色且不设为主按钮。
- **数据库不可用时无法恢复**：打开或完整性检查失败会令 `m_ready=false`，此后所有命令静默失败，包括应用内的快照恢复路径；`databaseIntegrity`、`databaseOpen`、`databaseRead`、`databaseConfigure`、`migrationFailed`、`dataDirectory`、`checklistInvalid`、`catalogInvalid`、`orderInvalid` 也未映射，用户只能看到笼统的数据库错误。现补充这些错误的可操作文案，新增 `dataDirectory()`、`availableSnapshots()`、`restoreFromFile()`，并在错误提示旁提供「恢复备份…」入口；恢复命令是唯一允许在非就绪状态下执行的操作族，且始终整体替换（不对备份做增量合并）。损坏库的恢复路径由 `corruptDatabaseCanStillBeRestoredFromSnapshot` 用真实损坏文件与快照覆盖。
- **关闭提示会把用户困住**：首次关闭到托盘的提示只有一个按钮，其关闭依赖偏好写入成功；只读配置或磁盘满时无法关闭也无法退出。现在提示包含「知道了，隐藏主窗口」与「退出 Tilo」，且不依赖写入结果。
- **版本与发布元数据**：`TILO_VERSION` 提升为 `1.0.0`；打包脚本的 scope 由本地候选改为 release；新增 `LICENSE`（MIT）、[1.0.0 发行说明](release-notes-v1.0.md) 与 [ADR-016](ADR/016-v1-release-scope.md)。
- **CI 工具链**：原 CI 安装 MSVC Qt 却使用写死 MinGW 编译器的预设，Windows 作业无法配置。预设拆分为 `windows-base`（隐藏）、`windows-debug/release`（MinGW）与 `windows-msvc`；CI 与 Release 作业使用对应预设，并新增 macOS arm64 与 x86_64 双架构矩阵。
- **关于信息**：设置页新增版本、许可与数据目录，用户无需查文档即可定位数据文件。
- **拖动范围**：新增 C++ `moveTaskToToday`、`moveTaskTo` 与 `taskDragAllowed`，把「任意列表→侧栏今天」「拖入项目/领域」的判定收进 `TaskWorkspace`；Upcoming→今天仍走改期确认，跨视图拖动只改开始日、不复制实体。
- **行菜单与详情页一致**：行菜单补齐「标记为已取消…」「删除任务…」，与详情页共用同一确认与 8 秒撤销路径；分隔线随破坏动作可见性隐藏，`verifyMenuSpacing()` 跳过装饰性分隔线。
- **键盘可达性**：快速编辑卡的日期/截止/标签/项目/提醒进入 Tab 链并提供 Enter/空格/Escape 路径；月格事项、当天议程、桌面组件行、桌面日历的缩放与移动均可只用键盘操作；焦点环为非颜色提示（2px 描边 + 前置色条）。
- **行内卡片宿主**：`TaskRow` 的 `inlineHost` 不再随卡片可见性离开布局，避免原生后端上宿主保持 0 宽导致卡片无法排版。
- **重复规则停止确认**：`stopConfirm` 补上 `parent`/`width`，消除 `implicitWidth` 绑定循环（offscreen `warnings=true` 的根因）。

验证（本轮实测）：Debug 与 Release 各 17/17 CTest 通过；`tilo_qmllint` 与 `tilo_style_qmllint` 无诊断；颜色审计四组均无失败项；文档本地链接 65 文件通过；`QT_QPA_PLATFORM=offscreen` smoke 退出 0、`warnings=false`；Windows 原生 OpenGL 后端 Debug 3/3 与 Release 3/3 无截图运行退出 0，Release 全截图运行退出 0（116 张）。

环境限制（不得当作已通过）：验证时段主机处于 Windows 锁定会话。D3D11 后端对非前台窗口不再交换帧，脚本化原生流程会停在依赖新帧的断言（菜单间距、行内卡片宽度）。同一构建在 OpenGL 与 offscreen 下全流程通过，未修改的上一提交二进制在 D3D11 下同样失败，故判定为环境而非回归。`scripts/test-window-native.ps1` 在锁屏会话下会因此报 `Native QML startup failed`，解锁后需重跑确认。真实键鼠、IME、读屏、多屏、睡眠、8h、干净机、签名与 macOS 仍 UNVERIFIED，详见[平台矩阵](platform-test-matrix.md)。

### 构建与验证基线

- 工具链固定 Qt 6.10.2（[ADR-007](ADR/007-qt-toolchain.md)），C++20，CMake ≥ 3.24，Ninja。
- 每轮至少执行：Debug/Release 构建、CTest 全量、`tilo_qmllint` 与 `tilo_style_qmllint`、`check-ui-colors.py`、`check-docs.ps1`。
- 自动测试一律使用 `QTemporaryDir`；不访问真实用户数据库。
- Windows 原生验证使用 `QT_QPA_PLATFORM=windows`，同时覆盖有截图与无截图两类 smoke；macOS 需在实机执行后另行记录。

### REN-01：项目全面更名为 Tilo（DONE）

按 [ADR-015](ADR/015-project-rename-tilo.md) 把 CMake 项目/目标、QML 模块 URI、C++ 命名空间、Kit 环境变量、图标资源、exe、数据目录与文档品牌统一改为 Tilo。数据目录由 `applicationName`/`organizationName` 决定，现为 `Tilo/Tilo`，首次启动新建 `tilo.sqlite`（schema001 起走既有迁移链）与 `ui.ini`，等同全新安装；程序不读取、不复制、不移动 `Daymark/Daymark`。

QML 内部 `objectName` 查找键（`tiloScrollPhysics`、`tiloScrollView`、`tiloIcon`）与 `AppRuntime.cpp` 中的查找字符串同步更新，校验键值一致且行为不变。无 schema/依赖/业务语义变化。

已验证：Debug 与 Release 全量 CTest 通过；两项 qmllint 无诊断；颜色检查无失败项；文档本地链接检查通过；offscreen smoke 退出 0、双窗口、warnings=false。

### UI-20 / CAL-06A：连续日程与全局交互修订（DONE）

按[设计](design/calendar-visual-refresh.md)实现跨日连续条与分周泳道（最多三条可见，超出从当天议程访问）、长按约 350ms 拖动排序与键盘替代（Ctrl+↑/↓）、独立循环日程入口与真实实例详情、全局明快配色、有序表单行，以及提醒单层一次提交。

同时完成：侧栏三个分区独立折叠并持久化、关注范围三段单选、日期可直接为空、提醒只保留时分步进、任务记录与结束动作分组、清单手柄拖动与键盘替代、校验错误随放弃清除而存储错误保留。

验证：Debug 17/17、Release 17/17 CTest 通过；两项 qmllint 无诊断；颜色四组（浅/深 × 普通/增强）各 74 对无失败，普通文字最低 4.617:1、必要边界最低 3.369:1；文档链接检查通过。Windows 原生：Release 与 Debug 各 111 张全截图运行退出 0、双窗口、warnings=false；无截图原生 smoke Release 与 Debug 各连续 3 次退出 0。`test-window-native.ps1` 两个 preset 均 PASS；桌面层级、焦点与物理拖动仍 UNVERIFIED。

修复记录：本切片新增阶段使 271 阶段冒烟超出原 45 秒看门狗，原生无截图运行以退出 3 中断。看门狗是挂起保护而非计时断言，改为按阶段数推导的 75 秒（截图运行仍 90 秒），未放宽任何阶段断言。早前长按拖动用例存在原生后端激活与合成按键竞争，改为分帧等待激活后单次按下，保留 `dragArmed` 断言。

未包含：冻结 Release 包与本地候选包（发布流程见 [交付指南](delivery-guide.md)），以及 macOS、物理输入、读屏、多屏、8h、干净机与签名许可门禁。

### UI-19：原行展开、整理与即时反馈（DONE）

按[设计](design/inline-task-experience.md)把快速编辑改为在原任务行展开：标题、一行备注摘要与日期/截止/标签/项目/提醒五个核心图标；信息图标进入同一草稿的完整详情。多行备注在行内只显示摘要，完整内容在详情编辑。

详情固定左返回/右保存，末尾为文字型危险动作；“整理”解释项目（一个目标下的相关任务）、领域（长期职责）与标签（跨项目查找），项目或领域选择器内可直接新建，新建资料条目立即独立持久化，取消任务修改不删除已建条目。成功完成后先保存再显示 110ms 勾选与 80ms 收拢，减少动态效果可关闭。主窗菜单使用 `Popup.Item`、小窗使用 `Popup.Window`；移动可用性复用 C++ 模型判定。

验证：Debug 17/17、Release 17/17；两项 lint 无诊断；颜色检查普通文字最低 4.608:1、必要边界最低 3.261:1；文档链接检查通过。Windows 原生 235 阶段全截图 PASS。10k 任务 50 次上下可用性查询对均值 680.924μs；菜单命令 1.4643ms。

修复记录：offscreen 大字日期焦点越界与首图展开底部裁切均保留几何断言，改为编辑时关闭 ListView 自动跟随高亮并在渲染稳定后整卡/焦点揭示；`Theme` 遗漏 `pressed` 转发由 lint 捕获后修复；PNG 读回阻塞 UI 计时改为渲染信号线程计时与原子传回。

### UI-18：就近编辑与渐进呈现（DONE；快速卡形式由 UI-19 修订）

按[设计](design/direct-editing.md)实现非模态快速编辑卡、共享 `CalendarPicker`（内联与弹层复用）、日期图标快捷菜单（含当前值勾选）、`TimeField` 与 `ReminderField`。六类表单统一灰画布/白组/16 圆角；规则启用与领域归档使用开关，清单/多选保留勾选；事件与组织表单的放弃改为明确文字与危险色。

快速编辑与完整详情共用同一草稿，切换不重载；关闭、切页、主窗退出共用三选草稿保护。验证 Debug 17/17、Release 17/17、lint 无诊断、颜色 260 对与文档链接通过；Windows 原生 219 阶段全截图 PASS。

修复记录：首次快速卡原生尺寸检查 FAIL，原因是 Layout 拥有的 `implicitHeight` 不能用父布局绑定替代，正文被压为 0；改为正文提供自然 `implicitHeight` 与最小视口并保留断言。追加长备注 200% 键盘焦点用例发现日期位于正文视口外，补齐两日期聚焦时的单轴揭示后通过（阶段扩至 223）。

### UI-17：iOS 分组、圆角与开关（DONE）

按[设计](design/ios-grouped-details.md)实现灰画布/浅色白内容组/深色分组表面，详情组 16、控件 8、选中 10 圆角；开关以滑块位置与成功色表达状态，图标按今天/月亮/对比/列表/置顶/穿透/锁定/通知等语义原创绘制。今天/今晚与设置布尔值统一 `SettingSwitch`，清单/标签仍用勾选。移除顶部无单击行为的拖放伪按钮，保留真实菜单分组与拖放排序。

验证：Debug 17/17、Release 17/17、两项 lint 无诊断、颜色 260 对与文档链接通过；Windows 原生 202 阶段全截图 PASS。

### UI-16：任务详情信息架构与行布局（DONE）

按[设计](design/task-detail-layout.md)采用 `DetailSection` 连续表面与区段线，空备注自然增长；安排区同行、两日期并排、提醒归入安排；归属使用互斥单选（项目或领域），仅适用时显示分组；标签同行、步骤直接添加、关联按内容出现、页尾只读信息显式展开。单个 `TaskPatch` 仍经原 `saveTaskWithDetails`，不改 C++ 查询/服务/SQL。

验证：Debug 17/17、Release 17/17、lint 无诊断、颜色 260 对、文档链接通过；Windows 原生 202 阶段全截图 PASS，覆盖项目＋分组保存重开、领域切换清空分组、非法提醒保留旧数据与草稿、今晚激活并关注今天、展开信息跨缩放保持、宽页同行/窄栏/200% 无横向裁切。

修复记录：首次专项 FAIL 定位到“未进入今天的任务 evening 按既有业务规范化为 false”；先修订交互设计为“安排今晚”显式激活/关注，再验证实际点击与落库，未改变 QueryService 规则。

### UI-15：全界面动作图标与语义配色（DONE）

按[动作审计和配色设计](design/actions-and-color.md)集中 `ActionButton`/`IconToolButton` 的图文、名称与键盘提示；常见/低风险动作仅图标，创建/编辑/数据操作图文，确认/取消/复杂范围保留文字。语义 token 覆盖浅深与显式增强对比度，今日不再复用 danger；透明度偏好在增强时改为实色并禁用调节，附解释文字。

验证：Debug 17/17、lint 无诊断；颜色 260 对 PASS（普通文字最低 4.586:1、必要边界 3.074:1）；文档链接检查通过；Windows 原生 191 阶段全截图 PASS。

修复记录：修改清单期间 CMake 未重新生成导致 `IconToolButton` 未编入，`qml_startup` FAIL；重新生成后全测通过。

### CAL-05：系统评估与日程浏览定位（DONE）

按[浏览定位设计](design/calendar-browsing.md)实现：同日事件按全天/实例 UTC/标题/ID 稳定排序；只读预览精确校验定位键，明确实例/系列、循环与提醒，失效或删除显示空态；显式编辑进入原 CAS 表单；主窗与独立窗各自可跳转日期。无 schema 变化。

验证：Debug 17/17、Release 17/17、两项 lint 无诊断；Windows 原生 180 阶段与默认/深色 200% 截图 PASS，含 420×480 逻辑尺寸窄窗 200% 预览。

修复记录：弹层曾放在 `ColumnLayout` 下触发布局静态警告，改为置于 `ScrollView` 的非布局上下文，未压制 lint。备注滚轮探针原在同回调内立即投递事件，改为等待渲染/焦点稳定后投递，保留位移断言。

### CAL-04：月历精修、循环事件及提醒（DONE）

按[设计](design/event-series.md)与 [ADR-014](ADR/014-event-series.md) 实现 schema4、学生成规则（每天/每周/每月/每年，间隔 1–365，可选结束日）、按所属时区墙钟投影实例、非法月日/闰日/DST 不存在或歧义实例跳过、提醒（开始时/提前 5/15/30/60 分钟/1 天）、持久化去重与提醒中心；月格增加今日圆标、事件色条与重复标识。

验证：Debug 17/17、Release 17/17、两项 lint；原生 172 阶段与全截图 PASS；升级前自动创建 WAL 一致快照到 `backups/migrations`，JSON 1–4 兼容。

修复记录：DST 间隙测试 FAIL，改为先校验当地时间再 `toUTC` 并保留原用例；全天提醒导出统一 UTC。短备注滚轮曾被布局/光标回调吸回，改为手动滚动暂停自动定位。

### CAL-03：日历精修与独立桌面日历（DONE）

按[设计](design/desktop-calendar.md)新增独立桌面日历窗口，与主窗/任务小窗/Mini 同时存在；复用 `CalendarService`/`EventService`，不建第二数据库。背景不透明度 50–100%（文字保持实色）、独立置顶、隐藏/恢复、拖动与右下角缩放、几何与偏好持久化；主窗与日历均提供恢复入口。

验证：Debug 17/17、Release 17/17、两项 lint；原生 167 阶段与全截图 PASS，三窗并存/独立翻页/单独隐藏断言通过；背景 RGBA 采样符合 70% 设置。

### CAL-01/02：任务议程与本地事件关联（DONE）

按 [ADR-013](ADR/013-local-events.md) 实现当天议程直接完成/恢复、类型显示过滤、日期键盘路径、宽窄/200% 滚动与议程直达；独立事件编辑（全天日期段或定时起止＋时区）、任务与事件多对多关联、双向进入、版本冲突与草稿保护、软删与 8 秒撤销。追加 003 迁移与 schema3，JSON/一致快照向后兼容。

验证：Debug 17/17、Release 17/17、lint 无诊断；原生 114 阶段退出 0、双窗口、warnings=false。

### UI-14：Apple HIG 全界面重设计（DONE）

按[全界面设计](design/hig-redesign.md)覆盖全部既有入口：任务/规划/资料库导航与标题上下文、可操作空态；设置独立直达并分外观/桌面组件/通用；任务、组织、重复、事件、批量、数据页统一标签/分组/日期与固定提交区；日历议程、提醒中心、Floating/Mini 与共享控件同步精修。规则新建/切换/退出统一草稿保护。

验证：Debug 17/17、Release 17/17、两项 lint；连续 3 次 Release 原生与全截图 162 阶段 PASS。

修复记录：首轮严格部署因“未完成创建”2 项 FAIL，采用 `ListView cacheBuffer=0`、下拉弹层独立非零视口、取消手动滚动时的过期焦点定位后通过；另有 QML 方法重名、Flow 只读属性、确认弹窗绑定循环、星期对齐与大字导航宽度问题。

### UI-13：视觉关系及月格事项（DONE）

按[视觉系统](design/visual-system.md)定义字体/字号/布局/圆角/颜色/线框层级：普通字段使用共享 `FieldSurface`（浅填充/底线/焦点轮廓）；标题与备注为文档式无框；页面外框删除，仅停靠时保留 1DIP 分隔；正文最大 680×文字比例，宽页日期并列、窄/大字重排。紧凑月格显示实际标题与余项 +N。

验证：Debug 17/17、Release 17/17、两项 lint；原生 152 阶段 PASS。底线/填充对比 3.23/4.14，焦点/填充 5.77/6.91，次级文字/填充 5.11/7.03。

修复记录：新增标题校验缓存绑定缺少 `count` 依赖导致 FAIL，补齐后原样复跑通过。

### V-03W：Windows 离线交付验收（工程与本地部署 DONE；完整 V-03 门禁未完成）

只读目录/元数据/SHA/敏感文件校验、SDK 隔离原生测试、DLL 来源审计、ZIP 逐文件与侧车校验、版本与干净工作区守卫均已实现并有合成篡改回归。唯一 OS 运行库例外为精确的 `System32/D3DCompiler_47.dll`，其余 Qt/MinGW 来源限包内。操作见[交付指南](delivery-guide.md)。

早期阶段曾出现 Qt “未完成创建”类 FAIL 与多次失败记录，均不作为交付；当前构建干净退出，但不宣称根因已普遍修复。独立干净机、许可、签名、完整 8h/真实睡眠/多屏与 macOS 仍 UNVERIFIED。

### V-02W：Windows 稳定性与恢复基础（DONE；完整 V-02 门禁未完成）

按[设计](design/windows-stability.md)实现系统事件合并排队（时间/设置/唤醒/激活），写入期间保留一次维护请求并在结束后补做；后台维护不禁用文本表单、不清除校验错误；主窗工作区变化后恢复可达并保持隐藏/最小化状态；新增只读完整性检查、同进程隔离业务循环与 CPU/内存采样报告。

验证：Debug 16/16、Release 16/16、两项 lint、原生恢复测试 6/6；原生 148 阶段 PASS。短跑（Debug 3 循环、Release 6 循环）退出 0、无长暂停，最大事件循环延迟 383ms。资源峰值为活跃合成负载，不证明闲置 CPU、内存趋势或无泄漏。操作见[稳定性验收指南](stability-guide.md)。

### UI-12：整体精修（DONE）

统一密度与间距（32DIP 起控件、20DIP 页边、10DIP 字段间距、紧凑 8DIP）、标题 24DIP、详情默认 344DIP；任务元信息合并、Today 不重复今日标记；完成圆固定 18DIP 与 32DIP 命中区；搜索/筛选使用带中文提示的图标；原创 SVG 与多尺寸 PNG/ICO/ICNS，EXE、窗口、任务栏与托盘共用标识。

验证：Debug 17/17、Release 17/17、两项 lint；原生 152 阶段 PASS；PE 图标 8 个尺寸齐全，ICNS 结构与 7 个 PNG 块验证通过（macOS 实机未验）。

### UI-11：滚动与备注输入（DONE）

按[滚动交互](design/scroll-interaction.md)统一滚动行为：边界停止，惯性 1200DIP/s、减速度 6000DIP/s²；内容未溢出则不可滚动且不显示滚动条；备注自然增高，仅外层正文滚动；焦点已可见时不挪动，手动滚动不被吸回；下拉框/数字框不因滚轮改值。展开态小窗表头提供常驻置顶图钉，Mini 只保留摘要与展开并继承同一状态。

### UI-10：单一任务编辑面板（DONE）

按[设计](design/unified-task-editor.md)把归属/标签/清单/提醒合入同一面板，删除二级详情；宽窗并排、窄窗替换主内容；页面固定标题/返回/保存与错误区，正文单一 `ScrollView`；草稿包含未按 Enter 的清单输入，一次 `TaskPatch`/CAS/事务保存。新增 `viewSection` 模型投影避免隐藏列表时动态切换分组属性。

### UI-09：详情与工具区精修（DONE）

实现紧凑详情与渐进搜索/筛选、更多菜单、按需拖放提示、可编辑 `DateField` 与组件独立菜单窗口。无效排序在 C++ 统一判定并禁用；日期手输/选择不抢焦点、不改另一日期。

### UI-08：组件降干扰与日历关联再评估（DONE）

浮窗两排大按钮收为一排图标工具区，隐藏/打开主窗保留在菜单；Mini 图标展开；保留添加、显示/隐藏、打开主窗与穿透外部恢复，保留键盘焦点与 32DIP 命中区。日历部分先输出官方来源、现状差距与分阶段设计（即后来 CAL-01/02）。

### UI-07：全界面视觉统一（DONE）

采用独立 `TiloStyle` 控件样式与共享设计 token，覆盖主窗/详情/组织/重复/批量/数据/日期/日历/桌面组件；统一 15 类控件、`DesignTokens`、独立线性图标、固定且可换行的 `ActionBar`、分区表单与滚动正文；保留原生系统对话框与托盘。

### V1-RC：Windows V1 候选版（DONE：候选范围）

完成六视图、组织体系、日历、重复与提醒、桌面组件、批量操作、数据保护与备份恢复的候选闭环，见[候选设计](design/v1-candidate.md)、[需求审计](v1-feature-matrix.md)、[候选说明](release-notes-v1-rc.md)。追加 002 迁移（升级前 WAL 一致快照、备份失败阻止迁移），JSON 兼容 schema1 输入。

### UI-03A / M3-01：响应式详情（DONE）

宽窗右侧停靠、窄窗覆盖主内容；不复制编辑状态，不改数据模式与业务查询；共享草稿宽窄往返不丢失，取消/放弃/保存后导航语义一致。

## 恢复入口

先读本文件、[文档导航](README.md)、[里程碑](milestones.md)与 [ADR 索引](ADR/README.md)。当前状态以本文件为准；平台真实验收状态以[平台矩阵](platform-test-matrix.md)为准，不得把自动测试或合成流程当作物理输入、辅助技术或干净机验收。

发布与推送由用户显式授权后执行，见 `docs/engineering.md` 的结束切片步骤。