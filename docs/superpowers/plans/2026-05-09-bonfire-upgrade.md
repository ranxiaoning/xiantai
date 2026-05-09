# 篝火升级卡牌 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在篝火节点实装"升级卡牌"功能——全屏选牌UI、ID后缀编码升级状态、所有场合显示升级效果和"+"名称。

**Architecture:** 升级状态编码为卡牌ID后缀（`"5+"` = 已升级的ID=5卡牌），`CardDatabase.get_card("5+")` 透明剥离后缀并返回 `is_upgraded=true`；`CardRenderer` 追加"+"到卡名；新增 `BonfireUpgrade` 全屏场景承担升级交互流程，完成后调 `change_scene_to_file` 返回地图。

**Tech Stack:** Godot 4.3 GDScript，SceneTree.change_scene_to_file，CardView / CardZoomOverlay 组件复用

---

## 文件地图

| 文件 | 变更 | 职责 |
|------|------|------|
| `tests/suites/TestCardEffects.gd` | **新建** | 升级功能单元测试（TDD先写） |
| `scripts/data/CardDatabase.gd` | 修改 | 解析"+"后缀ID，返回`is_upgraded=true` |
| `scripts/CardRenderer.gd` | 修改 | 静态`get_display_name()`，名字追加"+" |
| `scripts/BonfireUpgrade.gd` | **新建** | 升级选牌场景全部逻辑 |
| `scenes/BonfireUpgrade.tscn` | **新建** | 最小根节点，挂脚本 |
| `scripts/GameMap.gd` | 修改 | 篝火按钮跳转BonfireUpgrade |
| `tests/suites/TestScriptIntegrity.gd` | 修改 | 注册新文件 |

---

## Task 1: 创建 TestCardEffects.gd（失败测试先行）

**Files:**
- Create: `tests/suites/TestCardEffects.gd`

- [ ] **Step 1: 创建测试文件（全部测试预期失败）**

文件路径：`tests/suites/TestCardEffects.gd`

```gdscript
## TestCardEffects.gd
extends RefCounted

const CardRendererScript = preload("res://scripts/CardRenderer.gd")

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestCardEffects ]")
	_t("test_get_card_plus_returns_upgraded")
	_t("test_get_card_plus_base_data_matches")
	_t("test_get_card_base_not_upgraded")
	_t("test_is_upgraded_id")
	_t("test_display_name_upgraded")
	_t("test_display_name_not_upgraded")
	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func _t(method: String) -> void:
	var result: Dictionary = call(method)
	if result.get("pass", false):
		_pass_count += 1
	else:
		_fail_count += 1
		_lines.append("    ✗ %s: %s" % [method, result.get("msg", "(no msg)")])


func test_get_card_plus_returns_upgraded() -> Dictionary:
	var card := CardDatabase.get_card("5+")
	if card.is_empty():
		return {"pass": false, "msg": "get_card('5+') returned empty dict"}
	if not card.get("is_upgraded", false):
		return {"pass": false, "msg": "expected is_upgraded=true, got false"}
	return {"pass": true}


func test_get_card_plus_base_data_matches() -> Dictionary:
	var base := CardDatabase.get_card("5")
	var up   := CardDatabase.get_card("5+")
	if base.is_empty() or up.is_empty():
		return {"pass": false, "msg": "one or both cards empty"}
	if base.get("name") != up.get("name"):
		return {"pass": false, "msg": "name mismatch: base=%s up=%s" % [base.get("name"), up.get("name")]}
	if int(base.get("ling_li", -1)) != int(up.get("ling_li", -2)):
		return {"pass": false, "msg": "ling_li mismatch: base=%d up=%d" % [int(base.get("ling_li")), int(up.get("ling_li"))]}
	return {"pass": true}


func test_get_card_base_not_upgraded() -> Dictionary:
	var card := CardDatabase.get_card("5")
	if card.get("is_upgraded", true):
		return {"pass": false, "msg": "get_card('5') should have is_upgraded=false"}
	return {"pass": true}


func test_is_upgraded_id() -> Dictionary:
	if not CardDatabase.is_upgraded_id("5+"):
		return {"pass": false, "msg": "'5+' should be recognized as upgraded"}
	if CardDatabase.is_upgraded_id("5"):
		return {"pass": false, "msg": "'5' should not be recognized as upgraded"}
	return {"pass": true}


func test_display_name_upgraded() -> Dictionary:
	var name := CardRendererScript.get_display_name({"name": "剑气斩", "is_upgraded": true})
	if name != "剑气斩+":
		return {"pass": false, "msg": "expected '剑气斩+' got '%s'" % name}
	return {"pass": true}


func test_display_name_not_upgraded() -> Dictionary:
	var name := CardRendererScript.get_display_name({"name": "剑气斩", "is_upgraded": false})
	if name != "剑气斩":
		return {"pass": false, "msg": "expected '剑气斩' got '%s'" % name}
	return {"pass": true}
```

- [ ] **Step 2: 运行，确认测试失败（实现未完成）**

```
run_suite.bat TestCardEffects
```

Expected: 6 个测试全部失败，错误如 `"is_upgraded_id" is not a method` 或 `expected is_upgraded=true, got false`

---

## Task 2: 修改 CardDatabase.gd — 支持 "+" ID 后缀

**Files:**
- Modify: `scripts/data/CardDatabase.gd`

- [ ] **Step 3: 在 `get_card()` 中添加 "+" 后缀识别逻辑**

将现有 `get_card` 函数完整替换为：

```gdscript
func get_card(id) -> Dictionary:
	if _all.is_empty():
		_load_cards_from_json()
	var id_str: String
	var is_upgraded := false
	match typeof(id):
		TYPE_INT, TYPE_FLOAT:
			id_str = str(int(id))
		_:
			id_str = str(id)

	if id_str.ends_with("+"):
		id_str = id_str.left(id_str.length() - 1)
		is_upgraded = true

	if _all.has(id_str):
		var card := _all[id_str].duplicate()
		if is_upgraded:
			card["is_upgraded"] = true
		return card
	push_error("CardDatabase: 未知卡牌 id = " + id_str + ("+" if is_upgraded else ""))
	return {}
```

- [ ] **Step 4: 在文件末尾添加 `is_upgraded_id` 静态方法**

在 `get_all_cards` 函数之后追加：

```gdscript
static func is_upgraded_id(id: String) -> bool:
	return id.ends_with("+")
```

- [ ] **Step 5: 运行 TestCardEffects，确认 CardDatabase 相关 4 个测试通过**

```
run_suite.bat TestCardEffects
```

Expected: 4 pass（CardDatabase 测试），2 fail（CardRenderer 测试仍未实现）

---

## Task 3: 修改 CardRenderer.gd — 名字追加 "+"

**Files:**
- Modify: `scripts/CardRenderer.gd`

- [ ] **Step 6: 添加 `get_display_name` 静态方法**

在 `resolve_upgrade_text` 方法定义之前插入：

```gdscript
static func get_display_name(card_data: Dictionary) -> String:
	var name := str(card_data.get("name", ""))
	if card_data.get("is_upgraded", false):
		return name + "+"
	return name
```

- [ ] **Step 7: 在 `refresh()` 中改用 `get_display_name`**

将 `refresh()` 里的这一行：
```gdscript
_place_text_center(_name_label, str(_card_data.get("name", "")), render_size, CARD_BASE_W * 0.5, 95.0, 720.0, 110.0)
```
替换为：
```gdscript
_place_text_center(_name_label, get_display_name(_card_data), render_size, CARD_BASE_W * 0.5, 95.0, 720.0, 110.0)
```

- [ ] **Step 8: 运行 TestCardEffects，确认全部 6 个测试通过**

```
run_suite.bat TestCardEffects
```

Expected: 6 pass, 0 fail

- [ ] **Step 9: Commit**

```
git add scripts/data/CardDatabase.gd scripts/CardRenderer.gd tests/suites/TestCardEffects.gd
git commit -m "feat: support card upgrade ID suffix (+) and display name"
```

---

## Task 4: 创建 BonfireUpgrade 场景和脚本

**Files:**
- Create: `scenes/BonfireUpgrade.tscn`
- Create: `scripts/BonfireUpgrade.gd`

- [ ] **Step 10: 创建 `scenes/BonfireUpgrade.tscn`**

文件内容：

```
[gd_scene load_steps=2 format=3 uid="uid://bonfire_upgrade_v1"]

[ext_resource type="Script" path="res://scripts/BonfireUpgrade.gd" id="1_bu"]

[node name="BonfireUpgrade" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_bu")
```

- [ ] **Step 11: 创建 `scripts/BonfireUpgrade.gd`**

```gdscript
## BonfireUpgrade.gd
## 篝火升级卡牌全屏场景。
extends Control

const GAME_MAP_SCENE       := "res://scenes/GameMap.tscn"
const CardViewScene        = preload("res://scenes/CardView.tscn")
const CardZoomOverlayScript = preload("res://scripts/CardZoomOverlay.gd")

const COLS        := 5
const H_SEP       := 10
const CARD_ASPECT := 2752.0 / 1536.0
const PAD_X       := 96.0

var _card_zoom_overlay


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MusicManager.play("map")
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.04, 0.02, 0.97)
	add_child(bg)

	var title := Label.new()
	title.text = "🔥 篝火 · 选择一张卡牌升级"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_left   = 0
	title.offset_top    = 16
	title.offset_right  = 0
	title.offset_bottom = 60
	add_child(title)

	var hint := Label.new()
	hint.text = "悬停查看升级后效果，已升级的卡牌无法再次升级"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left   = 0
	hint.offset_top    = 62
	hint.offset_right  = 0
	hint.offset_bottom = 98
	add_child(hint)

	# 先创建 zoom overlay，后续信号连接会引用它
	_card_zoom_overlay = CardZoomOverlayScript.new()
	add_child(_card_zoom_overlay)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 104
	scroll.offset_bottom = -68
	scroll.offset_left   = PAD_X * 0.5
	scroll.offset_right  = -PAD_X * 0.5
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", H_SEP)
	grid.add_theme_constant_override("v_separation", H_SEP)
	scroll.add_child(grid)

	var vp     := get_viewport_rect().size
	var card_w := int((vp.x - PAD_X - H_SEP * (COLS - 1)) / float(COLS))
	var card_h := int(card_w * CARD_ASPECT)

	for i in range(GameState.deck.size()):
		var card_id: String        = GameState.deck[i]
		var already_upgraded: bool = card_id.ends_with("+")
		var card_data              := CardDatabase.get_card(card_id)
		if card_data.is_empty():
			continue

		var view: Control = CardViewScene.instantiate()
		view.custom_minimum_size = Vector2(card_w, card_h)
		view.mouse_filter        = Control.MOUSE_FILTER_STOP
		view.setup(card_data, null, false)

		if already_upgraded:
			view.modulate.a = 0.4
			view.set_usable(false)
			# 鼠标移入已升级卡时关闭可能残留的 zoom
			view.unhovered.connect(_card_zoom_overlay.hide_card)
		else:
			var upgraded_data := card_data.duplicate(true)
			upgraded_data["is_upgraded"] = true
			view.hovered.connect(_on_card_hovered.bind(upgraded_data))
			view.unhovered.connect(_card_zoom_overlay.hide_card)
			view.activated.connect(_on_card_selected.bind(i))

		grid.add_child(view)

	var skip_btn := Button.new()
	skip_btn.text       = "跳过"
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.add_theme_font_size_override("font_size", 20)
	skip_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	skip_btn.offset_left   = vp.x * 0.35
	skip_btn.offset_right  = -vp.x * 0.35
	skip_btn.offset_top    = -58
	skip_btn.offset_bottom = -8
	skip_btn.pressed.connect(_on_skip)
	add_child(skip_btn)


# hovered 信号：(card_data, rect)；bind 追加 upgraded_data
func _on_card_hovered(original_cd: Dictionary, rect: Rect2, upgraded_data: Dictionary) -> void:
	_card_zoom_overlay.show_card(upgraded_data, "", rect)


# activated 信号：(card_data)；bind 追加 deck_index
func _on_card_selected(_card_data: Dictionary, deck_index: int) -> void:
	var base_id := GameState.deck[deck_index].trim_suffix("+")
	GameState.deck[deck_index] = base_id + "+"
	Log.info("BonfireUpgrade", "升级卡牌：%s+ (index=%d)" % [base_id, deck_index])
	get_tree().change_scene_to_file(GAME_MAP_SCENE)


func _on_skip() -> void:
	get_tree().change_scene_to_file(GAME_MAP_SCENE)
```

---

## Task 5: 修改 GameMap.gd — 接通篝火按钮

**Files:**
- Modify: `scripts/GameMap.gd`

- [ ] **Step 12: 修改 `_show_bonfire_popup` 中的按钮文字**

找到：
```gdscript
popup_btn1.text    = "升级卡牌（未实装）"
```
改为：
```gdscript
popup_btn1.text    = "升级卡牌"
```

- [ ] **Step 13: 实现 `_on_popup_btn1_pressed`**

找到：
```gdscript
func _on_popup_btn1_pressed() -> void:
	# 预留：篝火升级 / 商店购买
	pass
```
替换为：
```gdscript
func _on_popup_btn1_pressed() -> void:
	node_popup.hide()
	get_tree().change_scene_to_file("res://scenes/BonfireUpgrade.tscn")
```

- [ ] **Step 14: Commit**

```
git add scripts/BonfireUpgrade.gd scenes/BonfireUpgrade.tscn scripts/GameMap.gd
git commit -m "feat: implement bonfire upgrade scene and wire map popup button"
```

---

## Task 6: 注册新文件，运行完整测试

**Files:**
- Modify: `tests/suites/TestScriptIntegrity.gd`

- [ ] **Step 15: 在 GAME_SCRIPTS 数组末尾追加**

在 `"res://scripts/RewardScreen.gd",` 之后加一行：
```gdscript
"res://scripts/BonfireUpgrade.gd",
```

- [ ] **Step 16: 在 TEST_SCRIPTS 数组末尾追加**

在 `"res://tests/suites/TestBattleEngineLogic.gd",` 之后加一行：
```gdscript
"res://tests/suites/TestCardEffects.gd",
```

- [ ] **Step 17: 在 SCENES 数组末尾追加**

在 `"res://scenes/RewardScreen.tscn",` 之后加一行：
```gdscript
"res://scenes/BonfireUpgrade.tscn",
```

- [ ] **Step 18: 运行 TestScriptIntegrity**

```
run_suite.bat TestScriptIntegrity
```

Expected: 所有脚本/场景/Autoload 检查全部通过，0 fail

- [ ] **Step 19: 运行 TestCardEffects**

```
run_suite.bat TestCardEffects
```

Expected: 6 pass, 0 fail

- [ ] **Step 20: Commit**

```
git add tests/suites/TestScriptIntegrity.gd
git commit -m "chore: register BonfireUpgrade and TestCardEffects in integrity check"
```

---

## Task 7: 手动验证清单

- [ ] 运行游戏，新局开始进入地图
- [ ] 点击篝火节点 → 弹窗出现，按钮文字为"升级卡牌"（无"未实装"字样）
- [ ] 点击"升级卡牌" → 全屏升级界面（黑底，标题"🔥 篝火 · 选择一张卡牌升级"）
- [ ] 悬停一张剑气斩 → 放大预览名字显示"剑气斩+"，描述数值显示升级后（14点而非6点）
- [ ] 点击一张剑气斩 → 返回地图
- [ ] 打开牌组（"查看牌组"按钮） → 已升级的剑气斩名称显示"剑气斩+"
- [ ] 进入战斗 → 升级牌在手牌中显示"剑气斩+"
- [ ] 再次进入篝火升级 → 已升级的剑气斩显示为半透明（alpha ≈ 0.4），无法选中
- [ ] 升级界面点击"跳过" → 返回地图，牌组未变化
- [ ] 篝火弹窗点击"继续前行" → 关闭弹窗，不跳转升级场景
