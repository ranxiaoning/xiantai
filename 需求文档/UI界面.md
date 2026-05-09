# 《无尽仙台》UI 界面规范

## 一、技术栈

- **引擎**：Godot 4.3+
- **渲染**：Forward Plus
- **分辨率基准**：1280×720（16:9），支持 1600×900 / 1920×1080 / 2560×1440
- **拉伸模式**：canvas_items + expand（UI 整体等比缩放）

---

## 二、主菜单（MainMenu）

**场景文件**：`scenes/MainMenu.tscn`

### 布局

| 区域 | 位置（屏幕占比） | 内容 |
|------|----------------|------|
| 标题区 | 垂直 10%–38% | 游戏名"无尽仙台"（64px）+ 英文副标题（16px） |
| 按钮区 | 垂直 42%–80%，水平居中 35%–65% | 三个主操作按钮 |
| 版本号 | 右下角 | v0.x.x 小字 |

### 按钮列表

| 按钮 | 功能 |
|------|------|
| 开始游戏 | 跳转至职业选择 / 存档界面（待实现） |
| 选项 | 跳转至 OptionsMenu |
| 退出 | `get_tree().quit()` |

### 键盘导航

进入场景时焦点自动落在"开始游戏"，支持方向键上下切换，Enter 确认。

---

## 三、选项界面（OptionsMenu）

**场景文件**：`scenes/OptionsMenu.tscn`

### 分区

#### 显示

| 设置项 | 控件 | 说明 |
|--------|------|------|
| 分辨率 | OptionButton | 1280×720 / 1600×900 / 1920×1080 / 2560×1440 |
| 全屏 | CheckButton | 勾选后分辨率选项禁用 |

> 分辨率更改需点击"应用"后生效（`apply_display()`），防止误触。

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
| `fullscreen` | bool | false | 是否全屏 |
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
| 背景色 | `#0A0A15`（深蓝黑） |
| 标题主色 | 白色，后期替换为金色渐变字体 |
| 章节标题色 | `#B3A666`（浅金） |
| 按钮默认状态 | 深灰面板 + 白色文字 |
| 按钮 Hover 状态 | 轻微金色描边（待主题配置） |
| 字体 | 暂用 Godot 默认字体，后期替换为支持中文的古风字体 |

---

## 六、测试规范

### 测试分层要求

每个 UI 模块完成开发后，必须按以下顺序提供测试：

| 层级 | 类型 | 要求 | 执行方式 |
|------|------|------|----------|
| 1 | **白盒/完整性测试** | 所有新增 .gd 文件必须注册到 `TestScriptIntegrity.gd` 的 `GAME_SCRIPTS` 列表 | `run_tests.bat` headless |
| 2 | **单元测试** | 纯逻辑函数（配置读写、计算、状态变更）必须有对应单元测试套件 | `run_tests.bat` headless |
| 3 | **功能/集成测试** | 涉及 Display/Audio/场景跳转的流程，记录在 `tests/xxx_system.md` 供手动验证 | Godot Editor 手动 |

### 已知约束

- **Autoload 调用规范**：不得在任何脚本中直接写 `Logger.info()`，必须通过 `Log.info()` 调用。
  原因：GDScript 解析器将 Autoload 名视为类引用，无法在编译期验证实例方法，导致 Parse Error。
- **headless 限制**：DisplayServer、AudioServer、场景切换相关逻辑无法在 headless 模式下自动测试。

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
| ├ SidebarPanel | 固定宽 210px | 当前门派弟子列表与提示 |
| ├ HeroPanel | 弹性 ratio 1.35 | 角色称号、大立绘、角色名、背景故事 |
| └ StatsCard | 固定最小宽 340px，弹性 ratio 1.0 | 初始资质 / 天赋 / 英雄技能 |
| StartBtn | 右下 72.5%–95.5%，垂直 89%–96.5% | “开始轮回”，确认选择并跳转地图 |

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
│   │   ├── CharTitle (Label) *
│   │   ├── PortraitFrame/PortraitMargin/PortraitStage/Portrait (TextureRect) *
│   │   ├── CharName (Label) *
│   │   └── Lore (Label) *
│   └── StatsCard/StatsPad/StatsPanel
│       ├── Stats Grid（HPValue* / HPRegenValue* / LingLiValue* / LingLiRegenValue* / DaoHuiValue* / DmgValue*）
│       ├── TalentPanel/TalentPad/TalentDesc *
│       └── SkillPanel/SkillPad/SkillDesc *
└── StartBtn (Button) *           # 开始轮回
```

> `*` = `unique_name_in_owner = true`，脚本通过 `%NodeName` 访问

### 数据来源

- `CharacterDatabase.get_all_sects()` → 门派名称列表（按 `SECT_ORDER` 顺序）
- `CharacterDatabase.get_sect_data(sect)` → 门派元数据（`bg_path` 等）
- `CharacterDatabase.get_sect_characters(sect)` → 该门派所有角色列表
- `CharacterDatabase.get_character(id)` → 单个角色完整数据（含 `portrait_path`）
- 初始资质中【灵力上限】与【灵力回复】分别独立成行展示，不把回复值写在括号里。

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

### 视觉状态

- 背景采用冷青灰暗化，前景使用半透明深色面板和克制金色细边。
- 门派/弟子按钮使用普通、悬停、按下三态；选中态沿用 pressed 样式，颜色更亮。
- 角色切换时只使用 `modulate` 与 `scale` 轻动效，不移动布局尺寸，避免 UI 抖动。
- 立绘使用 `PortraitStage` 作为全尺寸画布，`Portrait` 在其中 full-rect 锚定，并使用零固定最小尺寸、`EXPAND_IGNORE_SIZE` 与 `STRETCH_KEEP_ASPECT_CENTERED`。`PortraitFrame` 不参与纵向扩展，720p 下显式约束为约 320px 高，避免被图片原始尺寸撑到屏幕外。

### 手动验证要点

（headless 不可测，需 Godot Editor 运行）

- [ ] 默认进入时选中"万剑门"按钮，弟子列表显示"程天锋"，右侧属性/天赋正确
- [ ] 切换门派按钮时，弟子列表和背景图同步更新
- [ ] 点击弟子按钮，中央立绘与右侧面板立即刷新，淡入不遮挡文本
- [ ] 立绘不变形，文本不溢出，开始按钮位于右下且状态清晰
- [ ] 1280×720 下立绘完整显示，不下沉到立绘框底部，也不裁掉上半身
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
| MapScroll | 垂直 8–100% | 可垂直滚动的地图区域（禁止水平滚动） |
| NodePopup | 水平 15–85%，垂直 15–85%，`z_index=100` | 节点事件弹窗（篝火/商店/奇遇/起始叙事），初始隐藏，显示时覆盖地图节点与连线 |
| VictoryPanel | 水平 20–80%，垂直 20–80%，`z_index=100` | Boss 击败后胜利面板，初始隐藏 |
| CardZoomOverlay | 全屏运行时控件，`z_index=250` | 卡组查看时点击小卡显示居中大卡，采用高质量 Shader 实时背景虚化（Blur）效果 |
| MapDrawLayer | MapContainer 全尺寸 | 节点连线绘制层，固定 `1280 × 1520`，位于节点按钮下方 |
| RingDrawLayer | MapContainer 全尺寸 | 当前节点外环绘制层，位于节点按钮上方 |

地图卡组弹窗每次打开时 `DeckScroll` 重置到顶部；卡牌缩略图按 5 列铺满弹窗宽度并通过纵向滚动浏览。卡组/牌堆查看中的小卡使用 `CardView.set_hover_motion_enabled(false)` 禁用手牌悬浮位移动画，只保留点击放大交互。`CardZoomOverlay` 打开时从被点击卡牌的当前位置缓动放大到屏幕中央，同时背景通过 `textureLod` 实现平滑的毛玻璃虚化（Blur）效果，弱化背景干扰；点击遮罩或大卡后反向缩回原卡位置并关闭。

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
| `__start__` | `assets/nodes/start.png` | 起始节点，每局游戏入口 |
| `normal` | `assets/nodes/monster.png` | 普通战斗 |
| `elite` | `assets/nodes/elite.png` | 精英战斗 |
| `bonfire` | `assets/nodes/rest.png` | 篝火（调息回复 HP） |
| `shop` | `assets/nodes/shop.png` | 商店（暂未实装） |
| `event` | `assets/nodes/adventure.png` | 奇遇事件（暂未实装） |
| `boss` | `assets/nodes/boss.png` | Boss 节点（第16层唯一） |

所有节点图片通过 canvas_item shader 裁切为圆形（smoothstep 抗锯齿）。节点按钮统一设置 `pivot_offset = size / 2`，当前起始节点/当前节点的放大缩小动画必须围绕节点自身中心执行。

### 完整交互流程

```
CharacterSelect → start_run() → GameMap 加载
  → 地图动态生成（MapGenerator.generate()）
  → 起始节点亮起（⬤），第1层节点暗淡

点击起始节点（start.png）
  → NodePopup 显示起始叙事文本
  → 点击"踏入轮回"
  → GameState.start_map() → 第1层节点全部解锁（⬤）
  → 地图自动滚动至第1层

点击第 N 层节点（已解锁）
  → GameState.visit_map_node(node_id) 标记已访问
  → battle / bonfire / shop / event 分支处理
  → 战斗节点：跳转 Battle.tscn；非战斗：NodePopup

返回地图（战斗胜利后）
  → map_accessible_ids 已更新为第 N+1 层节点
  → 地图自动滚动至第 N+1 层

点击第16层 Boss 并胜利
  → VictoryPanel 显示
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
- [ ] 起始节点在访问后变灰，不可再次点击
- [ ] 起始节点→第1层连线在访问后变为金色
- [ ] 篝火节点回复30%HP，HP 显示正确更新
- [ ] 第16层 Boss 节点战斗后显示胜利面板

---

## 九、战斗界面（Battle）✅ 已优化

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
| Entities Area | 屏幕中上部 | 玩家与敌人的角色卡片 |
| ├ PlayerCard | 左侧 (x:40, y:100) | 玩家立绘、HP条、护体值 |
| └ EnemyCard | 右侧 (x:960, y:100) | 敌人立绘、名称、HP条、意图、状态 |
| BottomUI | 屏幕底部 (h:260) | 资源与手牌交互区 |
| ├ ResourceDock | 左下 (x:22, y:-118) | 灵力、道慧圆盘，道行徽章，抽牌堆/弃牌堆入口 |
| ├ Actions | 右下 (x:1070, y:-150) | 英雄技能、结束回合按钮 |
| └ HandArea | 中下 (居中) | 手牌容器（HandContainer） |

### 关键节点结构

```
Battle (Control, Theme: main_theme.tres)
├── BG (TextureRect)
├── Overlay (ColorRect, Alpha 0.4)
├── LogPanel (PanelContainer)
│   └── LogScroll/LogLabel (%)
├── Entities (Control)
│   ├── EnemyCard (PanelContainer)
│   │   └── VBox/EnemyPortrait + InfoVBox/Margin/V/
│   │       ├── EnemyName (%) + EnemyHPBar (%)
│   │       └── HBox (IntentLabel% + EnemyShieldLabel%)
│   └── PlayerCard (PanelContainer)
│       └── VBox/PlayerPortrait + InfoVBox/Margin/V/
│           └── PlayerName + HPBar (%) + ShieldLabel (%)
└── BottomUI (Control)
    ├── ResourceDock (Runtime Control) -> ResourceOrb(灵力) / ResourceOrb(道慧) / DaoXingBadge / DrawPileBtn / DiscardPileBtn
    ├── PileOverlay (Runtime Control) -> ScrollContainer / GridContainer(columns=5)
    ├── Actions (VBoxContainer) -> SkillBtn% / EndTurnBtn%
    └── HandArea (Control) -> HandContainer (%)
```

### 交互优化
- **手牌布局**：动态计算间距，卡牌在 5 张以上时自动压缩重叠。
- **资源展示**：`scripts/ResourceOrb.gd` 绘制灵力、道慧圆盘，左下道行以金色徽章展示；旧 Resources 面板在运行时隐藏。
- **牌堆查看**：点击抽牌堆或弃牌堆按钮打开 `PileOverlay`，按一行 5 张卡展示当前牌堆内容，空堆显示占位提示。
- **卡牌放大查看**：地图卡组、战斗抽牌堆、战斗弃牌堆的小卡点击后调用 `scripts/CardZoomOverlay.gd` 显示居中大卡；再次点击遮罩或大卡关闭放大层，原查看弹窗保持打开。
- **抽牌动画**：普通抽牌、战斗开始抽 3 张、牌库耗尽后的洗牌重抽都从抽牌堆锚点飞入手牌；洗牌时旧手牌先飞回抽牌堆，再延迟飞出重抽卡。
- **悬停反馈**：卡牌悬停时 `z_index` 提升，平滑向上弹出并放大。
- **卡牌渲染**：所有卡牌显示统一通过 `scripts/CardRenderer.gd` 运行时合成，不依赖 `assets/card/generated/` 整卡图；渲染器以 `assets/card/template.png` 为底板，按 `assets/card/gen_all_cards.py` 的坐标规则叠加原画、费用、名称、类型和深棕描述文字；普通卡牌描述继续使用 `Label` 保持居中排版，战斗手牌、牌堆放大与悬停预览在需要数字变色时由 `scripts/BattleScene.gd` 传入同一份实时计算后的富文本片段，富文本层必须透明且与普通描述框居中对齐，避免小卡与大卡数值不一致。
- **战斗卡牌数值颜色**：战斗中描述里的伤害数值以当前战斗状态重算，并与该卡当前升级状态下的原始数值比较；高于原始值时仅数字显示绿色，低于原始值时仅数字显示红色，相等时数字保持深棕/黑色，单位和其余文字不变。
- **提示信息**：资源不足时通过 Toast 弹出提示。
---

## 十、战斗奖励界面（RewardScreen）

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

## 十一、待办 / 后续界面

| 界面 | 优先级 | 说明 |
|------|--------|------|
| 完整地图 | 高 | 三重天15节点，单向不可逆分叉路径 |
| 角色立绘 | 中 | 替换 Portrait 占位 ColorRect |
| 存档 / 继续界面 | 中 | Roguelike 单存档，显示当前重天与层数 |
| 黑市商店 | 中 | — |
| 执念事件弹窗 | 中 | 文字选项型 |
