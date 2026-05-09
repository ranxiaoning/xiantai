# 篝火升级卡牌功能设计文档

**日期**：2026-05-09  
**状态**：已批准，待实现

---

## 一、需求概述

在地图的篝火节点，玩家可以选择将牌组中的一张卡牌永久升级。升级后的卡牌在所有场合（牌组查看、战斗手牌、放大预览）均显示升级后的效果和名称。

---

## 二、升级状态编码（数据层）

**方案：ID 后缀编码**

- `GameState.deck: Array[String]` 保持不变，数组元素为卡牌 ID 字符串
- 升级后的卡牌 ID 追加 `"+"` 后缀，例如 `"5"` → `"5+"`
- `"5+"` 和 `"5"` 是同一张卡的不同状态，底层数据相同，`is_upgraded` 字段不同

**优势**：无需新数据结构，BattleEngine / RewardScreen / 现有测试零改动。

---

## 三、各模块改动

### 3.1 CardDatabase.gd

`get_card(id)` 新增逻辑：
- 若 `id` 以 `"+"` 结尾，去掉后缀查找基础卡，返回副本中强制 `is_upgraded = true`
- 新增静态方法 `is_upgraded_id(id: String) -> bool`，返回 `id.ends_with("+")`

### 3.2 CardRenderer.gd

`_place_text_center(_name_label, ...)` 调用处：
- 当 `_card_data.get("is_upgraded", false)` 为 true 时，名字追加 `"+"`，例如 `"剑气斩+"`

### 3.3 GameMap.gd

`_show_bonfire_popup()` 中：
- 保留自动回血逻辑（30% 最大 HP）
- `popup_btn1.text` 改为 `"升级卡牌"`（去掉「未实装」）
- `_on_popup_btn1_pressed()` 改为：关闭弹窗 → `get_tree().change_scene_to_file("res://scenes/BonfireUpgrade.tscn")`

### 3.4 BonfireUpgrade（新建）

**文件**：
- `scenes/BonfireUpgrade.tscn`
- `scripts/BonfireUpgrade.gd`

**场景结构**（全部通过代码构建，.tscn 只含根节点）：
```
Control (BonfireUpgrade, FULL_RECT)
├── ColorRect (半透明暗色背景)
├── Label (标题："🔥 篝火 · 选择一张卡牌升级")
├── Label (提示："悬停查看升级后效果，已升级的卡牌不可再次升级")
├── ScrollContainer (铺满中部)
│   └── GridContainer (5 列, h_separation=10, v_separation=10)
└── Button ("跳过", 底部居中)
```

**卡牌展示逻辑**：
- 遍历 `GameState.deck`，每张卡用 `CardViewScene` 渲染
- 已升级卡（ID 含 `"+"`）：`modulate.a = 0.45`，禁用点击
- 可升级卡：正常显示，点击后执行升级

**悬停预览**：
- 使用 `CardZoomOverlay`，显示**升级后**版本（`is_upgraded: true`）

**升级执行**：
```gdscript
func _upgrade_card(deck_index: int) -> void:
    var base_id := GameState.deck[deck_index].trim_suffix("+")
    GameState.deck[deck_index] = base_id + "+"
    get_tree().change_scene_to_file("res://scenes/GameMap.tscn")
```

**"跳过"**：直接 `get_tree().change_scene_to_file("res://scenes/GameMap.tscn")`

---

## 四、交互流程

```
玩家点击篝火节点
    → 弹窗出现（自动回复 HP，显示回复量）
    → [升级卡牌] → 跳转 BonfireUpgrade 全屏场景
        → 展示所有牌（已升级的半透明不可选）
        → 点击某张卡 → GameState.deck[i] 追加 "+" → 返回 GameMap
        → 点击"跳过" → 直接返回 GameMap
    → [继续前行] → 关闭弹窗，不升级，留在地图
```

---

## 五、显示效果

| 场合 | 已升级卡显示 |
|------|------------|
| 牌组弹窗（GameMap DeckOverlay） | 名字显示"剑气斩+"，描述显示升级后数值 |
| 战斗手牌 | 名字显示"剑气斩+"，描述显示升级后数值 |
| 放大预览（CardZoomOverlay） | 同上 |
| BonfireUpgrade 悬停预览 | 显示升级后效果（方便玩家决策） |

---

## 六、不在本次范围内

- 卡牌二次升级（每张卡只能升级一次）
- 篝火选项扩展（如"烤火休息"等其他选项）
- 商店/事件系统

---

## 七、测试要点

- `TestScriptIntegrity`：确保新脚本无语法错误
- `TestCardEffects`（如存在）：确认 `CardDatabase.get_card("5+")` 返回 `is_upgraded: true`
- 手动验证：
  1. 进入篝火节点，点击"升级卡牌"，确认跳转
  2. 选择一张卡升级，返回地图后打开牌组，确认名字含"+"且描述为升级值
  3. 进入战斗，确认升级牌在手牌中正确显示
  4. 点击"跳过"，确认牌组未变化
  5. 已升级的卡在 BonfireUpgrade 中为半透明不可选
