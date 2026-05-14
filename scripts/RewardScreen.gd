## RewardScreen.gd — 战斗奖励界面
## 小弹窗含灵石/卡牌两个奖励按钮；卡牌按钮打开全屏选卡页面
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"
const CardViewScene := preload("res://scenes/CardView.tscn")

const _RARITY_ORDER      := ["黄品", "玄品", "地品", "天品"]
const _RARITY_CUMULATIVE := [0.55, 0.85, 0.95, 1.0]

const CARD_W := 186
const CARD_H := 333   # 186 × 1.79
const CARD_SEPARATION := 170

var _offered_cards:    Array[Dictionary] = []
var _selected_idx:     int  = -1
var _hovered_idx:      int  = -1
var _stone_gain:       int  = 0
var _stones_collected: bool = false
var _card_confirmed:   bool = false
var _slots_built:      bool = false
var _slot_wrappers:    Array[Control] = []
var _slot_card_views:  Array[Control] = []
var _slot_tweens:      Array          = []
var _upgrade_check:    CheckBox       = null
var _preview_upgraded: bool           = false
var _reward_min_rarity: String        = ""

# ── 弹窗节点 ─────────────────────────────────────────────────────────
@onready var _stones_btn:      Button        = %StonesBtn
@onready var _card_reward_btn: Button        = %CardRewardBtn
@onready var _popup_continue:  Button        = %PopupContinue

# ── 选卡页面节点 ───────────────────────────────────────────────────────
@onready var _card_panel:   Control       = %CardPanel
@onready var _cards_row:    HBoxContainer = %CardsRow
@onready var _confirm_btn:  Button        = %ConfirmBtn
@onready var _skip_btn:     Button        = %SkipBtn
@onready var _action_row:   HBoxContainer = _confirm_btn.get_parent()


func _ready() -> void:
	MusicManager.play("map")
	_initialize_reward_screen()


func _initialize_reward_screen() -> void:
	_card_panel.hide()
	_prepare_action_row_bottom_bar()
	_build_upgrade_preview_check()

	var node_type: String = GameState.pending_battle_node_type
	var reward_bonus := GameState.consume_pending_reward_bonuses()
	_reward_min_rarity = str(reward_bonus.get("min_rarity", ""))
	_stone_gain = (60 if node_type == "elite" else 30) + int(reward_bonus.get("stones_bonus", 0))
	GameState.pending_battle_node_type = ""
	GameState.pending_battle_node_floor = 0
	_stones_btn.text = "灵石  +%d" % _stone_gain

	_offered_cards = _pick_three_cards()
	_confirm_btn.disabled = true


# ── 稀有度抽卡 ───────────────────────────────────────────────────────

func _pick_three_cards() -> Array[Dictionary]:
	var all_cards := CardDatabase.get_all_cards()
	var result: Array[Dictionary] = []
	var attempts := 0
	while result.size() < 3 and attempts < 300:
		attempts += 1
		var card := _pick_one_by_rarity(all_cards)
		var dup := false
		for c in result:
			if c["id"] == card["id"]:
				dup = true
				break
		if not dup:
			result.append(card)
	_apply_reward_min_rarity(result, all_cards)
	return result


func _pick_one_by_rarity(all_cards: Array[Dictionary]) -> Dictionary:
	var roll := randf()
	var rarity := _RARITY_ORDER[0]
	for i in range(_RARITY_ORDER.size()):
		if roll < _RARITY_CUMULATIVE[i]:
			rarity = _RARITY_ORDER[i]
			break
	var pool := all_cards.filter(func(c: Dictionary) -> bool: return c["rarity"] == rarity)
	if pool.is_empty():
		pool = all_cards
	return pool[randi() % pool.size()]


func _apply_reward_min_rarity(result: Array[Dictionary], all_cards: Array[Dictionary]) -> void:
	if _reward_min_rarity.is_empty() or result.is_empty():
		return
	for card in result:
		if _rarity_rank(str(card.get("rarity", "黄品"))) >= _rarity_rank(_reward_min_rarity):
			return
	var replacement := _pick_one_at_least_rarity(all_cards, _reward_min_rarity, result)
	if replacement.is_empty():
		return
	result[result.size() - 1] = replacement


func _pick_one_at_least_rarity(all_cards: Array[Dictionary], rarity: String, current: Array[Dictionary]) -> Dictionary:
	var used := {}
	for card in current:
		used[str(card.get("id", ""))] = true
	var pool := all_cards.filter(func(c: Dictionary) -> bool:
		return _rarity_rank(str(c.get("rarity", "黄品"))) >= _rarity_rank(rarity) and not used.has(str(c.get("id", "")))
	)
	if pool.is_empty():
		pool = all_cards.filter(func(c: Dictionary) -> bool:
			return _rarity_rank(str(c.get("rarity", "黄品"))) >= _rarity_rank(rarity)
		)
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]


func _rarity_rank(rarity: String) -> int:
	match rarity:
		"玄品": return 1
		"地品": return 2
		"天品": return 3
		_: return 0


# ── 弹窗按钮回调 ──────────────────────────────────────────────────────

func _on_stones_btn_pressed() -> void:
	if _stones_collected:
		return
	_stones_collected = true
	GameState.add_spirit_stones(_stone_gain)
	_stones_btn.text     = "灵石  +%d  ✓" % _stone_gain
	_stones_btn.disabled = true
	Log.info("RewardScreen", "领取灵石 %d，现有 %d" % [_stone_gain, GameState.spirit_stones])


func _on_card_reward_btn_pressed() -> void:
	if not _slots_built:
		_populate_card_slots()
		_slots_built = true
	_card_panel.show()
	_action_row.show()
	if _upgrade_check:
		_upgrade_check.show()


func _on_popup_continue_pressed() -> void:
	get_tree().change_scene_to_file(GAME_MAP_SCENE)


# ── 选卡页面：构建卡槽 ────────────────────────────────────────────────

func _populate_card_slots() -> void:
	for t in _slot_tweens:
		if t and is_instance_valid(t):
			t.kill()
	_slot_wrappers.clear()
	_slot_card_views.clear()
	_slot_tweens.clear()
	_cards_row.add_theme_constant_override("separation", CARD_SEPARATION)
	_cards_row.custom_minimum_size = Vector2(0.0, CARD_H)
	_cards_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_cards_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for child in _cards_row.get_children():
		child.free()

	for i in range(_offered_cards.size()):
		var card := _offered_cards[i]

		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(CARD_W, CARD_H)
		wrapper.size = wrapper.custom_minimum_size
		wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		wrapper.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)

		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.position = Vector2.ZERO
		btn.custom_minimum_size = Vector2(CARD_W, CARD_H)
		btn.size = btn.custom_minimum_size
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var card_view = CardViewScene.instantiate()
		card_view.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_view.custom_minimum_size = Vector2(CARD_W, CARD_H)
		card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_view.setup(_make_reward_display_card(card), null, false)
		btn.add_child(card_view)

		wrapper.add_child(btn)
		_cards_row.add_child(wrapper)
		_slot_wrappers.append(wrapper)
		_slot_card_views.append(card_view)
		_slot_tweens.append(null)

		btn.pressed.connect(_on_card_slot_toggled.bind(i))
		btn.mouse_entered.connect(_on_card_hover_enter.bind(i))
		btn.mouse_exited.connect(_on_card_hover_exit.bind(i))


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"玄品": return Color(0.5, 0.7, 1.0, 1)
		"地品": return Color(0.8, 0.5, 1.0, 1)
		"天品": return Color(1.0, 0.75, 0.1, 1)
		_:      return Color(0.85, 0.85, 0.85, 1)


# ── 选卡交互 ─────────────────────────────────────────────────────────

func _slot_target_scale(idx: int) -> float:
	var base := 1.05 if _selected_idx == idx else 1.0
	if _hovered_idx == idx and not (_card_confirmed and idx != _selected_idx):
		base += 0.02
	return base


func _on_card_slot_toggled(idx: int) -> void:
	if _card_confirmed:
		return
	if _selected_idx == idx:
		_selected_idx = -1
		_animate_slot(idx, Color.WHITE)
		_confirm_btn.disabled = true
	else:
		if _selected_idx >= 0:
			_animate_slot(_selected_idx, Color.WHITE)
		_selected_idx = idx
		_animate_slot(idx, Color(1.15, 1.05, 0.6))
		_confirm_btn.disabled = false


func _on_card_hover_enter(idx: int) -> void:
	if _card_confirmed and idx != _selected_idx:
		return
	_hovered_idx = idx
	_tween_slot_scale(idx, _slot_target_scale(idx), 0.12)


func _on_card_hover_exit(idx: int) -> void:
	if _hovered_idx == idx:
		_hovered_idx = -1
	if _card_confirmed and idx != _selected_idx:
		return
	_tween_slot_scale(idx, _slot_target_scale(idx), 0.14)


func _animate_slot(idx: int, col: Color) -> void:
	_slot_wrappers[idx].modulate = col
	_tween_slot_scale(idx, _slot_target_scale(idx), 0.18)


func _tween_slot_scale(idx: int, target: float, duration: float) -> void:
	var wrapper := _slot_wrappers[idx]
	var prev: Tween = _slot_tweens[idx]
	if prev and is_instance_valid(prev):
		prev.kill()
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(wrapper, "scale", Vector2(target, target), duration)
	_slot_tweens[idx] = t


func _on_confirm_btn_pressed() -> void:
	if _selected_idx < 0 or _selected_idx >= _offered_cards.size() or _card_confirmed:
		return
	_card_confirmed = true
	var chosen := _offered_cards[_selected_idx]
	GameState.deck.append(chosen["id"])
	Log.info("RewardScreen", "获得卡牌：%s（id=%s）" % [chosen["name"], chosen["id"]])
	for i in _slot_wrappers.size():
		if i != _selected_idx:
			_slot_wrappers[i].modulate = Color(0.35, 0.35, 0.35, 0.5)
	_confirm_btn.disabled = true
	_skip_btn.text = "返回"
	_card_reward_btn.text    = "卡牌  已选取  ✓"
	_card_reward_btn.disabled = true
	_hide_card_panel()


func _on_skip_btn_pressed() -> void:
	_hide_card_panel()


func _hide_card_panel() -> void:
	_card_panel.hide()
	_action_row.hide()
	if _upgrade_check:
		_upgrade_check.hide()


func _prepare_action_row_bottom_bar() -> void:
	if _action_row.get_parent() != self:
		_action_row.get_parent().remove_child(_action_row)
		_action_row.owner = null
		add_child(_action_row)
	_action_row.hide()
	_action_row.z_index = 40
	_action_row.mouse_filter = Control.MOUSE_FILTER_STOP
	_action_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_action_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_action_row.anchor_left = 0.5
	_action_row.anchor_right = 0.5
	_action_row.anchor_top = 1.0
	_action_row.anchor_bottom = 1.0
	_action_row.offset_left = -170.0
	_action_row.offset_right = 170.0
	_action_row.offset_top = -112.0
	_action_row.offset_bottom = -54.0
	_action_row.add_theme_constant_override("separation", 28)


# ── 升级预览 CheckBox ──────────────────────────────────────────────

func _build_upgrade_preview_check() -> void:
	_upgrade_check = CheckBox.new()
	_upgrade_check.text = "查看升级"
	_upgrade_check.button_pressed = _preview_upgraded
	_upgrade_check.focus_mode = Control.FOCUS_NONE
	_upgrade_check.mouse_filter = Control.MOUSE_FILTER_STOP
	_upgrade_check.anchor_left = 0.0
	_upgrade_check.anchor_top = 1.0
	_upgrade_check.anchor_right = 0.0
	_upgrade_check.anchor_bottom = 1.0
	_upgrade_check.offset_left = 36.0
	_upgrade_check.offset_top = -78.0
	_upgrade_check.offset_right = 176.0
	_upgrade_check.offset_bottom = -38.0
	_upgrade_check.z_index = 30
	_upgrade_check.add_theme_font_size_override("font_size", 18)
	_upgrade_check.add_theme_color_override("font_color", Color.WHITE)
	_upgrade_check.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.58))
	_upgrade_check.add_theme_icon_override("unchecked", _make_check_icon(false))
	_upgrade_check.add_theme_icon_override("checked", _make_check_icon(true))
	_upgrade_check.toggled.connect(_on_upgrade_check_toggled)
	_upgrade_check.hide()
	add_child(_upgrade_check)


func _make_check_icon(checked: bool) -> Texture2D:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var border := Color.WHITE
	var fill := Color(0.0, 0.0, 0.0, 0.42)
	for y in range(2, 22):
		for x in range(2, 22):
			img.set_pixel(x, y, fill)
	for i in range(2, 22):
		img.set_pixel(i, 2, border)
		img.set_pixel(i, 21, border)
		img.set_pixel(2, i, border)
		img.set_pixel(21, i, border)
	if checked:
		var mark := Color(0.7, 1.0, 0.45)
		for step in range(0, 6):
			img.set_pixel(7 + step, 13 + step, mark)
			img.set_pixel(7 + step, 14 + step, mark)
		for step in range(0, 9):
			img.set_pixel(12 + step, 18 - step, mark)
			img.set_pixel(12 + step, 17 - step, mark)
	return ImageTexture.create_from_image(img)


func _make_reward_display_card(card: Dictionary) -> Dictionary:
	if not _preview_upgraded:
		return card
	var display_card := card.duplicate(true)
	display_card["is_upgraded"] = true
	return display_card


func _on_upgrade_check_toggled(pressed: bool) -> void:
	_preview_upgraded = pressed
	if _slots_built:
		_selected_idx = -1
		_hovered_idx = -1
		_confirm_btn.disabled = true
		_populate_card_slots()
