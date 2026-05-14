## BattleScene.gd
extends Control

const GAME_MAP_SCENE     := "res://scenes/GameMap.tscn"
const REWARD_SCREEN_SCENE := "res://scenes/RewardScreen.tscn"
const MAIN_MENU_SCENE    := "res://scenes/MainMenu.tscn"
const ENEMY_PORTRAIT_FALLBACK := "res://assets/portraits/enemy.png"
const _BattleEngineScript = preload("res://scripts/BattleEngine.gd")
const CardViewScene       = preload("res://scenes/CardView.tscn")
const CardRendererScript  = preload("res://scripts/CardRenderer.gd")
const ResourceOrbScene    = preload("res://scripts/ResourceOrb.gd")
const CardZoomOverlayScript = preload("res://scripts/CardZoomOverlay.gd")
const ArtifactIconScript = preload("res://scripts/ArtifactIcon.gd")
const StatusIconScript = preload("res://scripts/StatusIcon.gd")

# Preview size matches the card art ratio.
const PREVIEW_W := 280
const PREVIEW_H := 502
const BATTLE_BAG_PER_PAGE := 5
const BATTLE_ART_PER_PAGE := 10
const STATUS_BAR_COLUMNS := 7
const STATUS_BAR_MAX_ICONS := 14
const STATUS_KEY_ORDER: Array[String] = ["xin_liu", "bu_qin", "jing_ci", "lie_shang", "ku_jie", "xu_ruo", "zhen_she"]
const CARD_NUM_COLOR_NORMAL := Color(40.0 / 255.0, 20.0 / 255.0, 0.0, 1.0)
const CARD_NUM_COLOR_UP := Color(0.06, 0.48, 0.18, 1.0)
const CARD_NUM_COLOR_DOWN := Color(0.72, 0.08, 0.05, 1.0)

var _engine: RefCounted
var _enemy_portrait_path := ""
var _enemy_portrait_texture: Texture2D
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
var _draw_pile_btn: Button
var _discard_pile_btn: Button
var _pile_overlay: Control
var _pile_title_label: Label
var _pile_grid: GridContainer
var _card_zoom_overlay
var _top_left_hud: VBoxContainer
var _battle_bag_prev: Button
var _battle_bag_next: Button
var _battle_bag_slots: HBoxContainer
var _battle_art_row: HBoxContainer
var _battle_art_prev: Button
var _battle_art_next: Button
var _battle_art_slots: HBoxContainer
var _battle_bag_page := 0
var _battle_art_page := 0
var _artifact_detail_dialog: AcceptDialog
var _player_status_bar: GridContainer
var _enemy_status_bar: GridContainer

# ── UI 节点引用 ────────────────────────────────────────────────────
@onready var enemy_name_label:     Label         = %EnemyName
@onready var enemy_portrait:       TextureRect   = $Entities/EnemyCard/VBox/EnemyPortrait
@onready var enemy_hp_shield_bar  = %EnemyHPShieldBar
@onready var enemy_intent_label:   Label         = %IntentLabel
@onready var enemy_status_label:   Label         = %EnemyStatusLabel
@onready var enemy_status_scene_bar: GridContainer = %EnemyStatusBar

@onready var player_hp_shield_bar = %PlayerHPShieldBar
@onready var player_status_scene_bar: GridContainer = %PlayerStatusBar
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
	_build_status_bars()
	_build_top_left_hud()
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


func _build_top_left_hud() -> void:
	_top_left_hud = VBoxContainer.new()
	_top_left_hud.name = "TopLeftHUD"
	_top_left_hud.anchor_left = 0.0
	_top_left_hud.anchor_top = 0.0
	_top_left_hud.anchor_right = 0.0
	_top_left_hud.anchor_bottom = 0.0
	_top_left_hud.offset_left = 10.0
	_top_left_hud.offset_top = 8.0
	_top_left_hud.offset_right = 360.0
	_top_left_hud.offset_bottom = 92.0
	_top_left_hud.z_index = 14
	_top_left_hud.mouse_filter = Control.MOUSE_FILTER_PASS
	_top_left_hud.add_theme_constant_override("separation", 4)
	add_child(_top_left_hud)

	var bag_row := HBoxContainer.new()
	bag_row.add_theme_constant_override("separation", 4)
	_top_left_hud.add_child(bag_row)

	_battle_bag_prev = _make_small_nav_button("<")
	_battle_bag_prev.pressed.connect(_on_battle_bag_prev)
	bag_row.add_child(_battle_bag_prev)
	_battle_bag_slots = HBoxContainer.new()
	_battle_bag_slots.add_theme_constant_override("separation", 4)
	bag_row.add_child(_battle_bag_slots)
	_battle_bag_next = _make_small_nav_button(">")
	_battle_bag_next.pressed.connect(_on_battle_bag_next)
	bag_row.add_child(_battle_bag_next)

	_battle_art_row = HBoxContainer.new()
	_battle_art_row.add_theme_constant_override("separation", 4)
	_top_left_hud.add_child(_battle_art_row)
	_battle_art_prev = _make_small_nav_button("<")
	_battle_art_prev.pressed.connect(_on_battle_art_prev)
	_battle_art_row.add_child(_battle_art_prev)
	_battle_art_slots = HBoxContainer.new()
	_battle_art_slots.add_theme_constant_override("separation", 4)
	_battle_art_row.add_child(_battle_art_slots)
	_battle_art_next = _make_small_nav_button(">")
	_battle_art_next.pressed.connect(_on_battle_art_next)
	_battle_art_row.add_child(_battle_art_next)

	_refresh_battle_hud()


func _make_small_nav_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(20, 36)
	btn.add_theme_font_size_override("font_size", 13)
	return btn


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
	right_box.custom_minimum_size = Vector2(145, 40)
	right_box.add_theme_constant_override("separation", 5)
	row.add_child(right_box)

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


func _build_status_bars() -> void:
	enemy_status_label.hide()
	var enemy_parent := enemy_status_label.get_parent()
	if enemy_parent:
		_enemy_status_bar = enemy_status_scene_bar
		if _enemy_status_bar == null:
			_enemy_status_bar = _make_status_bar("EnemyStatusBar")
			enemy_parent.add_child(_enemy_status_bar)
			enemy_parent.move_child(_enemy_status_bar, enemy_status_label.get_index())
		_configure_status_bar(_enemy_status_bar, "EnemyStatusBar")

	var player_parent := player_hp_shield_bar.get_parent()
	if player_parent:
		_player_status_bar = player_status_scene_bar
		if _player_status_bar == null:
			_player_status_bar = _make_status_bar("PlayerStatusBar")
			player_parent.add_child(_player_status_bar)
			player_parent.move_child(_player_status_bar, player_hp_shield_bar.get_index() + 1)
		_configure_status_bar(_player_status_bar, "PlayerStatusBar")


func _make_status_bar(node_name: String) -> GridContainer:
	var bar := GridContainer.new()
	_configure_status_bar(bar, node_name)
	return bar


func _configure_status_bar(bar: GridContainer, node_name: String) -> void:
	bar.name = node_name
	bar.columns = STATUS_BAR_COLUMNS
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(0, 32)
	bar.add_theme_constant_override("h_separation", 3)
	bar.add_theme_constant_override("v_separation", 3)
	bar.visible = false
	bar.mouse_filter = Control.MOUSE_FILTER_PASS


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
	var node_type: String = GameState.pending_battle_node_type
	if node_type.is_empty():
		node_type = "normal"
	var enemy_data := EnemyDatabase.get_enemy_for_node(node_type, GameState.pending_battle_node_floor)

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
	_update_enemy_portrait(s["enemy_data"])
	enemy_hp_shield_bar.set_values(s["enemy_hp"], s["enemy_hp_max"], s["enemy_hu_ti"])
	enemy_intent_label.text = "意图：" + s["enemy_intent_text"]

	player_hp_shield_bar.set_values(s["player_hp"], s["player_hp_max"], s["player_hu_ti"])
	_refresh_unit_status_bars(s)
	_update_resource_dock(s)
	_refresh_battle_hud()

	var is_player_turn: bool = (s["phase"] == "player")
	end_turn_btn.disabled = not is_player_turn
	skill_btn.disabled    = not _engine.can_use_skill()
	skill_btn.text        = "剑意凝神\n(道慧%d)" % s["skill_dao_hui_cost"]

	_update_hand_display()


func _update_enemy_portrait(enemy_data: Dictionary) -> void:
	var path := str(enemy_data.get("portrait_path", ""))
	if path.is_empty():
		path = ENEMY_PORTRAIT_FALLBACK
	if path == _enemy_portrait_path:
		return

	var tex := load(path) as Texture2D
	if tex == null and path != ENEMY_PORTRAIT_FALLBACK:
		path = ENEMY_PORTRAIT_FALLBACK
		tex = load(path) as Texture2D

	_enemy_portrait_path = path
	_enemy_portrait_texture = tex
	enemy_portrait.texture = _enemy_portrait_texture


func _refresh_battle_hud() -> void:
	_refresh_battle_bag()
	_refresh_battle_artifacts()


func _refresh_battle_bag() -> void:
	if _battle_bag_slots == null:
		return
	for c in _battle_bag_slots.get_children():
		c.queue_free()

	var items: Array = GameState.consumables
	var max_page := maxi(0, ceili(float(items.size()) / BATTLE_BAG_PER_PAGE) - 1)
	_battle_bag_page = clampi(_battle_bag_page, 0, max_page)
	var start := _battle_bag_page * BATTLE_BAG_PER_PAGE
	var can_use := _engine != null and str(_engine.s.get("phase", "")) == "player"

	for i in range(BATTLE_BAG_PER_PAGE):
		var idx := start + i
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(44, 44)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 11)
		if idx < items.size():
			var item: Dictionary = items[idx]
			btn.text = (item.get("name", "?") as String).left(2)
			btn.tooltip_text = "%s\n%s" % [item.get("name", ""), item.get("effect_desc", "")]
			btn.disabled = not can_use
			btn.add_theme_stylebox_override("normal", _battle_item_slot_style(true, false))
			btn.add_theme_stylebox_override("hover", _battle_item_slot_style(true, true))
			btn.add_theme_stylebox_override("pressed", _battle_item_slot_style(true, true))
			btn.add_theme_stylebox_override("disabled", _battle_item_slot_style(true, false, true))
			btn.pressed.connect(_on_battle_item_pressed.bind(idx))
		else:
			btn.text = ""
			btn.disabled = true
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var empty := _battle_item_slot_style(false)
			btn.add_theme_stylebox_override("normal", empty)
			btn.add_theme_stylebox_override("disabled", empty)
		_battle_bag_slots.add_child(btn)

	_battle_bag_prev.visible = (_battle_bag_page > 0)
	_battle_bag_next.visible = ((_battle_bag_page + 1) * BATTLE_BAG_PER_PAGE < items.size())


func _battle_item_slot_style(filled: bool, hovered: bool = false, disabled: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(22)
	s.set_border_width_all(2)
	if not filled:
		s.bg_color = Color(0.08, 0.08, 0.08, 0.45)
		s.border_color = Color(0.45, 0.40, 0.28, 0.35)
	elif disabled:
		s.bg_color = Color(0.16, 0.14, 0.10, 0.65)
		s.border_color = Color(0.45, 0.40, 0.28, 0.55)
	elif hovered:
		s.bg_color = Color(0.38, 0.30, 0.14, 0.95)
		s.border_color = Color(0.95, 0.80, 0.30, 1.0)
	else:
		s.bg_color = Color(0.28, 0.22, 0.10, 0.9)
		s.border_color = Color(0.82, 0.70, 0.28, 0.95)
	return s


func _refresh_battle_artifacts() -> void:
	if _battle_art_slots == null:
		return
	for c in _battle_art_slots.get_children():
		c.queue_free()

	var artifacts: Array = GameState.artifacts
	_battle_art_row.visible = not artifacts.is_empty()
	if artifacts.is_empty():
		_battle_art_page = 0
		_battle_art_prev.visible = false
		_battle_art_next.visible = false
		return

	var flash_id := str(GameState.last_acquired_artifact_id)
	if not flash_id.is_empty():
		for i in range(artifacts.size()):
			if str((artifacts[i] as Dictionary).get("id", "")) == flash_id:
				_battle_art_page = int(i / BATTLE_ART_PER_PAGE)
				break

	var max_page := maxi(0, ceili(float(artifacts.size()) / BATTLE_ART_PER_PAGE) - 1)
	_battle_art_page = clampi(_battle_art_page, 0, max_page)
	var start := _battle_art_page * BATTLE_ART_PER_PAGE
	var end := mini(start + BATTLE_ART_PER_PAGE, artifacts.size())
	for i in range(start, end):
		var art: Dictionary = artifacts[i]
		var icon: Control = ArtifactIconScript.new()
		icon.setup(art)
		icon.activated.connect(_show_artifact_detail)
		_battle_art_slots.add_child(icon)
		if not flash_id.is_empty() and str(art.get("id", "")) == flash_id:
			icon.call_deferred("play_acquire_flash")
			GameState.last_acquired_artifact_id = ""

	_battle_art_prev.visible = (_battle_art_page > 0)
	_battle_art_next.visible = ((_battle_art_page + 1) * BATTLE_ART_PER_PAGE < artifacts.size())


func _on_battle_item_pressed(idx: int) -> void:
	if _engine == null:
		return
	var result: Dictionary = GameState.use_consumable(idx, "battle")
	var max_page := maxi(0, ceili(float(GameState.consumables.size()) / BATTLE_BAG_PER_PAGE) - 1)
	_battle_bag_page = mini(_battle_bag_page, max_page)
	_refresh_battle_bag()
	if not bool(result.get("ok", false)):
		_show_toast(str(result.get("message", "")))
		return
	var effect: Dictionary = result.get("battle_use", {})
	if effect.is_empty():
		_show_toast("当前战斗无法使用该物品。")
		return
	_engine.apply_battle_consumable_effect(effect)
	_show_toast(str(result.get("message", "已使用物品")))
	_refresh_battle_hud()


func _show_artifact_detail(art: Dictionary, _source: Control = null) -> void:
	if _artifact_detail_dialog == null or not is_instance_valid(_artifact_detail_dialog):
		_artifact_detail_dialog = AcceptDialog.new()
		_artifact_detail_dialog.title = "宝物"
		_artifact_detail_dialog.min_size = Vector2i(420, 260)
		add_child(_artifact_detail_dialog)
	var rarity := ArtifactIconScript.rarity_label(str(art.get("rarity", "yellow")))
	var detail := str(art.get("artifact_detail", ""))
	_artifact_detail_dialog.title = "%s · %s" % [art.get("name", "宝物"), rarity]
	_artifact_detail_dialog.dialog_text = str(art.get("effect_desc", ""))
	if not detail.is_empty():
		_artifact_detail_dialog.dialog_text += "\n\n" + detail
	_artifact_detail_dialog.popup_centered(Vector2i(420, 260))


func _on_battle_bag_prev() -> void:
	_battle_bag_page = maxi(0, _battle_bag_page - 1)
	_refresh_battle_bag()


func _on_battle_bag_next() -> void:
	_battle_bag_page += 1
	_refresh_battle_bag()


func _on_battle_art_prev() -> void:
	_battle_art_page = maxi(0, _battle_art_page - 1)
	_refresh_battle_artifacts()


func _on_battle_art_next() -> void:
	_battle_art_page += 1
	_refresh_battle_artifacts()


func _update_resource_dock(s: Dictionary) -> void:
	if _ling_li_orb:
		_ling_li_orb.set_values(s["player_ling_li"], s["player_ling_li_max"], "灵力")
	if _dao_hui_orb:
		_dao_hui_orb.set_values(s["player_dao_hui"], s["player_dao_hui_max"], "道慧")
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
		if view.has_method("set_description_segments_override"):
			view.set_description_segments_override(_compute_desc_segments(c_data))
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
	_preview_renderer.setup(card, _compute_desc(card), _compute_desc_segments(card))

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
	_card_zoom_overlay.show_card(card, _compute_desc(card), source_view.get_global_rect(), _compute_desc_segments(card))


func _hide_pile_overlay() -> void:
	if _card_zoom_overlay:
		_card_zoom_overlay.hide_card()
	_pile_overlay.hide()


func _refresh_unit_status_bars(battle_state: Dictionary) -> void:
	var player_entries := build_player_status_entries(battle_state)
	var enemy_entries := build_enemy_status_entries(battle_state)
	_refresh_status_bar(_player_status_bar, player_entries)
	_refresh_status_bar(_enemy_status_bar, enemy_entries)

	var visible_player_bar := find_child("PlayerStatusBar", true, false) as GridContainer
	if visible_player_bar != null and visible_player_bar != _player_status_bar:
		_refresh_status_bar(visible_player_bar, player_entries)
	var visible_enemy_bar := find_child("EnemyStatusBar", true, false) as GridContainer
	if visible_enemy_bar != null and visible_enemy_bar != _enemy_status_bar:
		_refresh_status_bar(visible_enemy_bar, enemy_entries)


func _refresh_status_bar(bar: GridContainer, entries: Array) -> void:
	if bar == null:
		return
	for child in bar.get_children():
		child.free()

	if entries.is_empty():
		bar.visible = false
		return

	var shown: Array = []
	if entries.size() > STATUS_BAR_MAX_ICONS:
		for i in range(STATUS_BAR_MAX_ICONS - 1):
			shown.append(entries[i])
		shown.append(_make_status_entry(
			"overflow",
			"更多状态",
			entries.size() - shown.size(),
			"还有 %d 个状态未显示。" % (entries.size() - shown.size()),
			"temporary"
		))
	else:
		shown = entries

	bar.custom_minimum_size = Vector2(0, 67 if shown.size() > STATUS_BAR_COLUMNS else 32)
	bar.visible = true
	for entry in shown:
		var icon: Control = StatusIconScript.new()
		icon.setup(entry as Dictionary)
		bar.add_child(icon)


static func build_player_status_entries(battle_state: Dictionary) -> Array:
	var entries: Array = []
	var base_regen := int(battle_state.get("player_ling_li_base_regen", GameState.character.get("ling_li_regen", 3)))
	entries.append(_make_status_entry("base_ling_li_regen", "基础灵力回复", base_regen, "每个玩家回合开始回复 %d 点灵力。" % base_regen, "core"))

	var actual_regen := int(battle_state.get("player_ling_li_regen", base_regen))
	if GameState.has_artifact("R-S06"):
		actual_regen += 1
	var bonus_regen := maxi(0, actual_regen - base_regen)
	if bonus_regen > 0:
		entries.append(_make_status_entry("bonus_ling_li_regen", "额外灵力回复", bonus_regen, "每个玩家回合开始额外回复 %d 点灵力。" % bonus_regen, "positive"))

	var dao_xing := int(battle_state.get("player_dao_xing", 0))
	entries.append(_make_status_entry("dao_xing", "道行", dao_xing, "当前道行。术法伤害按道行获得绝对值加成。", "core"))

	_append_status_dict(entries, battle_state.get("player_statuses", {}))
	_append_temp_entry(entries, battle_state, "next_attack_bonus", "下一攻加伤", "下一张术法攻击额外造成 %d 点伤害。")
	_append_temp_entry(entries, battle_state, "next_turn_dao_xing", "下回合道行", "下个玩家回合开始获得 %d 层道行。")
	_append_temp_entry(entries, battle_state, "extra_draw_next_turn", "下回合抽牌", "下个玩家回合开始额外抽 %d 张牌。")
	_append_temp_entry(entries, battle_state, "death_save_charges", "濒死保护", "可抵挡致死伤害 %d 次。")
	_append_temp_entry(entries, battle_state, "debuff_ward_charges", "负面免疫", "可抵消负面状态 %d 次。")
	return entries


static func build_enemy_status_entries(battle_state: Dictionary) -> Array:
	var entries: Array = []
	var dao_xing := int(battle_state.get("enemy_dao_xing", 0))
	if dao_xing > 0:
		entries.append(_make_status_entry("enemy_dao_xing", "道行", dao_xing, "敌方当前道行。敌方攻击按道行获得绝对值加成。", "core"))

	var jing_ci := int(battle_state.get("enemy_jing_ci", 0))
	if jing_ci > 0:
		entries.append(_make_status_entry("jing_ci", "荆棘", jing_ci, "受到攻击时反伤 %d 点。" % jing_ci, "positive"))

	_append_status_dict(entries, battle_state.get("enemy_statuses", {}))
	_append_temp_entry(entries, battle_state, "enemy_action_delay", "行动延后", "敌方行动会被延后 %d 次。")
	return entries


static func _append_status_dict(entries: Array, raw_statuses) -> void:
	if not (raw_statuses is Dictionary):
		return
	var statuses: Dictionary = raw_statuses
	for key in STATUS_KEY_ORDER:
		_append_status_key(entries, statuses, key)

	var extras: Array[String] = []
	for raw_key in statuses.keys():
		var key := str(raw_key)
		if not STATUS_KEY_ORDER.has(key):
			extras.append(key)
	extras.sort()
	for key in extras:
		_append_status_key(entries, statuses, key)


static func _append_status_key(entries: Array, statuses: Dictionary, key: String) -> void:
	var value := int(statuses.get(key, 0))
	if value <= 0:
		return
	entries.append(_make_status_entry(key, _status_label(key), value, _status_tooltip(key, value), _status_kind(key)))


static func _append_temp_entry(entries: Array, battle_state: Dictionary, key: String, label: String, tooltip_template: String) -> void:
	var value := int(battle_state.get(key, 0))
	if value <= 0:
		return
	entries.append(_make_status_entry(key, label, value, tooltip_template % value, "temporary"))


static func _make_status_entry(id: String, label: String, value: int, tooltip: String, kind: String) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"value": value,
		"tooltip": "%s：%s" % [label, tooltip],
		"kind": kind,
	}


static func _status_kind(key: String) -> String:
	match key:
		"xin_liu", "bu_qin", "jing_ci":
			return "positive"
		"lie_shang", "ku_jie", "xu_ruo", "zhen_she":
			return "negative"
		_:
			return "temporary"


static func _status_label(key: String) -> String:
	match key:
		"xin_liu":
			return "心流"
		"bu_qin":
			return "不侵"
		"jing_ci":
			return "荆棘"
		"lie_shang":
			return "裂伤"
		"ku_jie":
			return "枯竭"
		"xu_ruo":
			return "虚弱"
		"zhen_she":
			return "震慑"
		_:
			return key


static func _status_tooltip(key: String, value: int) -> String:
	match key:
		"xin_liu":
			return "造成伤害提高，剩余 %d 回合。" % value
		"bu_qin":
			return "受到伤害降低，可生效 %d 次。" % value
		"jing_ci":
			return "受到攻击时反伤 %d 点。" % value
		"lie_shang":
			return "受到伤害提高，剩余 %d 回合。" % value
		"ku_jie":
			return "造成伤害降低，剩余 %d 回合。" % value
		"xu_ruo":
			return "攻击伤害降低，剩余 %d 回合。" % value
		"zhen_she":
			return "行动效率受限，剩余 %d 回合。" % value
		_:
			return "当前值 %d。" % value


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


func _compute_desc_segments(card: Dictionary) -> Array:
	return build_dynamic_description_segments(card, _engine.s)


static func build_dynamic_description_segments(card: Dictionary, battle_state: Dictionary) -> Array:
	var text: String = CardRendererScript.resolve_description(card)
	var dao_xing: int = int(battle_state.get("player_dao_xing", 0))
	var mult: float = float(battle_state.get("player_damage_mult", 1.0))
	var st: Dictionary = battle_state.get("player_statuses", {})
	if int(st.get("xin_liu", 0)) > 0:
		mult *= 1.25
	if int(st.get("ku_jie", 0)) > 0:
		mult *= 0.75
	if int(st.get("xu_ruo", 0)) > 0:
		mult *= 0.75

	var rx_dmg := RegEx.new()
	rx_dmg.compile("(\\d+) 点伤害")
	var matches := rx_dmg.search_all(text)
	if matches.is_empty():
		return [{"text": text, "color": CARD_NUM_COLOR_NORMAL}]

	var segments: Array = []
	var pos := 0
	for m in matches:
		if m.get_start() > pos:
			segments.append({"text": text.substr(pos, m.get_start() - pos), "color": CARD_NUM_COLOR_NORMAL})

		var base := int(m.get_string(1))
		var computed := floori((base + dao_xing) * mult)
		segments.append({
			"text": str(computed),
			"color": _damage_number_color(computed, base)
		})

		var suffix_start := m.get_start() + m.get_string(1).length()
		segments.append({
			"text": text.substr(suffix_start, m.get_end() - suffix_start),
			"color": CARD_NUM_COLOR_NORMAL
		})
		pos = m.get_end()

	if pos < text.length():
		segments.append({"text": text.substr(pos), "color": CARD_NUM_COLOR_NORMAL})
	return segments


static func _damage_number_color(current: int, base: int) -> Color:
	if current > base:
		return CARD_NUM_COLOR_UP
	if current < base:
		return CARD_NUM_COLOR_DOWN
	return CARD_NUM_COLOR_NORMAL


static func _segments_to_text(segments: Array) -> String:
	var text := ""
	for segment in segments:
		text += str(segment.get("text", ""))
	return text


func _compute_desc(card: Dictionary) -> String:
	return _segments_to_text(_compute_desc_segments(card))
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
