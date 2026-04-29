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

## 七、角色选择界面（CharacterSelect）✅ 已实现

**场景文件**：`scenes/CharacterSelect.tscn`  
**脚本**：`scripts/CharacterSelect.gd`

### 布局

| 区域 | 位置 | 内容 |
|------|------|------|
| 页面标题 | 顶部 2%–10% | "角色选择"（32px，居中） |
| 门派选择栏 SectBar | 顶部 10%–19%，水平 10%–90%，居中 | 每个门派一个 ToggleButton，ButtonGroup 互斥 |
| 主内容区 MainContent | 垂直 20%–88%，水平 2%–98% | 三栏横排 |
| ├ 弟子列表 CharListPanel | 固定宽 155px | 当前门派所有角色按钮（ButtonGroup 互斥） |
| ├ 角色详情 CharDetailPanel | 弹性 ratio 1.8 | 角色名、副标题、立绘、背景故事 |
| └ 属性面板 StatsPanel | 弹性 ratio 2.2 | 初始属性 / 天赋 / 英雄技能 |
| 开始游戏按钮 | 水平 30%–70%，垂直 90%–98% | 确认选择，跳转地图 |

### 节点结构

```
CharacterSelect (Control)
├── BG (TextureRect)              # 全屏背景图，随门派切换
├── Overlay (ColorRect)           # 半透明暗化遮罩
├── PageTitle (Label)             # "角色选择" 32px
├── SectBar (HBoxContainer) *    # 门派按钮行，动态创建
├── MainContent (HBoxContainer)
│   ├── CharListPanel (VBoxContainer, min 155px)
│   │   ├── CharListTitle (Label) # "── 弟子 ──"
│   │   └── CharListBox (VBoxContainer) *  # 角色按钮，动态创建
│   ├── VSep1 (VSeparator)
│   ├── CharDetailPanel (VBoxContainer, ratio 1.8)
│   │   └── CharPanelContainer/PadMargin/InnerBox/
│   │       ├── CharName (Label) *   # 36px
│   │       ├── CharTitle (Label) *  # 15px 金色
│   │       ├── Portrait (TextureRect) *  # 动态加载立绘
│   │       └── Lore (Label) *       # 自动换行
│   ├── VSep2 (VSeparator)
│   └── StatsPanel (VBoxContainer, ratio 2.2)
│       ├── StatsTitle / Stats（HPValue* / HPRegenValue* / LingLiValue* / DaoHuiValue* / DmgValue*）
│       ├── TalentPanel/TalentPad/TalentDesc *
│       └── SkillPanel/SkillPad/SkillDesc *
└── StartBtn (Button)             # 开始游戏
```

> `*` = `unique_name_in_owner = true`，脚本通过 `%NodeName` 访问

### 数据来源

- `CharacterDatabase.get_all_sects()` → 门派名称列表（按 `SECT_ORDER` 顺序）
- `CharacterDatabase.get_sect_data(sect)` → 门派元数据（`bg_path` 等）
- `CharacterDatabase.get_sect_characters(sect)` → 该门派所有角色列表
- `CharacterDatabase.get_character(id)` → 单个角色完整数据（含 `portrait_path`）

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
| 点击弟子按钮 | 切换 `_selected_char_id`，刷新右侧属性面板 |
| 点击"开始游戏" | `GameState.start_run(_selected_char_id)` → 跳转 `GameMap.tscn` |

### 手动验证要点

（headless 不可测，需 Godot Editor 运行）

- [ ] 默认进入时选中"万剑门"按钮，弟子列表显示"程天锋"，右侧属性/天赋正确
- [ ] 切换门派按钮时，弟子列表和背景图同步更新
- [ ] 点击弟子按钮，右侧面板立即刷新
- [ ] 点击"开始游戏"正常跳转至 GameMap.tscn

---

## 八、游戏地图界面（GameMap）✅ 已实现（第一重天，16层动态生成）

**场景文件**：`scenes/GameMap.tscn`  
**脚本**：`scripts/GameMap.gd`  
**地图生成**：`scripts/MapGenerator.gd`  
**连线绘制**：`scripts/MapDrawLayer.gd`

### 布局

| 区域 | 锚点 | 内容 |
|------|------|------|
| Header | 垂直 0–8% | 标题 + HP 显示 |
| MapScroll | 垂直 8–100% | 可垂直滚动的地图区域（禁止水平滚动） |
| NodePopup | 水平 15–85%，垂直 15–85% | 节点事件弹窗（篝火/商店/奇遇/起始叙事），初始隐藏 |
| VictoryPanel | 水平 20–80%，垂直 20–80% | Boss 击败后胜利面板，初始隐藏 |

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

所有节点图片通过 canvas_item shader 裁切为圆形（smoothstep 抗锯齿）。

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

连线颜色：已访问路径金色 `Color(0.75,0.7,0.3,0.8)`，未访问灰色 `Color(0.45,0.45,0.55,0.5)`。

### GameState 地图相关字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `map_nodes` | Dictionary | node_id → 节点数据（含 floor/col/type/next_ids/visited） |
| `map_floors` | Array | `floors[i]` = 第 i+1 层节点 ID 列表 |
| `map_current_floor` | int | 最近访问的层号（0=未开始） |
| `map_accessible_ids` | Array[String] | 当前可点击的节点 ID 列表 |
| `map_started` | bool | 是否已通过起始节点进入地图 |
| `pending_battle_node` | String | 待进入的战斗节点 ID |
| `pending_battle_node_type` | String | 节点类型（normal/elite/boss） |
| `pending_battle_node_floor` | int | 节点层号，供 EnemyDatabase 选敌 |

### 手动验证要点

（headless 不可测，需 Godot Editor 运行）

- [ ] 进入地图时只有起始节点亮起，第1层全部灰暗
- [ ] 点击起始节点弹出叙事文本，内容正确
- [ ] 点击"踏入轮回"后第1层节点全部解锁，地图滚动至第1层
- [ ] 点击战斗节点正确跳转战斗场景，返回后下一层解锁
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
- **抽牌动画**：普通抽牌、战斗开始抽 3 张、牌库耗尽后的洗牌重抽都从抽牌堆锚点飞入手牌；洗牌时旧手牌先飞回抽牌堆，再延迟飞出重抽卡。
- **悬停反馈**：卡牌悬停时 `z_index` 提升，平滑向上弹出并放大。
- **预览功能**：悬停卡牌时在上方显示高清预览。
- **提示信息**：资源不足时通过 Toast 弹出提示。
---

## 十、待办 / 后续界面

| 界面 | 优先级 | 说明 |
|------|--------|------|
| 战斗胜利奖励 | 高 | 三选一抽卡，按稀有度概率 |
| 完整地图 | 高 | 三重天15节点，单向不可逆分叉路径 |
| 角色立绘 | 中 | 替换 Portrait 占位 ColorRect |
| 存档 / 继续界面 | 中 | Roguelike 单存档，显示当前重天与层数 |
| 黑市商店 | 中 | — |
| 执念事件弹窗 | 中 | 文字选项型 |
