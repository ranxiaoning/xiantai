## BattleScene.gd
extends Control

const GAME_MAP_SCENE     := "res://scenes/GameMap.tscn"
const REWARD_SCREEN_SCENE := "res://scenes/RewardScreen.tscn"
const MAIN_MENU_SCENE    := "res://scenes/MainMenu.tscn"
const _BattleEngineScript = preload("res://scripts/BattleEngine.gd")
const CardViewScene       = preload("res://scenes/CardView.tscn")
const CardRendererScript  = preload("res://scripts/CardRenderer.gd")
const ResourceOrbScene    = preload("res://scripts/ResourceOrb.gd")
const CardZoomOverlayScript = preload("res://scripts/CardZoomOverlay.gd")

# Preview size matches the card art ratio.
const PREVIEW_W := 280
const PREVIEW_H := 502

var _engine: RefCounted
# Preview overlay is attached to the battle root so it is not clipped by scroll containers.
var _preview_root: Control
var _preview_renderer

# 资源不足提示 toast
var _toast_tween:  Tween
var _toast_root:   Control
var _toast_label:  Label

var _pending_draw_ids: Array = []
var _reshuffle_anim_ids: Array = []
var _reshuffle_anim_pending: bool = false

var _resource_dock: Control
var _ling_li_orb
var _dao_hui_orb
var _dao_xing_badge: PanelContainer
var _dao_xing_value_label: Label
var _draw_pile_btn: Button
var _discard_pile_btn: Button
var _pile_overlay: Control
var _pile_title_label: Label
var _pile_grid: GridContainer
var _card_zoom_overlay

# ── UI 节点引用 ────────────────────────────────────────────────────
@onready var enemy_name_label:     Label         = %EnemyName
@onready var enemy_hp_shield_bar  = %EnemyHPShieldBar
@onready var enemy_intent_label:   Label         = %IntentLabel
@onready var enemy_status_label:   Label         = %EnemyStatusLabel

@onready var player_hp_shield_bar = %PlayerHPShieldBar
@onready var ling_li_bar:          ProgressBar   = %LingLiBar
@onready var ling_li_label:        Label         = %LingLiLabel
@onready var dao_hui_bar:          ProgressBar   = %DaoHuiBar
@onready var dao_hui_label:        Label         = %DaoHuiLabel
@onready var dao_xing_label:       Label         = %DaoXingLabel

@onready var hand_container:      Control        = %HandContainer
@onready var end_turn_btn:        Button         = %EndTurnBtn
@onready var skill_btn:           Button         = %SkillBtn
@onready var log_label:           Label          = %LogLabel
@onready var result_panel:        PanelContainer = %ResultPanel
@onready var result_label:        Label          = %ResultLabel
@onready var result_btn:          Button         = %ResultBtn

var _log_lines: Array[String] = []


func _ready() -> void:
	MusicManager.play("battle")
	result_panel.hide()
	_hide_legacy_resource_panel()
	_build_resource_dock()
	_build_pile_overlay()
	_build_preview_overlay()
	_build_toast_layer()
	_build_card_zoom_overlay()
	_init_battle()


# ── 预览覆盖层（代码构建，挂在根节点最顶层）────────────────────────

func _build_preview_overlay() -> void:
	_preview_root = Control.new()
	_preview_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_root.z_index = 20
	_preview_root.hide()
	add_child(_preview_root)

	_preview_renderer = CardRendererScript.new()
	_preview_renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_renderer.size = Vector2(PREVIEW_W, PREVIEW_H)
	_preview_root.add_child(_preview_renderer)


# ── Toast 提示层 ─────────────────────────────────────────────────────

func _build_toast_layer() -> void:
	_toast_root = Control.new()
	_toast_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_root.z_index = 25
	_toast_root.hide()
	add_child(_toast_root)

	_toast_label = Label.new()
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 26)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.15))
	_toast_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_toast_label.add_theme_constant_override("shadow_offset_x", 2)
	_toast_label.add_theme_constant_override("shadow_offset_y", 2)
	_toast_label.add_theme_constant_override("shadow_outline_size", 2)
	_toast_label.anchor_left   = 0.0
	_toast_label.anchor_right  = 1.0
	_toast_label.anchor_top    = 0.48
	_toast_label.anchor_bottom = 0.48
	_toast_label.offset_bottom = 40
	_toast_label.grow_vertical = Control.GROW_DIRECTION_END
	_toast_root.add_child(_toast_label)


func _build_card_zoom_overlay() -> void:
	_card_zoom_overlay = CardZoomOverlayScript.new()
	add_child(_card_zoom_overlay)


func _show_toast(text: String) -> void:
	if _toast_tween:
		_toast_tween.kill()
	_toast_label.text = text
	_toast_root.modulate.a = 1.0
	_toast_root.show()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(0.8)
	_toast_tween.tween_property(_toast_root, "modulate:a", 0.0, 0.35)
	_toast_tween.tween_callback(_toast_root.hide)


# ── 战斗初始化 ──────────────────────────────────────────────────────

func _hide_legacy_resource_panel() -> void:
	var legacy := get_node_or_null("BottomUI/Resources")
	if legacy:
		legacy.hide()
		legacy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hand_area := get_node_or_null("BottomUI/HandArea")
	if hand_area:
		hand_area.offset_left = 392.0


func _build_resource_dock() -> void:
	_resource_dock = Control.new()
	_resource_dock.name = "ResourceDock"
	_resource_dock.anchor_left = 0.0
	_resource_dock.anchor_top = 1.0
	_resource_dock.anchor_right = 0.0
	_resource_dock.anchor_bottom = 1.0
	_resource_dock.offset_left = 22.0
	_resource_dock.offset_top = -118.0
	_resource_dock.offset_right = 372.0
	_resource_dock.offset_bottom = -16.0
	_resource_dock.mouse_filter = Control.MOUSE_FILTER_PASS
	_resource_dock.z_index = 12
	add_child(_resource_dock)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	_resource_dock.add_child(row)

	_ling_li_orb = ResourceOrbScene.new()
	_ling_li_orb.fill_color = Color(0.0, 0.72, 0.92)
	_ling_li_orb.ring_color = Color(0.12, 0.96, 1.0)
	_ling_li_orb.back_color = Color(0.0, 0.04, 0.06, 0.95)
	row.add_child(_ling_li_orb)

	_dao_hui_orb = ResourceOrbScene.new()
	_dao_hui_orb.fill_color = Color(0.62, 0.18, 0.88)
	_dao_hui_orb.ring_color = Color(0.86, 0.55, 1.0)
	_dao_hui_orb.back_color = Color(0.06, 0.02, 0.10, 0.95)
	row.add_child(_dao_hui_orb)

	var right_box := VBoxContainer.new()
	right_box.custom_minimum_size = Vector2(145, 96)
	right_box.add_theme_constant_override("separation", 5)
	row.add_child(right_box)

	_dao_xing_badge = _make_badge_panel()
	_dao_xing_badge.custom_minimum_size = Vector2(126, 42)
	var dao_row := HBoxContainer.new()
	dao_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dao_row.add_theme_constant_override("separation", 4)
	_dao_xing_badge.add_child(dao_row)
	var dao_icon := Label.new()
	dao_icon.text = "道"
	dao_icon.add_theme_font_size_override("font_size", 19)
	dao_icon.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	dao_row.add_child(dao_icon)
	_dao_xing_value_label = Label.new()
	_dao_xing_value_label.add_theme_font_size_override("font_size", 24)
	_dao_xing_value_label.add_theme_color_override("font_color", Color(1.0, 0.74, 0.18))
	dao_row.add_child(_dao_xing_value_label)
	var dao_label := Label.new()
	dao_label.text = "道行"
	dao_label.add_theme_font_size_override("font_size", 13)
	dao_label.add_theme_color_override("font_color", Color(0.82, 0.70, 0.48))
	dao_row.add_child(dao_label)
	right_box.add_child(_dao_xing_badge)

	var pile_row := HBoxContainer.new()
	pile_row.add_theme_constant_override("separation", 6)
	right_box.add_child(pile_row)
	_draw_pile_btn = _make_pile_button("牌库")
	_discard_pile_btn = _make_pile_button("弃牌")
	pile_row.add_child(_draw_pile_btn)
	pile_row.add_child(_discard_pile_btn)
	_draw_pile_btn.pressed.connect(_show_draw_pile)
	_discard_pile_btn.pressed.connect(_show_discard_pile)


func _make_badge_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.03, 0.82)
	style.border_color = Color(0.85, 0.64, 0.25, 0.75)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_pile_button(label: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(58, 34)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 13)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.045, 0.035, 0.82)
	normal.border_color = Color(0.72, 0.58, 0.28, 0.65)
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_right = 4
	normal.corner_radius_bottom_left = 4
	var hover := normal.duplicate()
	hover.bg_color = Color(0.13, 0.10, 0.05, 0.92)
	hover.border_color = Color(1.0, 0.78, 0.32, 0.90)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.text = label
	return btn


func _build_pile_overlay() -> void:
	_pile_overlay = Control.new()
	_pile_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pile_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pile_overlay.z_index = 110
	_pile_overlay.hide()
	add_child(_pile_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.58)
	_pile_overlay.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -332.0
	panel.offset_top = -258.0
	panel.offset_right = 332.0
	panel.offset_bottom = 258.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.045, 0.05, 0.96)
	style.border_color = Color(0.92, 0.72, 0.38, 0.55)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", style)
	_pile_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)
	_pile_title_label = Label.new()
	_pile_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pile_title_label.add_theme_font_size_override("font_size", 22)
	_pile_title_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42))
	top.add_child(_pile_title_label)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(_hide_pile_overlay)
	top.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_pile_grid = GridContainer.new()
	_pile_grid.columns = 5
	_pile_grid.add_theme_constant_override("h_separation", 14)
	_pile_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_pile_grid)


func _init_battle() -> void:
	var char_data  := GameState.character
	var deck_ids   := GameState.deck
	var enemy_data := EnemyDatabase.get_battle_node_enemy(GameState.pending_battle_node)

	_engine = _BattleEngineScript.new()
	_engine.state_changed.connect(_on_state_changed)
	_engine.log_added.connect(_on_log_added)
	_engine.battle_ended.connect(_on_battle_ended)
	_engine.deck_reshuffled.connect(_on_deck_reshuffled)
	_engine.cards_drawn.connect(_on_cards_drawn)
	_engine.init(char_data, deck_ids, enemy_data)
	_engine.start_battle()


# ── 信号回调 ──────────────────────────────────────────────────────

func _on_state_changed() -> void:
	_update_ui()


func _on_log_added(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > 12:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


func _on_battle_ended(player_won: bool) -> void:
	end_turn_btn.disabled = true
	skill_btn.disabled    = true
	if player_won:
		get_tree().change_scene_to_file(REWARD_SCREEN_SCENE)
	else:
		result_label.text = "你已倒下……\n\n但记忆留存，下次会更强。"
		result_btn.text   = "返回主菜单"
		result_panel.show()


func _on_deck_reshuffled(cards: Array) -> void:
	_reshuffle_anim_ids.clear()
	for card in cards:
		_reshuffle_anim_ids.append(int(card.get("_instance_id", -1)))
	_reshuffle_anim_pending = true
	_show_toast("牌库重洗")


func _on_cards_drawn(cards: Array) -> void:
	for card in cards:
		_pending_draw_ids.append(int(card.get("_instance_id", -1)))


# ── 资源条样式初始化 ──────────────────────────────────────────────

func _apply_resource_bar_styles() -> void:
	var make_style := func(color: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = color
		s.corner_radius_top_left     = 3
		s.corner_radius_top_right    = 3
		s.corner_radius_bottom_right = 3
		s.corner_radius_bottom_left  = 3
		return s
	ling_li_bar.add_theme_stylebox_override("fill",       make_style.call(Color(0.25, 0.62, 0.95)))
	ling_li_bar.add_theme_stylebox_override("background", make_style.call(Color(0.07, 0.10, 0.16)))
	dao_hui_bar.add_theme_stylebox_override("fill",       make_style.call(Color(0.95, 0.82, 0.15)))
	dao_hui_bar.add_theme_stylebox_override("background", make_style.call(Color(0.12, 0.10, 0.04)))


# ── UI 刷新 ──────────────────────────────────────────────────────

func _update_ui() -> void:
	var s: Dictionary = _engine.s

	enemy_name_label.text = s["enemy_data"]["name"]
	enemy_hp_shield_bar.set_values(s["enemy_hp"], s["enemy_hp_max"], s["enemy_hu_ti"])
	enemy_intent_label.text = "意图：" + s["enemy_intent_text"]
	enemy_status_label.text = _format_statuses(s["enemy_statuses"])

	player_hp_shield_bar.set_values(s["player_hp"], s["player_hp_max"], s["player_hu_ti"])
	_update_resource_dock(s)

	var is_player_turn: bool = (s["phase"] == "player")
	end_turn_btn.disabled = not is_player_turn
	skill_btn.disabled    = not _engine.can_use_skill()
	skill_btn.text        = "剑意凝神\n(道慧%d)" % s["skill_dao_hui_cost"]

	_update_hand_display()


func _update_resource_dock(s: Dictionary) -> void:
	if _ling_li_orb:
		_ling_li_orb.set_values(s["player_ling_li"], s["player_ling_li_max"], "灵力")
	if _dao_hui_orb:
		_dao_hui_orb.set_values(s["player_dao_hui"], s["player_dao_hui_max"], "道慧")
	if _dao_xing_value_label:
		_dao_xing_value_label.text = "%d" % int(s["player_dao_xing"])
	if _draw_pile_btn:
		_draw_pile_btn.text = "牌库\n%d" % s["draw_pile"].size()
	if _discard_pile_btn:
		_discard_pile_btn.text = "弃牌\n%d" % s["discard_pile"].size()


func _update_hand_display() -> void:
	var s: Dictionary = _engine.s
	var hand_data = s["hand"]
	var current_children = hand_container.get_children()
	var draw_order_by_id := {}
	for i in range(_pending_draw_ids.size()):
		draw_order_by_id[_pending_draw_ids[i]] = i

	var available_children: Array = []
	for child in current_children:
		available_children.append(child)

	var new_children: Array = []
	var is_new_card:  Array = []

	for i in range(hand_data.size()):
		var c_data = hand_data[i]
		var view   = null
		var instance_id := int(c_data.get("_instance_id", -1))
		var force_new_after_shuffle := _reshuffle_anim_ids.has(instance_id)
		if not force_new_after_shuffle:
			for j in range(available_children.size()):
				var child = available_children[j]
				if child.has_method("set_usable") and child.card_data.get("_instance_id") == c_data.get("_instance_id"):
					view = child
					available_children.remove_at(j)
					view.card_data = c_data
					break

		if view == null:
			view = _make_card_view(c_data)
			hand_container.add_child(view)
			view.position = _draw_pile_anchor_local() + Vector2(-24, 0)
			view.scale    = Vector2(0.55, 0.55)
			view.rotation = -0.22
			view.modulate.a = 0.0
			is_new_card.append(true)
		else:
			is_new_card.append(false)

		view.set_usable(_engine.can_play_card(c_data))
		new_children.append(view)

	for child in available_children:
		if child.has_meta("_layout_tween"):
			var old: Tween = child.get_meta("_layout_tween")
			if old and old.is_valid():
				old.kill()
			child.remove_meta("_layout_tween")
		var child_id: int = int(child.card_data.get("_instance_id", -1))
		var to_pos: Vector2 = child.position + Vector2(0, -150)
		var to_scale: Vector2 = Vector2(1.3, 1.3)
		var to_rot: float = child.rotation + 0.16
		var duration: float = 0.25
		if _reshuffle_anim_ids.has(child_id):
			to_pos = _draw_pile_anchor_local() + Vector2(0, -8)
			to_scale = Vector2(0.35, 0.35)
			to_rot = -0.35
			duration = 0.32
		var t = create_tween().set_parallel(true)
		t.tween_property(child, "position", to_pos, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_property(child, "rotation", to_rot, duration)
		t.tween_property(child, "scale", to_scale, duration)
		t.tween_property(child, "modulate:a", 0.0, maxf(0.18, duration - 0.05))
		t.tween_callback(child.queue_free)

	if new_children.is_empty():
		_pending_draw_ids.clear()
		_reshuffle_anim_ids.clear()
		_reshuffle_anim_pending = false
		return

	# 同步 tree 顺序 = 手牌顺序，保证重叠时 z 层级正确
	for i in range(new_children.size()):
		hand_container.move_child(new_children[i], i)

	var count  = new_children.size()
	var max_w  = hand_container.size.x
	if max_w < 100:
		max_w = 840.0

	var card_w = 100.0
	var sep    = 12.0

	if count > 6:
		var visual_max = 680.0
		sep = (visual_max - count * card_w) / maxf(float(count - 1), 1.0)

	var total_w = count * card_w + (count - 1) * sep
	var start_x = (max_w - total_w) / 2.0

	for i in range(count):
		var view         = new_children[i]
		var t_pos        = Vector2(start_x + i * (card_w + sep), 40)
		var center_off   = (i - (count - 1) / 2.0)
		var t_rot        = center_off * 0.05
		var t_y_offset   = abs(center_off) * 4.0
		var final_pos    = t_pos + Vector2(0, t_y_offset)

		view.anim_pos = final_pos
		view.anim_rot = t_rot

		if is_new_card[i]:
			# 新卡飞入动画，终止可能残留的旧 tween
			if view.has_meta("_layout_tween"):
				var old: Tween = view.get_meta("_layout_tween")
				if old and old.is_valid():
					old.kill()
			var draw_instance_id := int(view.card_data.get("_instance_id", -1))
			var draw_delay := float(draw_order_by_id.get(draw_instance_id, i)) * 0.07
			if _reshuffle_anim_pending:
				draw_delay += 0.34
			var t = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
			t.tween_property(view, "position",   final_pos,    0.46).set_delay(draw_delay)
			t.tween_property(view, "rotation",   t_rot,        0.46).set_delay(draw_delay)
			t.tween_property(view, "scale",      Vector2.ONE,  0.46).set_delay(draw_delay)
			t.tween_property(view, "modulate:a", 1.0,          0.30).set_delay(draw_delay)
			view.set_meta("_layout_tween", t)
		else:
			# 已有卡复位：交给 CardView 内部 tween 管理，避免外部 tween 冲突
			view.move_to(final_pos, t_rot)

	_pending_draw_ids.clear()
	_reshuffle_anim_ids.clear()
	_reshuffle_anim_pending = false


func _draw_pile_anchor_local() -> Vector2:
	if _draw_pile_btn and is_instance_valid(_draw_pile_btn):
		return _global_to_hand_local(_draw_pile_btn.get_global_rect().get_center())
	var vp := get_viewport_rect()
	var global_pos := Vector2(74.0, vp.size.y - 154.0)
	return _global_to_hand_local(global_pos)


func _global_to_hand_local(global_pos: Vector2) -> Vector2:
	return hand_container.get_global_transform_with_canvas().affine_inverse() * global_pos


func _make_card_view(card: Dictionary) -> Control:
	var view: Control = CardViewScene.instantiate()
	var can_play: bool = _engine.can_play_card(card)
	view.setup(card, null, not can_play)
	view.hovered.connect(_on_card_hovered)
	view.unhovered.connect(_on_card_unhovered)
	view.activated.connect(_on_card_activated)
	view.play_blocked.connect(_on_card_play_blocked)
	return view


# ── 卡牌悬停预览 ─────────────────────────────────────────────────

func _on_card_hovered(card: Dictionary, card_rect: Rect2) -> void:
	# 将预览定位在悬停卡牌正上方，超出屏幕边界时修正
	var vp := get_viewport_rect()
	var px := card_rect.get_center().x - PREVIEW_W * 0.5
	var py := card_rect.position.y - PREVIEW_H - 16.0
	px = clamp(px, 4.0, vp.size.x - PREVIEW_W - 4.0)
	py = max(py, 4.0)
	_preview_renderer.position = Vector2(px, py)
	_preview_renderer.size = Vector2(PREVIEW_W, PREVIEW_H)
	_preview_renderer.setup(card, _compute_desc(card))

	_preview_root.show()


func _on_card_unhovered() -> void:
	_preview_root.hide()


func _on_card_activated(card: Dictionary) -> void:
	_preview_root.hide()
	_engine.play_card(card)


func _on_card_play_blocked(card: Dictionary) -> void:
	var reason: String = _engine.get_play_block_reason(card)
	if not reason.is_empty():
		_show_toast(reason)


# ── 格式化状态词条 ────────────────────────────────────────────────

func _show_draw_pile() -> void:
	_show_pile("抽牌堆", _engine.s["draw_pile"])


func _show_discard_pile() -> void:
	_show_pile("弃牌堆", _engine.s["discard_pile"])


func _show_pile(title: String, cards: Array) -> void:
	if _card_zoom_overlay:
		_card_zoom_overlay.hide_card()
	for child in _pile_grid.get_children():
		child.queue_free()
	_pile_title_label.text = "%s  %d张" % [title, cards.size()]
	if cards.is_empty():
		var empty := Label.new()
		empty.text = "这里暂时没有牌"
		empty.custom_minimum_size = Vector2(580, 80)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.75, 0.70, 0.62))
		_pile_grid.add_child(empty)
	else:
		for card in cards:
			var view: Control = CardViewScene.instantiate()
			view.custom_minimum_size = Vector2(100, 179)
			view.mouse_filter = Control.MOUSE_FILTER_STOP
			view.setup(card, null, true)
			view.set_hover_motion_enabled(false)
			view.play_blocked.connect(_show_pile_card_zoom.bind(card, view))
			_pile_grid.add_child(view)
	_pile_overlay.modulate.a = 0.0
	_pile_overlay.show()
	var t := create_tween()
	t.tween_property(_pile_overlay, "modulate:a", 1.0, 0.14)


func _show_pile_card_zoom(_blocked_card: Dictionary, card: Dictionary, source_view: Control) -> void:
	_card_zoom_overlay.show_card(card, _compute_desc(card), source_view.get_global_rect())


func _hide_pile_overlay() -> void:
	if _card_zoom_overlay:
		_card_zoom_overlay.hide_card()
	_pile_overlay.hide()


func _format_statuses(statuses: Dictionary) -> String:
	if statuses.is_empty():
		return ""
	var parts: Array[String] = []
	for k in statuses:
		parts.append("%s×%d" % [k, statuses[k]])
	return " ".join(parts)


# ── 按钮回调 ──────────────────────────────────────────────────────

func _on_end_turn_pressed() -> void:
	_engine.end_turn()


func _on_skill_btn_pressed() -> void:
	_engine.use_hero_skill()


func _on_result_btn_pressed() -> void:
	if _engine.s["battle_won"]:
		get_tree().change_scene_to_file(REWARD_SCREEN_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _compute_desc(card: Dictionary) -> String:
	var upgraded: bool = card.get("is_upgraded", false)
	var text: String   = card.get("desc", "")

	# 1. 解析 X(Y) 升级括号：未升级取 X，已升级取 Y
	var rx_bracket := RegEx.new()
	rx_bracket.compile("(\\d+%?)\\((\\d+%?)\\)")
	for m in rx_bracket.search_all(text):
		var pick: String = m.get_string(2) if upgraded else m.get_string(1)
		text = text.replace(m.get_string(0), pick)

	# 特殊：等量(+N) → 等量+N（已升级）/ 等量（未升级）
	var rx_equal := RegEx.new()
	rx_equal.compile("等量\\(\\+(\\d+)\\)")
	for m in rx_equal.search_all(text):
		var pick: String = "等量+%s" % m.get_string(1) if upgraded else "等量"
		text = text.replace(m.get_string(0), pick)

	# 2. 将所有"N 点伤害"替换为计算后的数值
	#    公式：floor((base + dao_xing) × damage_mult × 状态乘区)
	var dao_xing: int  = _engine.s.get("player_dao_xing", 0)
	var mult: float    = float(_engine.s.get("player_damage_mult", 1.0))
	var st: Dictionary = _engine.s.get("player_statuses", {})
	if st.get("xin_liu", 0) > 0: mult *= 1.25  # 心流
	if st.get("ku_jie",  0) > 0: mult *= 0.75  # 枯竭
	if st.get("xu_ruo",  0) > 0: mult *= 0.75  # 虚弱

	var rx_dmg := RegEx.new()
	rx_dmg.compile("(\\d+) 点伤害")
	for m in rx_dmg.search_all(text):
		var base     := int(m.get_string(1))
		var computed := int((base + dao_xing) * mult)
		text = text.replace(m.get_string(0), "%d 点伤害" % computed)

	return text
