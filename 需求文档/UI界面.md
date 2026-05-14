# 《无尽仙台》UI 界面规范

## 一、技术栈

- **引擎**：Godot 4.3+
- **渲染**：Forward Plus
- **分辨率基准**：1280×720（16:9），支持 1600×900 / 1920×1080 / 2560×1440
- **拉伸模式**：canvas_items + expand（UI 整体等比缩放）

---

## 当前菜单二次美术重做（2026-05-13）

本轮以“玉白鎏金云青 · 登仙台祭坛”为准，覆盖旧版“左侧琉璃入口面板”的视觉描述。

- `MainMenu`：仍使用 `assets/bg/menu.png`，但 `MenuPanel` 只作为中央祭坛布局容器，不再绘制大黑面板。标题、云纹分隔、法印光环、说明框与三枚平直玉条按钮居中叠在登仙台路径上；不再显示“登仙台 · 第一轮回”与“方向键选择 · Enter 确认”，底部不再使用硬切黑色遮罩。`BtnStart`、`BtnOptions`、`BtnExit` 仍为 Button，跳转逻辑不变；三个按钮默认均为青玉态，键盘焦点只显示透明细金边，鼠标悬浮时才显示高亮金色填充，文字必须保持清晰可读。
- `CharacterSelect`：仍使用 `assets/bg/wanjianmen.png`，重排为“程天锋登台”。左侧只保留轻量弟子入口，中间 `PortraitStage` 展示程天锋舞台，右侧 `StatsCard` 使用资质图标牌与两枚玉简展示天赋/技能；`SectBar`、`CharListBox`、`Portrait`、`CharName`、`TalentDesc`、`SkillDesc`、`StartBtn` 等节点名保持不变。
- `OptionsMenu`：改为宽版深玉设置面板（水平 20%–80%），显示区保留“显示模式 + 分辨率”：显示模式包含窗口化、无边框窗口、全屏，继续保留三路音量、语言、应用、返回控件。面板使用高不透明墨玉底、细金边、固定标签/控件/数值列与居中操作按钮，语言区行标签为“界面语言”，不再重复“语言 / Language”。
- 新增资产：`assets/ui/menu/*.png`（玉板、玉简、牌匾按钮、云纹分隔、资质图标、法印光环）与 `assets/portraits/chen_tianfeng_cutout.png`。文字仍由 Godot Label/Button 渲染，图片不烘焙文案。
- 窗口体验：项目默认 `display/window/size/borderless=false`，以标准窗口化启动并显示 Windows 标题栏按钮；`GlobalSettings.display_mode` 统一管理窗口化、无边框窗口、全屏三种模式，旧字段 `fullscreen` / `borderless_window` 仅作为兼容镜像保存。旧配置迁移时保留玩家显式选择过的全屏，隐藏的旧版无边框默认不再自动继承。

自动化覆盖：`TestMenuScreens` 断言中央祭坛布局、新 UI 资产可加载、Options 宽版面板、语言标签去重、设置行标签列对齐、项目默认标准窗口；`TestGlobalSettings` 覆盖显示模式默认值、保存读取、旧字段同步与越界截断；`TestCharacterSelect` 断言 `portrait_cutout_path` 可加载且关键节点/立绘布局接口不变。

## 二、主菜单（MainMenu）

**场景文件**：`scenes/MainMenu.tscn`
**脚本**：`scripts/MainMenu.gd`

### 布局

| 区域 | 位置（屏幕占比） | 内容 |
|------|----------------|------|
| 背景层 | 全屏 | `assets/bg/menu.png`，右侧保留云海天门主视觉，叠加暗化与柔光层 |
| MenuPanel | 水平 27.5%–72.5%，垂直 7.5%–87.5% | 中央祭坛布局容器，包含标题、说明框与按钮，不绘制大面板 |
| 标题组 | MenuPanel 内上部 | “无尽仙台”使用 Noto Serif SC 深墨字与暖金阴影，英文副标题使用 Noto Sans SC |
| 按钮区 | MenuPanel 内下部 | 三枚平直青玉按钮；键盘 focus 为透明细金边，鼠标 hover 切换到高亮金色填充，不使用锯齿牌匾轮廓 |
| 版本号 | 右下角 78%–97%，垂直 93%–98.5% | v0.x.x 小字 |

### 按钮列表

| 按钮 | 功能 |
|------|------|
| 开始游戏 | 跳转至职业选择 / 存档界面（待实现） |
| 选项 | 跳转至 OptionsMenu |
| 退出 | `get_tree().quit()` |

### 键盘导航

进入场景时焦点自动落在"开始游戏"，支持方向键上下切换，Enter 确认；界面不显示底部操作提示栏。

### 视觉与动效

- 主菜单采用“瑰丽仙宫史诗”方向，背景负责宏大云海，中央祭坛标题、说明框与平直玉条按钮负责信息秩序。
- `scripts/MenuParticles.gd` 在背景与遮罩之间绘制低密度金尘/云光粒子，只做慢速漂浮，不遮挡按钮。
- 进入场景时 `MenuPanel` 轻微上浮淡入，三个按钮依次淡入缩放，动效不改变最终布局尺寸。

---

## 三、选项界面（OptionsMenu）

**场景文件**：`scenes/OptionsMenu.tscn`
**脚本**：`scripts/OptionsMenu.gd`

### 分区

OptionsMenu 是独立“云台设置页”：使用 `assets/bg/menu.png` 全屏背景与深色遮罩，中央 `SettingsPanel`（水平 20%–80%，垂直 9.5%–90.5%）承载所有设置项。设置面板使用 Options 专用深玉高对比样式：墨玉高不透明底、细金边、柔和阴影与 Noto 字体，避免云海背景穿透正文。

设置项使用固定行网格：左侧标签列 140px，中间控件列起点对齐，音量行右侧保留 64px 百分比列。下拉控件统一 270×44，音量滑块使用厚轨道与程序化玉玺感手柄；底部“应用 / 返回”按钮统一为 150×46，同形不同权，应用为金色主按钮，返回为深玉次按钮。

#### 显示

| 设置项 | 控件 | 说明 |
|--------|------|------|
| 显示模式 | OptionButton | 窗口化 / 无边框窗口 / 全屏 |
| 分辨率 | OptionButton | 1280×720 / 1600×900 / 1920×1080 / 2560×1440 |

> 显示模式与分辨率更改需点击"应用"后生效（`apply_display()`），防止误触；选择“全屏”时分辨率选项禁用，窗口化与无边框窗口使用所选分辨率并居中。

#### 音频

| 设置项 | 控件 | 默认值 | 范围 |
|--------|------|--------|------|
| 总音量 | HSlider + 百分比标签 | 100% | 0–100% |
| 音乐音量 | HSlider + 百分比标签 | 80% | 0–100% |
| 音效音量 | HSlider + 百分比标签 | 80% | 0–100% |

> 音量拖动时立即生效（实时预览），无需点击应用。

#### 语言 / Language

| 选项 | 说明 |
|------|------|
| 中文 | locale = zh_CN |
| English | locale = en |

> 切换语言立即生效，文本通过 `TranslationServer` 热替换。

### 按钮

| 按钮 | 功能 |
|------|------|
| 应用 | 执行 `apply_display()` + `save_settings()` |
| 返回 | `save_settings()` 后返回主菜单 |

### 节点结构

```
OptionsMenu (Control)
├── BG (TextureRect)
├── Overlay (ColorRect)
└── SettingsPanel (PanelContainer) *
    └── PanelPad/Content (VBoxContainer)
        ├── PageTitle / PageSubTitle
        ├── Display -> DisplayModeOption* / ResolutionOption*
        ├── Audio -> MasterSlider* / MusicSlider* / SFXSlider* + 百分比标签
        ├── Locale -> LanguageRowLabel("界面语言") / LanguageOption*
        └── ActionRow -> BtnApply* / BtnBack*
```

> `*` = `unique_name_in_owner = true`，脚本通过 `%NodeName` 访问，避免布局调整破坏路径。

---

## 四、全局设置单例（GlobalSettings）

**脚本**：`scripts/GlobalSettings.gd`（Autoload）

**存储路径**：`user://settings.cfg`（Godot 用户数据目录，Windows 下为 `%APPDATA%\Godot\app_userdata\无尽仙台\`）

### 属性一览

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `master_volume` | float | 1.0 | Master 总线线性音量 |
| `music_volume` | float | 0.8 | Music 子总线 |
| `sfx_volume` | float | 0.8 | SFX 子总线 |
| `resolution_index` | int | 0 | RESOLUTIONS 数组下标 |
| `display_mode` | int | 0 | 0=窗口化，1=无边框窗口，2=全屏 |
| `fullscreen` | bool | false | 兼容镜像：`display_mode == 2` |
| `borderless_window` | bool | false | 兼容镜像：`display_mode == 1` |
| `language` | String | "zh_CN" | locale 代码 |

### 音频总线结构

```
Master（默认）
├── Music（BGM）
└── SFX（音效）
```

总线在 `_ensure_audio_buses()` 中运行时动态创建（无需手动配置 Godot 音频总线面板）。

---

## 五、视觉风格规范（初稿）

| 元素 | 规格 |
|------|------|
| 背景方向 | 瑰丽仙宫史诗：云海、天门、金色天光、冷青遮罩 |
| 标题主色 | 暖金白 `#FFF0BD` 附近，标题字体使用 `NotoSerifSC-Regular.otf` |
| 正文字体 | `NotoSansSC-Regular.otf`，用于按钮、正文、设置项和数值 |
| 面板 | 半透明深青黑琉璃面板 + 1px 克制金色细边 + 柔和阴影 |
| 主按钮 | 金色填充、深色文字，hover 提亮，pressed 加深 |
| 次按钮/下拉 | 深色玻璃底、金色细边、浅色文字 |
| 粒子 | 低密度金尘/云光，慢速漂浮，不遮挡标题、按钮、属性信息 |

### 共享资源

- 字体：`assets/fonts/NotoSerifSC-Regular.otf`、`assets/fonts/NotoSansSC-Regular.otf`，许可证 `assets/fonts/OFL.txt`。
- 共享样式：`scripts/ui/MenuUiStyle.gd`，提供 `apply_panel()`、`apply_button()`、`apply_heading()`、`apply_slider()` 等静态方法。
- 主题：`theme/main_theme.tres` 引用 Noto Sans SC 作为默认 UI 字体，并为 Button / OptionButton / CheckButton 等控件提供基础样式。

---

## 六、测试规范

### 测试分层要求

每个 UI 模块完成开发后，必须按以下分层提供测试：

| 层级 | 类型 | 要求 | 执行方式 |
|------|------|------|----------|
| 1 | **完整性/白盒测试** | 所有新增 `.gd` 文件必须注册到 `TestScriptIntegrity.gd`，验证脚本加载、Autoload、场景脚本引用 | `run_suite.bat TestScriptIntegrity` |
| 2 | **单元测试** | 纯逻辑函数（配置读写、计算、状态变更、数据表规则）必须有对应 suite | `run_suite.bat TestXxx` |
| 3 | **Headless 玩家旅程测试** | 基础用户流程必须验证跨场景状态承接：开局、地图、战斗、奖励、商店、事件/安全节点、pending 清理 | `run_suite.bat TestPlayerJourneyFlow` |
| 4 | **真实 UI 截图验收** | Display/Audio/视觉观感、布局遮挡、真实场景渲染用截图诊断，不作为自动 pass/fail | `capture_ui.bat <preset>` |

菜单美化专用自动化 suite：`tests/suites/TestMenuScreens.gd`，验证 MainMenu / CharacterSelect / OptionsMenu 可加载、关键节点存在、背景与字体资源可加载、设置控件与主按钮未丢失。

基础玩家流程 suite：`tests/suites/TestPlayerJourneyFlow.gd`，通过 `tests/helpers/FlowHarness.gd` 在 headless 下模拟新局、地图节点、战斗胜利、奖励领取/选卡/跳过、黑市购买、事件与篝火节点，重点检查 `GameState` 中 HP、牌组、灵石、地图可访问节点和跨场景 pending 字段不会断裂或泄漏。

涉及战斗、地图、奖励、商店、事件或角色选择的改动，除原有精准 suite 外，必须加跑 `TestPlayerJourneyFlow`。提交前仍使用 `run_regression.bat` 做全量回归。

### 已知约束

- **Autoload 调用规范**：不得在任何脚本中直接写 `Logger.info()`，必须通过 `Log.info()` 调用。
  原因：GDScript 解析器将 Autoload 名视为类引用，无法在编译期验证实例方法，导致 Parse Error。
- **headless 限制**：`TestPlayerJourneyFlow` 验证状态流和必要场景实例化，不做真实鼠标点击、动画、DisplayServer、AudioServer 或视觉观感判定；这些仍通过 `capture_ui.bat` 截图与人工验收确认。

---

## 七、角色选择界面（CharacterSelect）✅ 已优化

**场景文件**：`scenes/CharacterSelect.tscn`  
**脚本**：`scripts/CharacterSelect.gd`

### 布局

| 区域 | 位置 | 内容 |
|------|------|------|
| 背景层 | 全屏 | `wanjianmen.png` + 深色遮罩 + 顶部暗化层 |
| 页面标题 | 左上 4.5%–48%，垂直 3.5%–12% | “择一人，入登仙台”与副标题 |
| 门派选择栏 SectBar | 右上 58%–95.5%，垂直 5.5%–13% | 每个门派一个 ToggleButton，ButtonGroup 互斥 |
| MainContent | 水平 4.5%–95.5%，垂直 17%–86% | 左侧选择 / 中央立绘 / 右侧档案三块 |
| ├ SidebarPanel | 固定宽 220px | 当前门派弟子列表与提示，作为轻量切换控件 |
| ├ HeroPanel | 水平 15.5%–68%，垂直顶线与 StatsCard 对齐 | 大立绘、框内称号题签、角色名、背景故事，是单角色展示中心 |
| └ StatsCard | 水平 70%–100%，垂直顶线与 PortraitFrame 对齐 | 初始资质 / 天赋 / 英雄技能 / 开始轮回确认区 |
| StartBtn | StatsCard 内底部 | “开始轮回”，确认选择并跳转地图，填满右栏宽度但不悬浮出卡片 |

### 节点结构

```
CharacterSelect (Control)
├── BG (TextureRect)              # 全屏背景图，随门派切换
├── Overlay / TopShade            # 半透明暗化与顶部压暗
├── PageTitle / PageSubTitle      # 左上标题组
├── SectBar (HBoxContainer) *     # 门派按钮行，动态创建
├── MainContent (HBoxContainer)
│   ├── SidebarPanel/SidebarPad/CharListPanel
│   │   └── CharListBox (VBoxContainer) *      # 角色按钮，动态创建
│   ├── HeroPanel/HeroPad/CharDetailPanel
│   │   ├── PortraitFrame/PortraitMargin/PortraitStage
│   │   │   ├── Portrait (TextureRect) *
│   │   │   └── CharTitlePill/CharTitle (Label) *
│   │   ├── CharName (Label) *
│   │   └── Lore (Label) *
│   └── StatsCard/StatsPad/StatsPanel
│       ├── Stats Grid（HPValue* / HPRegenValue* / LingLiValue* / LingLiRegenValue* / DaoHuiValue* / DmgValue*）
│       ├── TalentPanel/TalentPad/TalentDesc *
│       ├── SkillPanel/SkillPad/SkillDesc *
│       └── StartBtn (Button) *          # 开始轮回
```

> `*` = `unique_name_in_owner = true`，脚本通过 `%NodeName` 访问

### 数据来源

- `CharacterDatabase.get_all_sects()` → 门派名称列表（按 `SECT_ORDER` 顺序）
- `CharacterDatabase.get_sect_data(sect)` → 门派元数据（`bg_path` 等）
- `CharacterDatabase.get_sect_characters(sect)` → 该门派所有角色列表
- `CharacterDatabase.get_character(id)` → 单个角色完整数据（含 `portrait_path`）
- `portrait_path` 必须能通过 `load(path) as Texture2D` 加载成功，角色选择界面据此刷新中央立绘。
- `CharacterSelect.tscn` 的 `Portrait` 节点默认绑定 `assets/portraits/chen_tianfeng.png`，避免场景进入后的首帧出现空白立绘。
- 初始资质中【灵力上限】与【灵力回复】分别独立成格展示；灵力回复值只显示数字（如 `3`），不追加“/回合”。

### 扩展指南

新增门派：
1. 在 `CharacterDatabase.SECTS` 字典中添加门派条目（含 `bg_path`）
2. 在 `CharacterDatabase.SECT_ORDER` 数组末尾追加门派名
3. 新建角色常量并在 `_ready()` 中注册到 `_all`

新增角色：
1. 在 `CharacterDatabase` 中定义角色常量（含 `portrait_path`、`sect` 等完整字段）
2. 在 `_ready()` 中注册到 `_all`
3. 立绘存放于 `assets/portraits/`

### 交互

| 操作 | 结果 |
|------|------|
| 点击门派按钮 | 切换 `_selected_sect`，刷新弟子列表，更新背景图 |
| 点击弟子按钮 | 切换 `_selected_char_id`，刷新中央立绘与右侧档案，并播放轻量淡入 |
| 点击"开始轮回" | 按钮轻微缩放反馈，`GameState.start_run(_selected_char_id)` → 跳转 `GameMap.tscn` |

角色选择界面运行时会通过 `preload("res://scripts/InGameMenu.gd")` 创建局内菜单，避免依赖 Godot 编辑器刷新全局脚本类缓存。

### 视觉状态

- 背景采用冷青灰暗化，前景使用半透明深色面板和克制金色细边。
- 三块主要内容都通过 `MenuUiStyle.apply_panel()` 应用统一琉璃面板，标题/角色名使用 Noto Serif SC，正文与数值使用 Noto Sans SC。
- 中央 `PortraitFrame` 顶边与右侧 `StatsCard` 顶边对齐；角色称号显示为立绘框内小题签，避免把画框整体下压。
- 右侧资质格保留六格结构但压缩高度，天赋/英雄技能玉简采用“名称 + 描述”两行；`StartBtn` 收在右侧档案卡底部作为固定确认区。
- 门派/弟子按钮使用普通、悬停、按下三态；选中态沿用 pressed 样式，颜色更亮。
- 角色切换时只使用 `modulate` 与 `scale` 轻动效，不移动布局尺寸，避免 UI 抖动。
- 立绘使用 `PortraitStage` 作为全尺寸画布，`Portrait` 在其中 full-rect 锚定，并使用零固定最小尺寸、`EXPAND_IGNORE_SIZE` 与 `STRETCH_KEEP_ASPECT_CENTERED`。`PortraitFrame` 不参与纵向扩展，720p 下显式约束为约 390px 高，避免被图片原始尺寸撑到屏幕外。

### 手动验证要点

（headless 不可测，需 Godot Editor 运行）

- [ ] 默认进入时选中"万剑门"按钮，弟子列表显示"程天锋"，右侧属性/天赋正确
- [ ] 切换门派按钮时，弟子列表和背景图同步更新
- [ ] 点击弟子按钮，中央立绘与右侧面板立即刷新，淡入不遮挡文本
- [ ] 立绘不变形，文本不溢出，开始按钮位于右侧档案卡底部且不压住技能说明
- [ ] 1280×720 下 PortraitFrame 与 StatsCard 顶边对齐，灵力回复显示为纯数字，不出现“/回合”
- [ ] 点击"开始轮回"正常跳转至 GameMap.tscn

---

## 八、游戏地图界面（GameMap）✅ 已实现（第一重天，16层动态生成）

**场景文件**：`scenes/GameMap.tscn`  
**脚本**：`scripts/GameMap.gd`  
**地图生成**：`scripts/MapGenerator.gd`  
**连线绘制**：`scripts/MapDrawLayer.gd`

### 布局

| 区域 | 锚点 | 内容 |
|------|------|------|
| Header | 垂直 0–8% | 标题（左0–50%）+ HP（中60–80%，右对齐）+ 灵石（右80–100%，含 24x24 图标 + 数值，金色）|
| Header/BagBar | 左上 8–296px | 背包消耗品，每页 5 个，圆形 44×44，点击在地图中使用 |
| Header/DeckBtn | 右上固定 52×约50px，预留局内菜单按钮间距 | 卡组入口改为透明背景叠卡图标 `assets/ui/menu/icon_deck.png`，无文字；点击仍打开当前卡组弹窗，悬停 tooltip 为“查看卡组” |
| TreasureBar | Header 下方，左上 8–820px，高 80px | 宝物栏，每页 10 个 `ArtifactIcon`，无宝物时隐藏 |
| MapScroll | 垂直 8–100% | 可垂直滚动的地图区域（禁止水平滚动） |
| PopupScrim | 全屏，`z_index=99` | 节点弹窗暗色遮罩，阻止点击穿透地图 |
| NodePopup | 水平 17–83%，垂直 16–84%，`z_index=100` | 节点事件弹窗（篝火/起始叙事/物品提示/起源结算），暗金面板 + 标题徽章 + 可滚动正文 + 固定按钮区 |
| VictoryPanel | 水平 20–80%，垂直 20–80%，`z_index=100` | Boss 击败后胜利面板，初始隐藏 |
| CardZoomOverlay | 全屏运行时控件，`z_index=250` | 卡组查看时点击小卡显示居中大卡，采用高质量 Shader 实时背景虚化（Blur）效果 |
| MapDrawLayer | MapContainer 全尺寸 | 节点连线绘制层，固定 `1280 × 1520`，位于节点按钮下方 |
| RingDrawLayer | MapContainer 全尺寸 | 当前节点外环绘制层，位于节点按钮上方 |

地图卡组入口位于 Header 右上角，使用叠卡 icon 按钮替代“查看卡组”文字按钮，保留 `DeckBtn.pressed -> _on_deck_btn_pressed` 的原交互。卡组弹窗每次打开时 `DeckScroll` 重置到顶部；卡牌缩略图按 5 列铺满弹窗宽度并通过纵向滚动浏览。卡组/牌堆查看中的小卡使用 `CardView.set_hover_motion_enabled(false)` 禁用手牌悬浮位移动画，只保留点击放大交互。`CardZoomOverlay` 打开时从被点击卡牌的当前位置缓动放大到屏幕中央，同时背景通过 `textureLod` 实现平滑的毛玻璃虚化（Blur）效果，弱化背景干扰；点击遮罩或大卡后反向缩回原卡位置并关闭。

宝物显示统一使用 `scripts/ArtifactIcon.gd`：36×36 程序化彩色实体图标，稀有度外框为黄品金、玄品紫、地品翠绿、天品朱红、起源青金/白金双层框。悬停 tooltip 显示名称、品级、效果与详情；点击打开详情弹窗。`GameState.last_acquired_artifact_id` 对应的图标在栏位刷新时短暂闪光。

GameMap 运行时同样通过 `preload("res://scripts/InGameMenu.gd")` 创建局内菜单，保证从角色选择点击"开始轮回"后不受脚本类缓存影响。

### 安全节点 UI 统一精修

`scripts/ui/MenuUiStyle.gd` 提供地图安全节点共用样式 helper：`apply_modal_panel`、`apply_result_panel`、`apply_choice_card`、`apply_scrim`、`apply_title_pill`。`scripts/ui/SafeNodeUiStyle.gd` 负责安全节点的运行时交互态：`apply_choice_state` 统一 normal / hover / selected / selected+hover / disabled，`animate_choice_hover` 为卡牌式选择提供轻量缩放与提亮。地图弹窗、起源选择、篝火升级页、奇遇页均复用这套暗金玻璃风格，避免各页面单独复制 StyleBox 配色。

`NodePopup` 结构：
```
PopupScrim
NodePopup
├── PopupVBox
│   ├── PopupPad / PopupInner
│   │   ├── PopupHeader / PopupTitlePill / PopupTitle
│   │   └── PopupBodyScroll / PopupDesc
│   ├── PopupActions / PopupBtn1 / PopupBtn2
│   └── PopupCloseBtn
```

起源选择 overlay 运行时创建 `OriginPanel`，内部 `OriginChoiceRow` 固定展示 3 张 `OriginChoiceCard`；鼠标悬停时卡片边框提亮并轻微放大，点击后卡片金色高亮并显示 `OriginConfirmBtn`，移出鼠标不清除已选态。若祝福需要功法三选一，则打开同风格的 `OriginCardPickerPanel`，功法卡牌悬停时使用 1.02 左右的轻量缩放，不使用大幅位移，避免滚动/网格抖动。

篝火升级页 `scenes/BonfireUpgrade.tscn` 仍由 `scripts/BonfireUpgrade.gd` 代码构建，根节点下创建地图背景、暗色遮罩、`BonfirePanel`、`BonfireCardScroll`、`BonfireSkipBtn`，可升级卡牌悬停时提亮并轻微放大，已升级卡牌只显示 disabled 态；升级预览打开 `UpgradePreviewPanel`。奇遇页 `scenes/AdventureEvent.tscn` 保留独立全屏场景，创建 `EventPanel`、`EventTitleRow`、`EventOptionsBox`、`EventResultPanel`；事件按钮保留按钮 hover/focus 样式，条件不满足时显示 disabled 态且不使用手型光标；需要选牌时打开 `EventCardPickerPanel`，可选卡牌使用同一套轻量 hover 反馈。

### MapContainer 布局常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `FLOOR_COUNT` | 16 | 总层数（含 Boss 层） |
| `FLOOR_SPACING` | 90px | 层间 Y 距离 |
| `MAP_W` | 1280px | 容器宽度 |
| `NODE_W / NODE_H` | 72 × 72px | 节点图片尺寸（正方形） |
| `COL_SPACING` | 240px | 同层节点水平间距 |
| `MAP_TOTAL_H` | 1520px | 容器总高度（含起始节点空间） |

节点坐标公式：
```
x = MAP_W/2 + (col - (total_cols-1)/2.0) × COL_SPACING
y = (FLOOR_COUNT - floor) × FLOOR_SPACING + MAP_H_PADDING
```
起始节点（floor 0）：`y = FLOOR_COUNT × FLOOR_SPACING + MAP_H_PADDING = 1480`

### 节点类型与图片

| 类型 | 图片 | 说明 |
|------|------|------|
| `__start__` | `assets/nodes/start.png` | 起始节点，每局游戏入口；触发叙事序章 + 起源选择（三选一祝福） |
| `normal` | `assets/nodes/monster.png` | 普通战斗 |
| `elite` | `assets/nodes/elite.png` | 精英战斗 |
| `bonfire` | `assets/nodes/rest.png` | 篝火（调息回复 HP） |
| `shop` | `assets/nodes/shop.png` | 黑市，点击后跳转 `scenes/Shop.tscn` |
| `event` | `assets/nodes/adventure.png` | 奇遇事件，点击后跳转 `scenes/AdventureEvent.tscn` |
| `boss` | `assets/nodes/boss.png` | Boss 节点（第16层唯一） |

所有节点图片通过 canvas_item shader 裁切为圆形（smoothstep 抗锯齿）。节点按钮统一设置 `pivot_offset = size / 2`，当前起始节点/当前节点的放大缩小动画必须围绕节点自身中心执行。

### 完整交互流程

```
CharacterSelect → start_run() → GameMap 加载
  → 地图动态生成（MapGenerator.generate()）
  → 起始节点亮起（⬤），第1层节点暗淡

点击起始节点（start.png）
  → NodePopup [第一屏] 显示"轮回再起"叙事文本
  → 点击"踏入轮回" → NodePopup 切换至起源选择屏（第二屏）

  [起源选择屏]
  → 三列卡片式布局，每列展示一组起源祝福（名称 + 奖励描述）
  → 玩家点击任意一列 → 该列高亮，出现"确认选择"按钮
  → 点击"确认选择"
      → 对应 S-XX 效果即时执行
      → 弹窗底部消息栏显示获得内容
  → 点击"踏入轮回"（最终确认）
  → GameState.start_map() → 第1层节点全部解锁（⬤）
  → 地图自动滚动至第1层

点击第 N 层节点（已解锁）
  → GameState.visit_map_node(node_id) 标记已访问
  → battle / bonfire / shop / event 分支处理
  → 战斗节点：跳转 Battle.tscn；黑市节点：跳转 Shop.tscn；其他非战斗节点：NodePopup

返回地图（战斗胜利后）
  → map_accessible_ids 已更新为第 N+1 层节点
  → 地图自动滚动至第 N+1 层

点击第16层 Boss 并胜利
  → VictoryPanel 显示
  → 胜利文案显示“丹狱童尊在你剑下崩作炉灰”
  → 点击"返回主菜单"
```

### 节点视觉状态

| 状态 | modulate | disabled |
|------|----------|---------|
| 可访问（当前可选） | `Color(1,1,1,1)` 亮白 | false |
| 已访问 | `Color(0.4,0.4,0.4,0.85)` 灰暗 | true |
| 未来层 | `Color(0.6,0.6,0.65,0.55)` 半透明 | true |
| 本层不可达 | `Color(0.3,0.3,0.3,0.4)` 暗 | true |

连线颜色：已访问路径金色实线 `Color(0.86,0.66,0.28,0.95)`，当前可选路径亮金实线 `Color(1.0,0.88,0.45,0.95)`，未来路径蓝灰实线 `Color(0.52,0.57,0.68,0.58)`。所有连线保持曲线实线效果，不使用虚线；连线从节点圆形边缘开始/结束，不穿过节点中心，底部绘制半透明阴影增强可读性。

### GameState 地图相关字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `map_nodes` | Dictionary | node_id → 节点数据（含 floor/col/type/next_ids/visited） |
| `map_floors` | Array | `floors[i]` = 第 i+1 层节点 ID 列表 |
| `map_current_floor` | int | 最近访问的层号（0=未开始） |
| `map_accessible_ids` | Array[String] | 当前可点击的节点 ID 列表 |
| `map_started` | bool | 是否已通过起始节点进入地图 |
| `shop_discount_pct` | float | 黑市折扣比例（0.0 = 无折扣；起源祝福 S-03 触发后设为 0.15） |
| `map_intro_played` | bool | 当前 run 是否已播放过"登仙台 / 第一重天"入场标题；战斗后回地图不重复播放 |
| `current_hp` | int | 地图与战斗共享的当前生命值；战斗扣血实时同步，战斗胜利或经过非战斗节点后回复【生命回复】点并在地图 HP 显示中保留 |
| `pending_battle_node` | String | 待进入的战斗节点 ID |
| `pending_battle_node_type` | String | 节点类型（normal/elite/boss） |
| `pending_battle_node_floor` | int | 节点层号，供 EnemyDatabase 选敌 |

### 手动验证要点

（headless 不可测，需 Godot Editor 运行）

- [ ] 进入地图时只有起始节点亮起，第1层全部灰暗
- [ ] 地图节点之间存在清晰连线，起始节点到第1层也有连线
- [ ] 点击起始节点弹出叙事文本，内容正确
- [ ] 起始节点放大缩小动画以自身中心为轴，不向左上或其他方向偏移
- [ ] 点击"踏入轮回"后第1层节点全部解锁，地图滚动至第1层
- [ ] 点击战斗节点正确跳转战斗场景，返回后下一层解锁
- [ ] 战斗结束回地图后 HP 保留战斗剩余生命，并额外回复角色【生命回复】点（不超过生命上限）
- [ ] 经过商店/执念/篝火等非战斗节点后 HP 也按【生命回复】点更新，地图左上 HP 显示准确
- [ ] 点击黑市节点进入 Shop.tscn，返回后地图灵石、背包、宝物栏刷新
- [ ] 起始节点在访问后变灰，不可再次点击
- [ ] 起始节点→第1层连线在访问后变为金色
- [ ] 篝火节点回复30%HP，HP 显示正确更新
- [ ] 起始叙事/篝火/物品提示弹窗显示暗色遮罩、标题徽章、可滚动正文和稳定按钮区，按钮文字不溢出
- [ ] 起源选择显示 3 张同尺寸祝福卡，点击后仅选中卡高亮，确认按钮出现且不挤压卡片
- [ ] 起源祝福、功法三选一、奇遇选项、奇遇选牌、篝火升级卡都能一眼区分 normal / hover / selected / disabled；鼠标悬停时立即高亮，disabled 项不响应 hover 且不显示手型光标
- [ ] `capture_ui.bat game_map --size 1280x720 --wait 90` 截图中地图弹窗、顶部栏、节点不互相遮挡
- [ ] 第16层 Boss 节点战斗后显示胜利面板

---

## 九、黑市界面（Shop）✅ V2 已实现

**场景文件**：`scenes/Shop.tscn`  
**脚本**：`scripts/ShopScene.gd`  
**数据层**：`scripts/data/ShopDatabase.gd`（Autoload: `ShopDatabase`）

### 布局

| 区域 | 内容 |
|------|------|
| 顶部栏 | “黑市”标题、当前灵石、返回地图按钮 |
| 左栏：卡牌 | 每次刷新 3 张卡牌，使用 `CardView` 预览，点击购买后加入 `GameState.deck` |
| 中栏：物品 | 每次刷新 4 个物品，包含丹药/符箓/阵盘；临时加货时刷新 5 个，购买后进入 `GameState.consumables` |
| 右栏：宝物 | 每次刷新 2 件宝物，已拥有宝物不再进货，购买后进入 `GameState.artifacts` |
| 底部服务区 | 删除卡牌、升级卡牌；点击后打开牌组选择 overlay |
| 牌组选择 overlay | 全屏遮罩 + 网格按钮，按卡牌名称与费用选择删除/升级对象 |

### 交互逻辑

| 操作 | 响应 |
|------|------|
| 进入黑市 | 按当前地图层数调用 `ShopDatabase.generate_stock(floor, owned_artifact_ids, seed, extra_item_count)`，并消耗下次黑市折扣/加货 |
| 购买卡牌 | `GameState.buy_shop_card(card_id, price)` 扣灵石并加入牌组，商品从当前货架移除 |
| 购买物品 | `GameState.buy_shop_item(item, price)`，背包满 10 格时按钮不可用 |
| 购买宝物 | `GameState.buy_shop_artifact(artifact, price)`，宝物不占背包且不可重复持有 |
| 删除卡牌 | 每次进入黑市最多 1 次，调用 `GameState.remove_deck_card_at(index, price)` |
| 升级卡牌 | 只能选择未升级卡，调用 `GameState.upgrade_deck_card_at(index, price)`，id 追加 `+` |
| 返回地图 | `change_scene_to_file("res://scenes/GameMap.tscn")`，地图重新读取 GameState 刷新灵石/背包/宝物 |

### 地图背包联动

`GameMap.gd` 的背包点击改为统一调用 `GameState.use_consumable(index, "map")`：

| 分类 | 地图点击效果 |
|------|------|
| 丹药 `elixir` | 应用 `map_use` 并移除，可用于补给或下场战斗准备 |
| 符箓 `talisman` | 应用 `map_use` 并移除；风符·逐云可让下一次地图选择改为从下一层所有同层节点中选择 1 个，其他符箓可用于下次奖励或下场战斗准备 |
| 阵盘 `formation` | 应用 `map_use` 并移除；不再写入常驻 `active_formation_id` |

地图使用可登记轻量 pending 状态：`pending_battle_consumable_effects` 供 `BattleEngine.init()` 读取，`pending_shop_discount_pct` / `pending_shop_extra_items` 供下次黑市读取，`pending_reward_stones_bonus` / `pending_reward_min_rarity` 供奖励页读取。风符·逐云的改选效果是符箓自身的一次性地图效果，使用时直接扩展当前可选的下一层节点，不作为地图默认规则。

### 手动验证要点

（headless 不可完整验证场景跳转和鼠标交互，需 Godot Editor 运行）

- [ ] 从地图黑市节点进入 `Shop.tscn`
- [ ] 分别购买卡牌、物品、宝物，灵石扣除且对应 GameState 列表更新
- [ ] 背包满 10 格后物品购买按钮不可用，宝物仍可购买
- [ ] 删除卡牌每次进入黑市最多 1 次，费用按 50/75/100/125 递增
- [ ] 升级卡牌后牌组 id 追加 `+`，已升级卡不可再次选择
- [ ] 返回地图后，灵石、背包、宝物栏显示同步；使用阵盘后背包数量减少

---

## 十、战斗界面（Battle）✅ 已优化

**场景文件**：`scenes/Battle.tscn`
**脚本**：`scripts/BattleScene.gd`
**全局主题**：`theme/main_theme.tres`

### 视觉风格
- **整体色调**：深色调（墨色/深蓝），搭配金色/古铜色边框。
- **组件样式**：
    - **PanelContainer**：使用 `StyleBoxFlat` 实现半透明毛玻璃感 + 金色细边框。
    - **ProgressBar**：深红填充（敌人/玩家 HP），带有深色背景和精致边框。
    - **按钮**：统一古风按钮样式，悬停时带有金色外发光。

### 布局分布

| 区域 | 锚点/位置 | 内容 |
|------|----------------|------|
| LogPanel | 顶部居中 (y:15) | 战斗实时日志，宽 500px，高度自适应 |
| TopLeftHUD | 左上 (x:10, y:8)，宽约 350px，高约 84px | 上排战斗消耗品栏，下排宝物栏；不与 LogPanel/PlayerCard 重叠 |
| Entities Area | 屏幕中上部 | 玩家与敌人的角色卡片 |
| ├ PlayerCard | 左侧 (x:40, y:100) | 玩家立绘、HP/护体条、状态 icon 栏 |
| └ EnemyCard | 右侧 (x:960, y:100) | 敌人立绘、名称、HP/护体条、状态 icon 栏、意图 |
| BottomUI | 屏幕底部 (h:260) | 资源与手牌交互区 |
| ├ ResourceDock | 左下 (x:22, y:-118) | 灵力、道慧圆盘，抽牌堆/弃牌堆入口 |
| ├ Actions | 右下 (x:1070, y:-150) | 英雄技能、结束回合按钮 |
| └ HandArea | 中下 (居中) | 手牌容器（HandContainer） |

### 关键节点结构

```
Battle (Control, Theme: main_theme.tres)
├── BG (TextureRect)
├── Overlay (ColorRect, Alpha 0.4)
├── TopLeftHUD (Runtime VBoxContainer)
│   ├── BattleBagRow -> Prev / 5×ItemButton / Next
│   └── BattleArtifactRow -> Prev / 10×ArtifactIcon / Next
├── LogPanel (PanelContainer)
│   └── LogScroll/LogLabel (%)
├── Entities (Control)
│   ├── EnemyCard (PanelContainer)
│   │   └── VBox/EnemyPortrait + InfoVBox/Margin/V/
│   │       ├── EnemyName (%) + EnemyHPShieldBar (%)
│   │       ├── EnemyStatusBar (%) -> StatusIcon(程序化 32×32，最多两行)
│   │       └── IntentLabel (%)
│   └── PlayerCard (PanelContainer)
│       └── VBox/PlayerPortrait + InfoVBox/Margin/V/
│           ├── PlayerName + PlayerHPShieldBar (%)
│           └── PlayerStatusBar (%) -> StatusIcon(程序化 32×32，最多两行)
└── BottomUI (Control)
    ├── ResourceDock (Runtime Control) -> ResourceOrb(灵力) / ResourceOrb(道慧) / DrawPileBtn / DiscardPileBtn
    ├── PileOverlay (Runtime Control) -> ScrollContainer / GridContainer(columns=5)
    ├── Actions (VBoxContainer) -> SkillBtn% / EndTurnBtn%
    └── HandArea (Control) -> HandContainer (%)
```

### 交互优化
- **敌人立绘**：`EnemyDatabase` 中所有当前可进入战斗的敌人都带 `portrait_path` 字段，指向 `assets/portraits/enemies/<enemy_id>.png`。`BattleScene.gd` 在刷新敌人 UI 时读取该字段并加载到 `Entities/EnemyCard/VBox/EnemyPortrait`；内部缓存当前路径，避免每帧重复 `load()`。若字段为空或资源加载失败，回退到 `res://assets/portraits/enemy.png`，该旧图仅作为异常 fallback 保留。当前覆盖 5 个普通怪、5 个精英怪、丹狱童尊 Boss 和 4 个事件战斗敌人，共 15 张独立原型立绘。立绘规格为约 7:8 竖幅、带简洁背景、主体居中清晰、无文字和水印，风格为黑暗修仙；普通与对应精英保持同源强化关系，方便玩家识别进阶威胁。
- **手牌布局**：动态计算间距，卡牌在 5 张以上时自动压缩重叠。
- **资源展示**：`scripts/ResourceOrb.gd` 绘制灵力、道慧圆盘；道行不再占用左下独立资源栏，改为玩家卡片状态 icon。旧 Resources 面板在运行时隐藏。
- **战斗状态栏**：`PlayerStatusBar` / `EnemyStatusBar` 位于各自 HP/护体条正下方，敌人意图继续显示在敌人状态栏下方。状态栏使用 `scripts/StatusIcon.gd` 程序化占位图标，32×32 深色底、按状态正负/核心类型描边，右下角显示当前数值，hover tooltip 解释层数/次数/回合含义；每行 7 个，最多两行，超出折叠为“更多状态”。玩家栏固定显示基础灵力回复与道行，额外灵力回复、裂伤、枯竭、不侵、心流、荆棘、震慑、下一攻加伤、下回合道行、下回合额外抽牌、濒死保护、负面免疫等按优先级追加；敌方栏显示敌方道行、荆棘、敌方状态字典与行动延后，无状态时隐藏整行。护体只在 HP/护体条显示，不进入状态栏。
- **左上 HUD**：`TopLeftHUD` 运行时创建，消耗品每页 5 个、宝物每页 10 个；宝物行无内容时隐藏。战斗中点击消耗品调用 `GameState.use_consumable(index, "battle")`，取回 `battle_use` 后交给 `BattleEngine.apply_battle_consumable_effect()`，使用后立即从背包移除并刷新栏位。
- **宝物详情**：战斗宝物栏与地图宝物栏共用 `scripts/ArtifactIcon.gd`，点击宝物只打开详情弹窗，不触发或消耗宝物；详情文案不显示主动/被动类型字段。
- **牌堆查看**：点击抽牌堆或弃牌堆按钮打开 `PileOverlay`，按一行 5 张卡展示当前牌堆内容，空堆显示占位提示。
- **卡牌放大查看**：地图卡组、战斗抽牌堆、战斗弃牌堆的小卡点击后调用 `scripts/CardZoomOverlay.gd` 显示居中大卡；再次点击遮罩或大卡关闭放大层，原查看弹窗保持打开。
- **抽牌动画**：普通抽牌、战斗开始抽 3 张、牌库耗尽后的洗牌重抽都从抽牌堆锚点飞入手牌；洗牌时旧手牌先飞回抽牌堆，再延迟飞出重抽卡。
- **悬停反馈**：卡牌悬停时 `z_index` 提升，平滑向上弹出并放大。
- **卡牌渲染**：所有卡牌显示统一通过 `scripts/CardRenderer.gd` 运行时合成，不依赖 `assets/card/generated/` 整卡图；渲染器以 `assets/card/template.png` 为底板，按 `assets/card/gen_all_cards.py` 的坐标规则叠加原画、费用、名称、类型和深棕描述文字；普通数字 ID 卡默认读取 `assets/card/art/XX.png`，Boss 专属牌、污染牌等非数字 ID 卡必须在数据中提供 `art_path`，例如【烂髓丹】读取 `res://assets/card/art/lan_sui_dan.png`；普通卡牌描述继续使用 `Label` 保持居中排版，战斗手牌、牌堆放大与悬停预览在需要数字变色时由 `scripts/BattleScene.gd` 传入同一份实时计算后的富文本片段，富文本层必须透明且与普通描述框居中对齐，避免小卡与大卡数值不一致。
- **战斗卡牌数值颜色**：战斗中描述里的伤害数值以当前战斗状态重算，并与该卡当前升级状态下的原始数值比较；高于原始值时仅数字显示绿色，低于原始值时仅数字显示红色，相等时数字保持深棕/黑色，单位和其余文字不变。
- **提示信息**：资源不足时通过 Toast 弹出提示。
---

## 十一、战斗奖励界面（RewardScreen）

**场景文件**：`scenes/RewardScreen.tscn`  
**脚本**：`scripts/RewardScreen.gd`  
**触发时机**：战斗胜利 → 结果面板点"返回地图" → 本界面 → "继续前行" → GameMap

### 节点结构

```
RewardScreen (Control)
├── BG (ColorRect) — 深色全屏背景
├── RewardPopup (PanelContainer) — 初始奖励弹窗
│   └── PopupPad → PopupVBox
│       ├── PopupTitle "战斗奖励"
│       ├── %StonesBtn "灵石 +30/+60"
│       ├── %CardRewardBtn "卡牌奖励"
│       └── %PopupContinue "继续"
├── %CardPanel (PanelContainer, hidden, z=10) — 全屏三选一卡牌页
│   └── CardPanelPad → CardPanelVBox
│       ├── CardPanelTitle "择取功法"
│       ├── %CardsRow (HBoxContainer) — 动态填入3个固定卡槽
├── ActionRow (HBoxContainer, runtime reparent, z=40) — 底部居中按钮栏
│   ├── %ConfirmBtn "确定"（初始禁用）
│   └── %SkipBtn "跳过"
└── _upgrade_check (CheckBox, runtime, z=30) — 左下角"查看升级"
```

### 交互逻辑

| 操作 | 响应 |
|------|------|
| 进入界面 | 根据 `GameState.pending_battle_node_type` 计算灵石奖励（普通+30，精英+60），并抽取3张不重复卡牌 |
| 点击"灵石" | 将灵石加入 `GameState.spirit_stones`，按钮置为已领取 |
| 点击"卡牌奖励" | 打开全屏 `CardPanel`，显示3个固定尺寸卡槽，并显示左下角"查看升级" |
| 点击卡牌 | 选中该卡（高亮），启用"确定" |
| 点击"查看升级" | 仅切换三张奖励卡的升级预览，清除当前选择，且复选框不参与卡牌布局 |
| 点击"确定" | 将卡ID追加到 `GameState.deck`，关闭选卡页，卡牌奖励按钮置为已选取 |
| 点击"跳过" | 关闭选卡页，不修改牌组 |
| 点击"继续" | `change_scene_to_file(GameMap.tscn)` |

### 奖励卡牌布局约束

- 三张奖励卡统一使用固定卡槽：卡牌 `186×333`，不在卡牌外额外显示名称，避免外部名称误叠到描述区；卡名只由卡牌顶部自身渲染。
- `%CardsRow` 运行时设置卡槽间距 `170`，卡槽与卡牌行 `size_flags` 使用 `SIZE_SHRINK_CENTER`，让三张牌左右展开，避免被 HBox/VBox 容器拉伸成大图、互相挤压或整体沉到底部。
- `%ConfirmBtn` / `%SkipBtn` 运行时随 `ActionRow` 挂到 `RewardScreen` 根节点底部居中（z=40），不参与卡牌行布局，不覆盖卡牌描述区。
- 每个卡槽用 `Button` 承接点击，内部 `CardView.mouse_filter = IGNORE`，确保点击卡面时触发选卡，而不是被 CardView 或左下角复选框误拦截。
- "查看升级"复选框运行时挂在 `RewardScreen` 根节点左下角，不放入 `%CardPanel` 和 `%CardsRow`，使用白色边框图标并只拦截自身矩形区域点击。

### 稀有度权重

黄品 55%（累积≤0.55）/ 玄品 30%（≤0.85）/ 地品 10%（≤0.95）/ 天品 5%（≤1.0）

三张卡去重抽取（同id不重复），最多重试300次。

---

## 十二、待办 / 后续界面

| 界面 | 优先级 | 说明 |
|------|--------|------|
| 完整地图 | 高 | 三重天15节点，单向不可逆分叉路径 |
| 角色立绘 | 中 | 替换 Portrait 占位 ColorRect |
| 存档 / 继续界面 | 中 | Roguelike 单存档，显示当前重天与层数 |
| 宝物效果后续 | 中 | 补齐所有宝物在 BattleEngine/奖励/商店中的持续效果触发 |
| 执念事件内容扩展 | 中 | 补充更多事件分支、事件战斗与专属美术资源 |

---

## 十三、卡牌圆角渲染实现补充

- `scripts/CardRenderer.gd` 作为独立卡牌渲染器时，根节点绘制圆角遮罩并设置 `clip_children = CLIP_CHILDREN_ONLY`，统一裁切底板、原画与文字层，避免放大预览和篝火升级大卡出现矩形硬角。
- `scripts/CardView.gd` 作为手牌/奖励/牌堆小卡外层时，根节点使用同一圆角比例裁切 `Shadow`、`Dimmer` 与内部 `CardRenderer`；内部渲染器关闭自身子裁切，避免嵌套 `CanvasItem` 裁切造成异常。
- 顶部圆角半径按卡牌当前较短边的 8.5% 计算；左下角和右下角按 14% 计算，手牌 100x179 显示约 14px 底部圆角，放大卡随尺寸等比增大。

---

## 十四、UI 诊断截图工具

**入口**：`capture_ui.bat`
**脚本**：`tools/UiCapture.gd`
**输出目录**：`tests/results/ui-captures/`（不入库）

该工具用于开发与协作代理在需要查看具体 UI 状态时快速生成真实渲染截图，不属于自动化测试 suite，不做 pass/fail 断言。

支持预设：`main_menu`、`options`、`character_select`、`game_map`、`battle`、`reward`、`shop`、`bonfire`、`event`、`all`。

常用命令：

```bat
capture_ui.bat --list
capture_ui.bat main_menu
capture_ui.bat battle --size 1920x1080 --wait 90
capture_ui.bat all
capture_ui.bat main_menu --visible
```

默认使用离屏真实 Godot 渲染窗口，不在桌面中央弹出；需要人工观察窗口时可显式添加 `--visible`。该工具不是纯 headless 截图：Godot 4.6.2 的 headless/dummy display 可加载场景，但拿不到真实 viewport texture。默认分辨率为 1280×720，默认等待 60 帧。每次运行保存 PNG 截图、`manifest.json` 和 `nodes.txt`，其中节点摘要记录场景节点的可见性、位置、尺寸和关键文本，便于和截图交叉排查。

预设直接构造必要的 `GameState`，默认角色为 `chen_tian_feng`，事件页默认 `Q-101`；这保证截图稳定复现目标画面，而不是模拟完整 UI 点击流程。新增 `.gd` 工具脚本仍需登记到 `TestScriptIntegrity`，但不新增 UI 自动测试 suite。
