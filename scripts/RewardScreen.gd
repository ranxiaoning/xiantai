## RewardScreen.gd — 战斗奖励界面
## 小弹窗含灵石/卡牌两个奖励按钮；卡牌按钮打开全屏选卡页面
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"
const CardViewScene := preload("res://scenes/CardView.tscn")

const _RARITY_ORDER      := ["黄品", "玄品", "地品", "天品"]
const _RARITY_CUMULATIVE := [0.55, 0.85, 0.95, 1.0]

const CARD_W := 210
const CARD_H := 376   # 210 × 1.79

var _offered_cards:    Array[Dictionary] = []
var _selected_idx:     int  = -1
var _hovered_idx:      int  = -1
var _stone_gain:       int  = 0
var _stones_collected: bool = false
var _card_confirmed:   bool = false
var _slots_built:      bool = false
var _slot_wrappers:    Array[Control] = []
var _slot_tweens:      Array          = []

# ── 弹窗节点 ─────────────────────────────────────────────────────────
@onready var _stones_btn:      Button        = %StonesBtn
@onready var _card_reward_btn: Button        = %CardRewardBtn
@onready var _popup_continue:  Button        = %PopupContinue

# ── 选卡页面节点 ───────────────────────────────────────────────────────
@onready var _card_panel:   Control       = %CardPanel
@onready var _cards_row:    HBoxContainer = %CardsRow
@onready var _confirm_btn:  Button        = %ConfirmBtn
@onready var _skip_btn:     Button        = %SkipBtn


func _ready() -> void:
	MusicManager.play("map")
	_card_panel.hide()

	var node_type: String = GameState.pending_battle_node_type
	_stone_gain = 60 if node_type == "elite" else 30
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
	return result


func _pick_one_by_rarity(all_cards: Array[Dictionary]) -> Dictionary:
	var roll := randf()
	var rarity := _RARITY_ORDER[0]
	for i in _RARITY_ORDER.size():
		if roll < _RARITY_CUMULATIVE[i]:
			rarity = _RARITY_ORDER[i]
			break
	var pool := all_cards.filter(func(c: Dictionary) -> bool: return c["rarity"] == rarity)
	if pool.is_empty():
		pool = all_cards
	return pool[randi() % pool.size()]


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


func _on_popup_continue_pressed() -> void:
	get_tree().change_scene_to_file(GAME_MAP_SCENE)


# ── 选卡页面：构建卡槽 ────────────────────────────────────────────────

func _populate_card_slots() -> void:
	_slot_wrappers.clear()
	_slot_tweens.clear()
	for child in _cards_row.get_children():
		child.queue_free()

	for i in _offered_cards.size():
		var card := _offered_cards[i]

		const LABEL_H := 22
		const SEP     := 8
		var wrapper_h := CARD_H + SEP + LABEL_H
		var wrapper   := Control.new()
		wrapper.custom_minimum_size = Vector2(CARD_W, wrapper_h)
		wrapper.pivot_offset        = Vector2(CARD_W * 0.5, wrapper_h * 0.5)

		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.add_theme_constant_override("separation", SEP)

		var btn := Button.new()
		btn.flat       = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(CARD_W, CARD_H)

		var card_view = CardViewScene.instantiate()
		card_view.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_view.custom_minimum_size = Vector2(CARD_W, CARD_H)
		card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_view.setup(card, null, false)
		btn.add_child(card_view)

		var name_lbl := Label.new()
		name_lbl.text = card["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", _rarity_color(card["rarity"]))

		vbox.add_child(btn)
		vbox.add_child(name_lbl)
		wrapper.add_child(vbox)
		_cards_row.add_child(wrapper)
		_slot_wrappers.append(wrapper)
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
	var base := 1.10 if _selected_idx == idx else 1.0
	if _hovered_idx == idx and not (_card_confirmed and idx != _selected_idx):
		base += 0.06
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
	_card_panel.hide()


func _on_skip_btn_pressed() -> void:
	_card_panel.hide()
