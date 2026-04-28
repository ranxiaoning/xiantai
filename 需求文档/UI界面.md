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

## 八、游戏地图界面（GameMap）✅ 已实现（第一重天原型）

**场景文件**：`scenes/GameMap.tscn`  
**脚本**：`scripts/GameMap.gd`

### 布局

| 区域 | 内容 |
|------|------|
| 顶部标题 | "登仙台 · 第一重天"（24px，金色） |
| 地图区（Map） | 出生节点 + 连线 + 战斗节点 |
| 对话弹窗（DialogPanel） | 叙事文本 + 继续按钮，初始隐藏 |

### 节点坐标（绝对像素，1280×720 基准）

| 节点 | 位置 | 说明 |
|------|------|------|
| SpawnNode（Button） | (580, 440)–(700, 520) | 出生节点，初始可点击 |
| Connector（Line2D） | (640,480) → (640,260) | 节点连线，宽度3 |
| BattleNode（Button） | (580, 180)–(700, 260) | 战斗节点，初始禁用 |

### 交互流程

```
点击 SpawnNode
  → 显示 DialogPanel（叙事文本）
  → 点击"继续前行"
  → 隐藏弹窗，GameState.spawn_node_visited = true
  → SpawnNode 变灰，BattleNode 解锁

点击 BattleNode（需先访问 SpawnNode）
  → GameState.pending_battle_node = "battle_node_01"
  → 跳转 Battle.tscn
```

### 出生节点叙事文本

> 登仙台的大门轰然洞开。无尽的杀戮与轮回在等待着你。你还记得，上一次死在这里的感觉。但这一次，你的剑更稳了。

### 状态持久化

| 字段 | 类型 | 说明 |
|------|------|------|
| `GameState.spawn_node_visited` | bool | 出生节点是否已访问，控制战斗节点可用性 |
| `GameState.pending_battle_node` | String | 待进入的战斗节点 ID，传递给战斗场景 |

---

## 九、战斗界面（Battle）✅ 已实现

**场景文件**：`scenes/Battle.tscn`  
**脚本**：`scripts/BattleScene.gd`

### 布局区域

| 区域 | 锚点（屏幕占比）| 内容 |
|------|----------------|------|
| EnemyArea | 水平 25–75%，垂直 2–35% | 敌人信息 |
| PlayerArea | 水平 2–55%，垂直 58–78% | 玩家资源 |
| SidePanel | 水平 82–99%，垂直 38–78% | 操作按钮 |
| LogPanel | 水平 56–81%，垂直 38–78% | 战斗日志 |
| HandArea | 水平全宽，垂直 79–100% | 手牌区 |
| ResultPanel | 水平 25–75%，垂直 20–80% | 结算弹窗（初始隐藏） |

### 敌人区节点（EnemyArea/）

```
EnemyName       # 敌人名（22px，红色）
EnemyHPBar      # HP进度条
EnemyHPLabel    # "HP X / Y"
EnemyShieldLabel # "护体 X"（蓝色，为0时隐藏文字）
IntentLabel     # "意图：XXX"（金色）
EnemyStatusLabel # 状态词条（紫色）
```

### 玩家区节点（PlayerArea/）

```
HPSection/
├── HPBar       # HP进度条
└── HPLabel     # "HP X / Y"
ResourceSection/
├── ShieldLabel  # "护体 X"（蓝色）
├── LingLiLabel  # "灵力 X/Y"（绿色）
├── DaoHuiLabel  # "道慧 X/Y"（紫色）
└── DaoXingLabel # "道行 X 层"（金色）
```

### 操作按钮（SidePanel/）

| 按钮 | 回调 | 禁用条件 |
|------|------|----------|
| EndTurnBtn | `_on_end_turn_pressed` | 非玩家回合 |
| SkillBtn | `_on_skill_btn_pressed` | 非玩家回合或道慧不足 |

技能按钮文字动态显示：`"剑意凝神\n(道慧X)"`

### 手牌区（HandArea/HandScroll/HandContainer）

手牌区容器已变更为 Control 节点，以此实现平滑的扇形铺展：
- 每张牌是动态创建的 Button（CardView 组件），尺寸 120×160 （`CardView` 中为 `100×179` 等比例）
- 布局逻辑：
  - **<= 5张时**：按固定间距（8px），计算每个卡片的坐标并执行平滑动画飞入，水平排开。
  - **> 5张时**：程序计算在保证不超出设计宽度下的收缩间距，卡牌会紧密水平排开且互相重叠，同样通过平滑进入展示，强制控制在一屏展示面内但没有任何扇形扭转。
- 交互悬停（Hover）：鼠标放到重叠卡牌上方时，该卡牌 `z_index` 设定为10，调用 Tween 动画并以一定距离弹出重叠堆。离开后动画归位。
- 状态展示：
  - 目前去掉了视觉上的灰色遮挡反馈，不可用时只进行了程序互动拦截而依然保持明亮的卡面展示。
- 点击 → 通过验证后执行 `_engine.play_card(card)`

### 日志区

最多显示 12 行，超出时滚动丢弃最旧行。

### 结算弹窗（ResultPanel）

| 结果 | 文本 | 按钮 | 跳转 |
|------|------|------|------|
| 胜利 | "战斗胜利！\nHP 剩余：X" | 返回地图 | `GameMap.tscn` |
| 失败 | "你已倒下……\n但记忆留存，下次会更强。" | 返回主菜单 | `MainMenu.tscn` |

### 战斗初始化流程

```
BattleScene._ready()
  → _init_battle()
      → 读取 GameState.character / deck / pending_battle_node
      → 实例化 BattleEngine（preload 加载）
      → 连接信号：state_changed / log_added / battle_ended
      → engine.init() + engine.start_battle()
      → _update_ui()
```

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
