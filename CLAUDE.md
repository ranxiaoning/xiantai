# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Godot skill usage

This is a Godot game project. When working on `.gd`, `.tscn`, `.tres`, UI scenes, resources, scene loading, headless validation, exports, or Godot runtime errors, actively use the available Godot-related skills as needed, especially `godot`, `godot-ui`, `godot-architect`, `game-dev`, and `game-test`.

## 项目概述

**《无尽仙台》** 是一款类杀戮尖塔的回合制构筑卡牌游戏，修仙题材。游戏讲述玩家在"登仙台"中反复轮回、记忆积累、寻找破局之法的故事。

## 当前状态

- 需求文档：`需求文档/` 目录，含战斗/卡牌/地图/职业/怪物等完整设计文档
- 代码：Godot 4.3 项目，主菜单与选项界面已实现，战斗系统尚未开始

## 技术栈

- **引擎**：Godot 4.3+（GDScript）
- **界面**：GUI（类杀戮尖塔风格），拉伸模式 canvas_items + expand
- **多语言**：中文/英文，通过 `TranslationServer` 管理（locale: zh_CN / en）
- **平台**：Windows
- **运行**：用 Godot Editor 打开 `project.godot` 即可运行

## 项目目录结构

```
scenes/       # .tscn 场景文件
scripts/      # .gd 脚本（GlobalSettings 为 Autoload 单例）
i18n/         # 多语言翻译文件
theme/        # 主题/样式资源（待创建）
需求文档/      # 所有设计文档
```

## 关键模块

- `scripts/GlobalSettings.gd` — Autoload，负责设置的读写与应用（音量/分辨率/语言），存储到 `user://settings.cfg`
- `scenes/MainMenu.tscn` + `scripts/MainMenu.gd` — 主菜单（开始/选项/退出）
- `scenes/OptionsMenu.tscn` + `scripts/OptionsMenu.gd` — 选项界面（分辨率/全屏/三路音量/语言）

## 多语言

当前用字面中文字符串，后续替换为 `tr("key")` 调用，key 命名规范：`模块.子项`（如 `menu.start`、`options.resolution`）

## 核心系统架构（设计层面）

### 战斗系统
- **回合制**：玩家回合 ↔ 敌方回合交替
- **三大资源**：
  - **生命值**（HP）：归零即死亡
  - **灵力**（Energy）：每回合回复（默认+3），回合结束完整保留，可跨回合积累
  - **道行/剑意**（Sword Intent）：跨回合积累，无上限，不清零——这是区别于普通Roguelike的核心机制
- **伤害公式**：`(基础伤害 + 道行绝对值加成) × 状态百分比乘区`，先加减后乘除，向下取整
- **防御层级**：护体（永久罡气）→ 身形（临时格挡，回合结束清零）→ 生命值

### 牌库机制
- 抽牌堆 / 弃牌堆 / 耗尽（永久移除）三区
- 弃牌堆耗尽时自动洗牌补充抽牌堆
- 特殊词缀：耗尽(Exhaust)、保留(Retain)、溃散(Ethereal)、本源(Innate)、禁锢(Unplayable)
- 剑意词缀：**剑耗(X)**（消耗X剑意）、**底力(X)**（剑意≥X触发额外效果但不消耗）

### 卡牌体系（剑修职业，Ver 3.1）
- 三类卡：**术法牌**（攻击/01-44）、**秘法牌**（防御运转/45-85）、**道法牌**（全局被动/86-99）
- 四个稀有度：黄品(55%) / 玄品(30%) / 地品(10%) / 天品(5%)
- 初始牌组：剑气斩×10 + 剑气护体×10

### 地图系统
- 三重天（每重15节点 + Boss）+ 隐藏终局
- 节点类型：⚔️普通战斗 / 👹精英战斗 / 🔥篝火（调息或升级） / 💰黑市 / ❓奇遇事件 / 🚪天门Boss
- 单向不可逆路线，玩家从底部向上推进
- 第5、10层收束（强制节点），第5/10层前后分叉
- Boss结构：第一重天【剥皮仙君】（DPS检测）/ 第二重天【无面司命】（防守控制）/ 第三重天【收割者·巨灵神机/伪善之门】（流派检测）/ 隐藏终局【天宫之主】

### 战斗奖励流程
1. 战斗胜利 → 三选一抽卡（按稀有度概率）
2. 50%概率额外掉落消耗品（灵丹/阵法/符箓），背包上限10格

### 职业
- 当前已设计：万剑门 · 程天锋（初始天赋：游戏开始获得4层剑意）

## 需求文档结构

| 文件 | 内容 |
|------|------|
| `UI界面.md` | UI规范：菜单/选项/布局/视觉风格（已实现部分的设计依据） |
| `需求.txt` | 总体需求与展示方式 |
| `游戏背景.txt` | 世界观与叙事设定 |
| `战斗.md` | 完整战斗规则手册 |
| `卡牌.md` | 剑修完整卡牌数据表（Ver 3.1） |
| `局内地图.txt` | 地图机制与三重天结构 |
| `职业类型.txt` | 职业与角色天赋 |
| `怪物类型.txt` | 敌方单位设计 |
| `商店商品.txt` | 黑市商品列表 |
| `执念.txt` | 奇遇事件设计（55个，三重天分布） |
| `宝物.txt` | 宝物（Artifact）系统：R-01~R-23 完整数据、稀有度、触发规则 |

## 开发工作流

**每次完成一个功能模块的开发后，必须同时更新需求文档，并编写自动化测试，全部通过后才能继续下一个功能。**

流程如下：

1. **开发前**：先读取 `需求文档/` 中相关文档，确认规格
2. **开发完成** → 代码自查
3. **更新需求文档**：将实现细节（节点结构、属性、交互逻辑、场景文件路径）补充到 `需求文档/UI界面.md` 或对应文档中，保持文档与代码同步
4. 在 `tests/suites/` 下创建或更新对应的测试套件
5. 在 `tests/TestMain.gd` 的 `_initialize()` 注册区追加 `_maybe_run("TestXxx", func(): return load(...).new())`
6. **精准运行受影响的 suite**（见下方映射表），结果写入 `tests/results/latest.txt`
7. 若存在失败，修复后重新执行，直至全部通过
8. 涉及 DisplayServer/场景跳转的 UI 测试无法 headless 自动化，记录在对应的 `.md` 文件中留人工验证

**测试运行命令**：

```batch
# 精准测试（日常开发，只跑受影响的 suite）
run_suite.bat TestBattleEngineLogic
run_suite.bat TestBattleEngineLogic TestCardEffects TestEnemyBehavior

# 全量回归（仅限 git commit 前）
run_regression.bat
```

> **严禁在日常开发中随意运行 `run_regression.bat`**，应按改动范围只跑对应 suite。

**改动文件 → 需运行的 Suite 映射**：

| 改动文件 | 运行的 Suite |
|---|---|
| `BattleEngine.gd` | TestBattleEngineLogic + TestCardEffects + TestEnemyBehavior |
| `MapGenerator.gd` | TestMapGenerator |
| `data/CardDatabase.gd` | TestCardEffects + TestSpiritStones |
| `data/EnemyDatabase.gd` | TestEnemyBehavior |
| `data/CharacterDatabase.gd` | TestCharacterSelect |
| `GameState.gd` | TestSpiritStones |
| `GlobalSettings.gd` | TestGlobalSettings |
| `Logger.gd` / `Log.gd` | TestLogger |
| `BattleScene.gd` / `CardRenderer.gd` | TestHandLayout |
| 任意 `.gd` 新增或删除 | TestScriptIntegrity（**总是先跑**） |

**测试框架说明**：
- 入口：`tests/TestMain.gd`（extends SceneTree，headless 运行）
- 结果文件：`tests/results/latest.txt`（退出码 0=通过，1=失败）
- 诊断工具：`tests/suites/TestEnemyDebug.gd`（不纳入自动化，手动调试时直接 `-s` 运行）

## 开发注意事项

- GUI模式下，拖拽打出需要目标的卡牌时必须渲染指向目标的连线特效
- 道法牌（Power）打出后自动移出本局，无需标注"耗尽"
- 所有能回复生命或造成免死/秒杀效果的卡牌必须带【耗尽】词缀（防止刷血漏洞）
- 高难度解锁"飞升/枷锁"系统后地图出现迷雾路线和燃血刑官变体

