# 灵石系统 + 战斗奖励页面 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在地图页面显示灵石数量（初始100），战斗胜利后弹出"大包小包"奖励页面，支持3选1卡牌和灵石拾取。

**Architecture:** GameState 持有 spirit_stones 字段跨场景持久化；RewardScene.gd 作为 Control 节点叠加在 BattleScene 上处理奖励逻辑，完成后 emit completed 信号触发场景跳转；CardDatabase 新增 get_all_cards() 供奖励系统按稀有度权重抽卡。

**Tech Stack:** Godot 4.3 GDScript，纯代码构建 UI，无外部 shader。

---

## 文件清单

| 操作 | 文件 | 职责 |
|------|------|------|
| 修改 | `scripts/GameState.gd` | 新增 spirit_stones 字段与 add_spirit_stones() |
| 修改 | `scripts/data/CardDatabase.gd` | 新增 get_all_cards() |
| 修改 | `scripts/GameMap.gd` | Header 区域动态添加灵石 Label |
| 新建 | `scripts/RewardScene.gd` | 奖励页面全部 UI + 逻辑（叠加层） |
| 修改 | `scripts/BattleScene.gd` | 胜利时改为显示 RewardScene，失败路径不变 |
| 新建 | `tests/suites/TestSpiritStones.gd` | 灵石系统单元测试 |
| 修改 | `tests/TestMain.gd` | 注册新测试套件 |

---

## Task 1：GameState + CardDatabase 基础层

**Files:**
- Modify: `scripts/GameState.gd`
- Modify: `scripts/data/CardDatabase.gd`
- Create: `tests/suites/TestSpiritStones.gd`
- Modify: `tests/TestMain.gd`

- [ ] **Step 1：在 GameState.gd 新增灵石字段和方法**

在 `var dao_xing_battle_start` 那行之后插入：

```gdscript
# ── 灵石（局内货币）─────────────────────────────────────────────
var spirit_stones: int = 0
```

在 `start_run()` 的 `ling_li_regen_bonus = 0` 那行后插入：

```gdscript
	spirit_stones = 100
```

在文件末尾 `get_map_node()` 之后追加：

```gdscript
func add_spirit_stones(amount: int) -> void:
	spirit_stones += amount
	Log.info("GameState", "获得 %d 灵石，现有 %d" % [amount, spirit_stones])
```

- [ ] **Step 2：在 CardDatabase.gd 末尾追加 get_all_cards()**

在 `get_starting_deck_ids()` 函数之后追加：

```gdscript
func get_all_cards() -> Array[Dictionary]:
	if _all.is_empty():
		_load_cards_from_json()
	var result: Array[Dictionary] = []
	for card in _all.values():
		result.append(card.duplicate())
	return result
```

- [ ] **Step 3：写测试文件 `tests/suites/TestSpiritStones.gd`**

```gdscript
## TestSpiritStones.gd
## 验证灵石系统的初始值与加减逻辑。
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestSpiritStones ]")
	_t("test_initial_spirit_stones")
	_t("test_add_spirit_stones")
	_t("test_get_all_cards_not_empty")
	_t("test_get_all_cards_have_rarity")
	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_initial_spirit_stones() -> void:
	GameState.start_run("chen_tian_feng")
	_assert_eq(GameState.spirit_stones, 100, "start_run 后初始灵石应为 100")

func test_add_spirit_stones() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.add_spirit_stones(30)
	_assert_eq(GameState.spirit_stones, 130, "加 30 后应为 130")
	GameState.add_spirit_stones(60)
	_assert_eq(GameState.spirit_stones, 190, "再加 60 后应为 190")

func test_get_all_cards_not_empty() -> void:
	var cards := CardDatabase.get_all_cards()
	_assert_true(cards.size() > 0, "get_all_cards 返回非空数组")

func test_get_all_cards_have_rarity() -> void:
	var cards := CardDatabase.get_all_cards()
	_assert_true(cards[0].has("rarity"), "卡牌字典含 rarity 字段")


# ── 断言工具 ──────────────────────────────────────────────────

func _t(method: String) -> void:
	call(method)

func _assert_eq(a, b, msg: String) -> void:
	if a == b:
		_pass_count += 1
		_lines.append("  ✅ " + msg)
	else:
		_fail_count += 1
		_lines.append("  ❌ " + msg + " （期望 %s，实际 %s）" % [str(b), str(a)])

func _assert_true(cond: bool, msg: String) -> void:
	if cond:
		_pass_count += 1
		_lines.append("  ✅ " + msg)
	else:
		_fail_count += 1
		_lines.append("  ❌ " + msg)
```

- [ ] **Step 4：在 `tests/TestMain.gd` 注册新套件**

在 `_run_suite(load("res://tests/suites/TestEnemyBehavior.gd").new())` 之后插入：

```gdscript
	_run_suite(load("res://tests/suites/TestSpiritStones.gd").new())
```

- [ ] **Step 5：运行测试**

```
run_tests.bat
```

预期 `tests/results/latest.txt` 包含：
```
[ TestSpiritStones ]
  ✅ start_run 后初始灵石应为 100
  ✅ 加 30 后应为 130
  ✅ 再加 60 后应为 190
  ✅ get_all_cards 返回非空数组
  ✅ 卡牌字典含 rarity 字段
  → 5 通过  0 失败
```

- [ ] **Step 6：提交**

```bash
git add scripts/GameState.gd scripts/data/CardDatabase.gd tests/suites/TestSpiritStones.gd tests/TestMain.gd
git commit -m "feat: add spirit_stones to GameState and get_all_cards to CardDatabase"
```

---

## Task 2：地图页面灵石标识

**Files:**
- Modify: `scripts/GameMap.gd`

- [ ] **Step 1：在 GameMap.gd 的 `@onready` 区域追加变量**

在 `var _pulse_target: BaseButton = null` 这行之后加：

```gdscript
var _stones_label: Label = null
```

- [ ] **Step 2：在 `_ready()` 的 `_update_hp_label()` 调用后加入灵石 label 初始化**

在 `_update_hp_label()` 调用行之后插入：

```gdscript
	_setup_stones_label()
```

- [ ] **Step 3：在 GameMap.gd 末尾追加两个方法**

```gdscript
func _setup_stones_label() -> void:
	var header: Control = $Header
	_stones_label = Label.new()
	_stones_label.name = "StonesLabel"
	_stones_label.add_theme_font_size_override("font_size", 16)
	_stones_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40))
	_stones_label.layout_mode = 1
	_stones_label.anchor_left   = 1.0
	_stones_label.anchor_right  = 1.0
	_stones_label.anchor_top    = 0.0
	_stones_label.anchor_bottom = 1.0
	_stones_label.offset_left   = -180.0
	_stones_label.offset_right  = -12.0
	_stones_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stones_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_stones_label)
	_update_stones_label()


func _update_stones_label() -> void:
	if _stones_label:
		_stones_label.text = "💎 %d 灵石" % GameState.spirit_stones
```

- [ ] **Step 4：所有调用 `_update_hp_label()` 的地方也同步调用 `_update_stones_label()`**

在 GameMap.gd 中搜索所有 `_update_hp_label()` 调用（共3处：`_ready()`、第484行、第539行），每处调用后各加一行：

```gdscript
	_update_stones_label()
```

- [ ] **Step 5：验证（人工）**

启动游戏，进入地图，Header 右侧应显示 "💎 100 灵石"，打完战斗返回地图后灵石数量反映实际值。

- [ ] **Step 6：提交**

```bash
git add scripts/GameMap.gd
git commit -m "feat: add spirit stone indicator to GameMap header"
```

---

## Task 3：创建 RewardScene.gd

**Files:**
- Create: `scripts/RewardScene.gd`

这是最大的任务。RewardScene 是一个 Control 覆盖层，完全通过代码构建 UI。

- [ ] **Step 1：创建 `scripts/RewardScene.gd`**

```gdscript
## RewardScene.gd
## 战斗奖励页面：大包（卡牌奖励 + 灵石奖励）叠加在 BattleScene 上方。
## 使用方：add_child(instance)，监听 completed 信号后 change_scene。
extends Control

signal completed

## 由调用方在 add_child 前设置
var battle_type: String = "normal"   # "normal" | "elite"

# ── 稀有度权重 ─────────────────────────────────────────────────
const RARITY_LIST    := ["黄品", "玄品", "地品", "天品"]
const RARITY_WEIGHTS := [55,     30,     10,     5   ]
const RARITY_COLORS  := {
	"黄品": Color(0.85, 0.72, 0.20, 1.0),
	"玄品": Color(0.35, 0.55, 0.95, 1.0),
	"地品": Color(0.72, 0.25, 0.88, 1.0),
	"天品": Color(0.95, 0.42, 0.10, 1.0),
}

# ── 内部状态 ──────────────────────────────────────────────────
var _reward_cards: Array[Dictionary] = []
var _selected_idx: int = -1      # -1 = 未选择
var _card_resolved: bool = false # 已跳过 or 已确认
var _stone_collected: bool = false

# ── UI 引用 ───────────────────────────────────────────────────
var _card_slots: Array[Button] = []
var _confirm_btn: Button
var _skip_btn: Button
var _collect_btn: Button
var _continue_btn: Button
var _detail_popup: PanelContainer
var _detail_name_lbl: Label
var _detail_rarity_lbl: Label
var _detail_cost_lbl: Label
var _detail_desc_lbl: Label
var _detail_select_btn: Button
var _stone_amount: int = 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200

	_stone_amount = 60 if battle_type == "elite" else 30
	_reward_cards = _pick_reward_cards()

	_build_ui()


# ── 卡牌抽取（按稀有度权重，不重复）─────────────────────────

func _pick_reward_cards() -> Array[Dictionary]:
	var all_cards := CardDatabase.get_all_cards()
	var result: Array[Dictionary] = []
	var used_ids: Array[String]   = []

	for _i in 3:
		var roll := randi() % 100
		var chosen_rarity := "黄品"
		var cumulative := 0
		for j in RARITY_LIST.size():
			cumulative += RARITY_WEIGHTS[j]
			if roll < cumulative:
				chosen_rarity = RARITY_LIST[j]
				break

		var pool: Array[Dictionary] = []
		for c in all_cards:
			if c["rarity"] == chosen_rarity and c["id"] not in used_ids:
				pool.append(c)
		if pool.is_empty():
			for c in all_cards:
				if c["id"] not in used_ids:
					pool.append(c)
		if pool.is_empty():
			break

		var picked: Dictionary = pool[randi() % pool.size()]
		result.append(picked)
		used_ids.append(picked["id"])

	return result


# ── UI 构建 ───────────────────────────────────────────────────

func _build_ui() -> void:
	# 半透明黑色遮罩
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# 大包面板（居中）
	var bag := PanelContainer.new()
	bag.custom_minimum_size = Vector2(920, 540)
	var bag_style := StyleBoxFlat.new()
	bag_style.bg_color = Color(0.10, 0.08, 0.05, 0.98)
	bag_style.border_width_left   = 3
	bag_style.border_width_top    = 3
	bag_style.border_width_right  = 3
	bag_style.border_width_bottom = 3
	bag_style.border_color = Color(0.70, 0.55, 0.22, 1.0)
	bag_style.corner_radius_top_left     = 12
	bag_style.corner_radius_top_right    = 12
	bag_style.corner_radius_bottom_right = 12
	bag_style.corner_radius_bottom_left  = 12
	bag_style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	bag_style.shadow_size  = 18
	bag.add_theme_stylebox_override("panel", bag_style)
	bag.set_anchors_preset(Control.PRESET_CENTER)
	bag.offset_left   = -460.0
	bag.offset_right  =  460.0
	bag.offset_top    = -270.0
	bag.offset_bottom =  270.0
	add_child(bag)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   22)
	margin.add_theme_constant_override("margin_right",  22)
	margin.add_theme_constant_override("margin_top",    18)
	margin.add_theme_constant_override("margin_bottom", 18)
	bag.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = "✦  战斗奖励  ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.48))
	vbox.add_child(title)

	# 两个小包横排
	var bags_row := HBoxContainer.new()
	bags_row.add_theme_constant_override("separation", 18)
	bags_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(bags_row)

	_build_card_bag(bags_row)
	_build_stone_bag(bags_row)

	# 继续前行按钮（居右）
	var bottom_row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(spacer)
	_continue_btn = _make_button("继续前行", Color(0.28, 0.55, 0.28, 1.0))
	_continue_btn.custom_minimum_size = Vector2(140, 44)
	_continue_btn.pressed.connect(_on_continue_pressed)
	bottom_row.add_child(_continue_btn)
	vbox.add_child(bottom_row)

	# 卡牌详情弹窗（默认隐藏）
	_build_detail_popup()


func _build_card_bag(parent: HBoxContainer) -> void:
	var bag := PanelContainer.new()
	bag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	bag.add_theme_stylebox_override("panel", _make_small_bag_style(Color(0.08, 0.10, 0.16)))
	parent.add_child(bag)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",   14)
	m.add_theme_constant_override("margin_right",  14)
	m.add_theme_constant_override("margin_top",    12)
	m.add_theme_constant_override("margin_bottom", 12)
	bag.add_child(m)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	m.add_child(vb)

	var lbl := Label.new()
	lbl.text = "卡牌奖励（3选1）"
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90))
	vb.add_child(lbl)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 10)
	slots_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(slots_row)

	_card_slots.clear()
	for i in _reward_cards.size():
		var slot := _build_card_slot(_reward_cards[i], i)
		slots_row.add_child(slot)
		_card_slots.append(slot)

	# 操作行
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	vb.add_child(action_row)

	_skip_btn = _make_button("跳过", Color(0.35, 0.35, 0.35, 1.0))
	_skip_btn.custom_minimum_size = Vector2(90, 38)
	_skip_btn.pressed.connect(_on_skip_pressed)
	action_row.add_child(_skip_btn)

	_confirm_btn = _make_button("确认选择", Color(0.20, 0.45, 0.75, 1.0))
	_confirm_btn.custom_minimum_size = Vector2(110, 38)
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	action_row.add_child(_confirm_btn)


func _build_card_slot(card: Dictionary, idx: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(172, 240)
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.clip_contents = true

	var rarity: String = card.get("rarity", "黄品")
	var rc: Color = RARITY_COLORS.get(rarity, Color.WHITE)
	var normal_style := _make_card_slot_style(rc, false)
	var hover_style  := _make_card_slot_style(rc, true)
	btn.add_theme_stylebox_override("normal",  normal_style)
	btn.add_theme_stylebox_override("hover",   hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	# 内部 VBoxContainer（Label 叠加）
	var inner := VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 4)
	btn.add_child(inner)

	# 稀有度色条
	var rarity_bar := ColorRect.new()
	rarity_bar.color = rc
	rarity_bar.custom_minimum_size = Vector2(0, 5)
	rarity_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(rarity_bar)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left",  8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top",   6)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(pad)

	var text_vb := VBoxContainer.new()
	text_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vb.add_theme_constant_override("separation", 5)
	pad.add_child(text_vb)

	var name_lbl := Label.new()
	name_lbl.text = card.get("name", "")
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vb.add_child(name_lbl)

	var rarity_lbl := Label.new()
	rarity_lbl.text = rarity
	rarity_lbl.add_theme_font_size_override("font_size", 12)
	rarity_lbl.add_theme_color_override("font_color", rc)
	rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vb.add_child(rarity_lbl)

	var type_lbl := Label.new()
	type_lbl.text = _card_type_display(card.get("card_type", ""))
	type_lbl.add_theme_font_size_override("font_size", 12)
	type_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.80))
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vb.add_child(type_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "灵%d · 道%d" % [card.get("ling_li", 0), card.get("dao_hui", 0)]
	cost_lbl.add_theme_font_size_override("font_size", 12)
	cost_lbl.add_theme_color_override("font_color", Color(0.60, 0.85, 1.0))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vb.add_child(cost_lbl)

	var spacer_ctrl := Control.new()
	spacer_ctrl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vb.add_child(spacer_ctrl)

	var desc_lbl := Label.new()
	desc_lbl.text = card.get("desc", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.78, 0.72))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vb.add_child(desc_lbl)

	btn.pressed.connect(_on_card_slot_pressed.bind(idx))
	return btn


func _build_stone_bag(parent: HBoxContainer) -> void:
	var bag := PanelContainer.new()
	bag.custom_minimum_size = Vector2(220, 0)
	bag.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag.add_theme_stylebox_override("panel", _make_small_bag_style(Color(0.12, 0.10, 0.05)))
	parent.add_child(bag)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",   16)
	m.add_theme_constant_override("margin_right",  16)
	m.add_theme_constant_override("margin_top",    12)
	m.add_theme_constant_override("margin_bottom", 12)
	bag.add_child(m)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(vb)

	var title := Label.new()
	title.text = "灵石奖励"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90))
	vb.add_child(title)

	var icon_lbl := Label.new()
	icon_lbl.text = "💎"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 48)
	vb.add_child(icon_lbl)

	var amount_lbl := Label.new()
	amount_lbl.text = "+ %d" % _stone_amount
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_lbl.add_theme_font_size_override("font_size", 28)
	amount_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.30))
	vb.add_child(amount_lbl)

	var desc := Label.new()
	desc.text = "（%s）" % ("精英战斗" if battle_type == "elite" else "普通战斗")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
	vb.add_child(desc)

	_collect_btn = _make_button("拾取", Color(0.60, 0.48, 0.12, 1.0))
	_collect_btn.custom_minimum_size = Vector2(110, 42)
	_collect_btn.pressed.connect(_on_collect_pressed)
	vb.add_child(_collect_btn)


func _build_detail_popup() -> void:
	_detail_popup = PanelContainer.new()
	_detail_popup.custom_minimum_size = Vector2(380, 300)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.08, 0.98)
	style.border_width_left   = 2
	style.border_width_top    = 2
	style.border_width_right  = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.70, 0.55, 0.22, 1.0)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left  = 8
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size  = 14
	_detail_popup.add_theme_stylebox_override("panel", style)
	_detail_popup.set_anchors_preset(Control.PRESET_CENTER)
	_detail_popup.offset_left   = -190.0
	_detail_popup.offset_right  =  190.0
	_detail_popup.offset_top    = -150.0
	_detail_popup.offset_bottom =  150.0
	_detail_popup.z_index = 10
	_detail_popup.hide()
	add_child(_detail_popup)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",   18)
	m.add_theme_constant_override("margin_right",  18)
	m.add_theme_constant_override("margin_top",    14)
	m.add_theme_constant_override("margin_bottom", 14)
	_detail_popup.add_child(m)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)

	_detail_name_lbl = Label.new()
	_detail_name_lbl.add_theme_font_size_override("font_size", 22)
	_detail_name_lbl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(_detail_name_lbl)

	_detail_rarity_lbl = Label.new()
	_detail_rarity_lbl.add_theme_font_size_override("font_size", 14)
	vb.add_child(_detail_rarity_lbl)

	_detail_cost_lbl = Label.new()
	_detail_cost_lbl.add_theme_font_size_override("font_size", 14)
	_detail_cost_lbl.add_theme_color_override("font_color", Color(0.60, 0.85, 1.0))
	vb.add_child(_detail_cost_lbl)

	var sep := HSeparator.new()
	vb.add_child(sep)

	_detail_desc_lbl = Label.new()
	_detail_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_desc_lbl.add_theme_font_size_override("font_size", 14)
	_detail_desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	_detail_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_detail_desc_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vb.add_child(btn_row)

	var close_btn := _make_button("关闭", Color(0.30, 0.30, 0.30, 1.0))
	close_btn.custom_minimum_size = Vector2(80, 36)
	close_btn.pressed.connect(func(): _detail_popup.hide())
	btn_row.add_child(close_btn)

	_detail_select_btn = _make_button("选择此牌", Color(0.20, 0.45, 0.75, 1.0))
	_detail_select_btn.custom_minimum_size = Vector2(100, 36)
	_detail_select_btn.pressed.connect(_on_detail_select_pressed)
	btn_row.add_child(_detail_select_btn)


# ── 事件回调 ──────────────────────────────────────────────────

func _on_card_slot_pressed(idx: int) -> void:
	if _card_resolved:
		return
	var card: Dictionary = _reward_cards[idx]
	_detail_name_lbl.text = card.get("name", "")
	var rarity: String = card.get("rarity", "黄品")
	_detail_rarity_lbl.text = "◆ " + rarity + "  " + _card_type_display(card.get("card_type", ""))
	_detail_rarity_lbl.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color.WHITE))
	_detail_cost_lbl.text = "消耗：灵力 %d  道慧 %d" % [card.get("ling_li", 0), card.get("dao_hui", 0)]
	_detail_desc_lbl.text = card.get("desc", "")
	_detail_select_btn.set_meta("card_idx", idx)
	_detail_popup.show()


func _on_detail_select_pressed() -> void:
	var idx: int = _detail_select_btn.get_meta("card_idx", -1)
	if idx < 0 or idx >= _card_slots.size():
		return
	_detail_popup.hide()
	# 更新选中状态
	_selected_idx = idx
	_confirm_btn.disabled = false
	for i in _card_slots.size():
		var rc: Color = RARITY_COLORS.get(_reward_cards[i].get("rarity", "黄品"), Color.WHITE)
		var selected: bool = (i == _selected_idx)
		_card_slots[i].add_theme_stylebox_override("normal", _make_card_slot_style(rc, selected))


func _on_skip_pressed() -> void:
	_card_resolved = true
	_skip_btn.disabled    = true
	_confirm_btn.disabled = true
	for slot in _card_slots:
		slot.disabled = true
	Log.info("RewardScene", "跳过卡牌奖励")


func _on_confirm_pressed() -> void:
	if _selected_idx < 0:
		return
	var card: Dictionary = _reward_cards[_selected_idx]
	GameState.deck.append(card["id"])
	_card_resolved = true
	_skip_btn.disabled    = true
	_confirm_btn.disabled = true
	for slot in _card_slots:
		slot.disabled = true
	Log.info("RewardScene", "选择卡牌：%s（id=%s）" % [card.get("name", ""), card["id"]])


func _on_collect_pressed() -> void:
	GameState.add_spirit_stones(_stone_amount)
	_stone_collected = true
	_collect_btn.text = "已拾取"
	_collect_btn.disabled = true
	Log.info("RewardScene", "拾取 %d 灵石" % _stone_amount)


func _on_continue_pressed() -> void:
	completed.emit()
	queue_free()


# ── 工具方法 ──────────────────────────────────────────────────

func _card_type_display(card_type: String) -> String:
	match card_type:
		"attack": return "术法"
		"skill":  return "秘法"
		"power":  return "道法"
	return card_type


func _make_button(label_text: String, border_c: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 15)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(border_c.r * 0.25, border_c.g * 0.25, border_c.b * 0.25, 0.92)
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	s.border_color = border_c
	s.corner_radius_top_left     = 5
	s.corner_radius_top_right    = 5
	s.corner_radius_bottom_right = 5
	s.corner_radius_bottom_left  = 5
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(border_c.r * 0.40, border_c.g * 0.40, border_c.b * 0.40, 0.95)
	h.border_color = border_c.lightened(0.25)
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	return btn


func _make_card_slot_style(rarity_color: Color, selected: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.10, 0.14, 0.95) if not selected else Color(0.15, 0.15, 0.22, 0.98)
	s.border_width_left   = 2 if not selected else 3
	s.border_width_top    = 2 if not selected else 3
	s.border_width_right  = 2 if not selected else 3
	s.border_width_bottom = 2 if not selected else 3
	s.border_color = rarity_color if not selected else rarity_color.lightened(0.3)
	s.corner_radius_top_left     = 6
	s.corner_radius_top_right    = 6
	s.corner_radius_bottom_right = 6
	s.corner_radius_bottom_left  = 6
	if selected:
		s.shadow_color = rarity_color
		s.shadow_size  = 8
	return s


func _make_small_bag_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.45, 0.38, 0.18, 1.0)
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left  = 8
	return s
```

- [ ] **Step 2：提交**

```bash
git add scripts/RewardScene.gd
git commit -m "feat: create RewardScene with card selection and spirit stone reward UI"
```

---

## Task 4：接入 BattleScene 胜利流程

**Files:**
- Modify: `scripts/BattleScene.gd`

- [ ] **Step 1：修改 `_on_battle_ended` 中的胜利分支**

找到 BattleScene.gd 中（约第 350 行）：

```gdscript
func _on_battle_ended(player_won: bool) -> void:
	end_turn_btn.disabled = true
	skill_btn.disabled    = true
	if player_won:
		result_label.text = "战斗胜利！\n\nHP 剩余：%d" % _engine.s["player_hp"]
		result_btn.text   = "返回地图"
	else:
		result_label.text = "你已倒下……\n\n但记忆留存，下次会更强。"
		result_btn.text   = "返回主菜单"
	result_panel.show()
```

替换为：

```gdscript
func _on_battle_ended(player_won: bool) -> void:
	end_turn_btn.disabled = true
	skill_btn.disabled    = true
	if player_won:
		_show_reward_scene()
	else:
		result_label.text = "你已倒下……\n\n但记忆留存，下次会更强。"
		result_btn.text   = "返回主菜单"
		result_panel.show()


func _show_reward_scene() -> void:
	var reward = load("res://scripts/RewardScene.gd").new()
	reward.battle_type = GameState.pending_battle_node_type
	reward.completed.connect(_on_reward_completed)
	add_child(reward)


func _on_reward_completed() -> void:
	get_tree().change_scene_to_file(GAME_MAP_SCENE)
```

- [ ] **Step 2：提交**

```bash
git add scripts/BattleScene.gd
git commit -m "feat: show RewardScene after battle victory instead of plain result panel"
```

---

## Task 5：运行全量测试并人工验证

- [ ] **Step 1：运行自动化测试**

```
run_tests.bat
```

预期：`tests/results/latest.txt` 全部通过，`TestSpiritStones` 5项均为 ✅。

- [ ] **Step 2：人工验证清单**

在 Godot Editor 中运行游戏：

1. 进入 CharacterSelect → 开始游戏 → 进入地图，Header 右侧显示 "💎 100 灵石"
2. 点击战斗节点进入战斗，击败敌人
3. 奖励页面弹出：
   - 左侧 3 张卡牌（稀有度边框颜色各不同）
   - 右侧显示 "💎 +30"（普通怪）或 "+60"（精英）
4. 点击卡牌 → 详情弹窗显示名称/稀有度/费用/描述
5. 点击"选择此牌" → 卡牌高亮，"确认选择"可点
6. 点击"确认选择" → 卡牌加入牌组
7. 点击"拾取" → 收到灵石，按钮变为"已拾取"
8. 点击"继续前行" → 返回地图，Header 灵石数已更新
9. 回到地图：点击"跳过"后直接点"继续前行"，牌组不变，灵石也不变
10. 失败流程：点败 → 仍显示"返回主菜单"旧面板（不受影响）

- [ ] **Step 3：最终提交**

```bash
git add .
git commit -m "feat: spirit stones system and post-battle reward screen complete"
```

---

## 稀有度权重速查

| 稀有度 | 权重 | 概率 | 颜色 |
|--------|------|------|------|
| 黄品   | 55   | 55%  | `Color(0.85, 0.72, 0.20)` |
| 玄品   | 30   | 30%  | `Color(0.35, 0.55, 0.95)` |
| 地品   | 10   | 10%  | `Color(0.72, 0.25, 0.88)` |
| 天品   | 5    |  5%  | `Color(0.95, 0.42, 0.10)` |

## 灵石掉落

| 节点类型 | 灵石数 |
|----------|--------|
| normal   | 30     |
| elite    | 60     |
