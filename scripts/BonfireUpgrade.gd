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
var _selected_index: int = -1
var _selected_view: Control = null
var _confirm_btn: Button = null


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
	hint.text = "卡牌已显示升级后效果。点击选择升级；已升级卡牌（置灰）点击可查看详情。"
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

		# 直接在格子里显示升级后效果，方便玩家对比选择
		var display_data := card_data.duplicate(true)
		if not already_upgraded:
			display_data["is_upgraded"] = true

		var view: Control = CardViewScene.instantiate()
		view.custom_minimum_size = Vector2(card_w, card_h)
		view.mouse_filter        = Control.MOUSE_FILTER_STOP
		view.set_hover_motion_enabled(false)

		if already_upgraded:
			view.setup(display_data, null, true)   # disabled，已升级
			view.modulate.a = 0.4
			view.play_blocked.connect(_show_card_zoom.bind(display_data, view))
		else:
			view.setup(display_data, null, false)  # enabled，点击选中
			view.activated.connect(_on_card_clicked.bind(i, view))

		grid.add_child(view)

	# 底部按钮行
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	btn_row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	btn_row.offset_top    = -62
	btn_row.offset_bottom = -10
	add_child(btn_row)

	_confirm_btn = Button.new()
	_confirm_btn.text       = "确认升级"
	_confirm_btn.disabled   = true
	_confirm_btn.focus_mode = Control.FOCUS_NONE
	_confirm_btn.custom_minimum_size = Vector2(160, 48)
	_confirm_btn.add_theme_font_size_override("font_size", 20)
	_confirm_btn.pressed.connect(_on_confirm_upgrade)
	btn_row.add_child(_confirm_btn)

	var skip_btn := Button.new()
	skip_btn.text       = "跳过"
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.custom_minimum_size = Vector2(120, 48)
	skip_btn.add_theme_font_size_override("font_size", 20)
	skip_btn.pressed.connect(_on_skip)
	btn_row.add_child(skip_btn)


# play_blocked 信号：(card_data)；bind 追加 display_data, source_view → 回调收到 (cd, display_data, source_view)
func _show_card_zoom(_cd: Dictionary, display_data: Dictionary, source_view: Control) -> void:
	_card_zoom_overlay.show_card(display_data, "", source_view.get_global_rect())


# activated 信号：(card_data)；bind 追加 deck_index, source_view
func _on_card_clicked(_card_data: Dictionary, deck_index: int, source_view: Control) -> void:
	# 取消上一张选中的高亮
	if _selected_view != null and is_instance_valid(_selected_view):
		_selected_view.modulate = Color.WHITE

	_selected_index = deck_index
	_selected_view  = source_view
	source_view.modulate = Color(1.0, 0.88, 0.4, 1.0)  # 金色高亮
	_confirm_btn.disabled = false


func _on_confirm_upgrade() -> void:
	if _selected_index < 0:
		return
	var base_id := GameState.deck[_selected_index].trim_suffix("+")
	GameState.deck[_selected_index] = base_id + "+"
	Log.info("BonfireUpgrade", "升级卡牌：%s+ (index=%d)" % [base_id, _selected_index])
	get_tree().change_scene_to_file(GAME_MAP_SCENE)


func _on_skip() -> void:
	get_tree().change_scene_to_file(GAME_MAP_SCENE)
