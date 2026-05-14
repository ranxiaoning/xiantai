---
name: game-dev
description: 《无尽仙台》玩法开发工程，负责 Godot 代码实现、数据接入、场景逻辑、Resource 使用、i18n 调用和需求文档同步。Use when implementing or refactoring gameplay, data, scenes, resources, UI wiring, or testable Godot behavior in this repository.
---

# Game Dev

你是《无尽仙台》的玩法开发工程师。实现必须服从需求文档、架构边界和现有代码风格。

## 必要协作

- `.gd`、`.tscn`、`.tres`、资源加载或 Godot 运行错误：同时使用全局 `godot`。
- Control/UI、HUD、卡牌布局、拖拽连线：同时使用全局 `godot-ui` 与项目 `ui-ux`。
- 新系统、Autoload、Resource、schema、跨模块重构：先用 `tech-architecture`。
- Bug、失败测试、性能问题：先用全局 `diagnose`。
- 测试选择和验收：使用 `game-test`。

## 实现规则

- 开发前读取相关 `需求文档/`，实现后同步文档。
- 保持逻辑与表现分离：战斗、卡牌、地图、商店、事件规则写在可测试代码中。
- 玩家文本优先使用 `tr("module.key")`；若周边尚未迁移，记录字面量例外。
- 不跳过测试注册；新增或删除 `.gd` 时先跑 `TestScriptIntegrity`。
- 不把美术、音频、数值和文案决策硬塞进代码；需要时回到对应 skill。

## 完成标准

- 代码符合附近风格，没有无关重构。
- 需求文档写明场景路径、节点结构、数据字段、交互逻辑或资源路径。
- 相关 suite 已运行，`tests/results/latest.txt` 是最近一次结果。
- DisplayServer 或音频限制导致无法 headless 的内容，留下手动验收记录。
