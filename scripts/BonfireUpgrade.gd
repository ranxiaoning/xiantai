## BonfireUpgrade.gd
## 篝火升级卡牌全屏场景。
extends Control

const GAME_MAP_SCENE     := "res://scenes/GameMap.tscn"
const CardViewScene      = preload("res://scenes/CardView.tscn")
const CardRendererScript = preload("res://scripts/CardRenderer.gd")

const COLS        := 5
const H_SEP       := 10
const CARD_ASPECT := 2752.0 / 1536.0
const PAD_X       := 96.0

var _selected_index: int = -1
var _upgrade_overlay: Control = null
var _overlay_renderer          = null


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
	hint.text = "点击卡牌预览升级效果并确认。已升级卡牌已置灰。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left   = 0
	hint.offset_top    = 62
	hint.offset_right  = 0
	hint.offset_bottom = 98
	add_child(hint)

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
		view.set_hover_motion_enabled(false)

		if already_upgraded:
			view.setup(card_data, null, true)
			view.modulate.a = 0.4
		else:
			view.setup(card_data, null, false)
			view.activated.connect(_on_card_clicked.bind(i))

		grid.add_child(view)

	var skip_btn := Button.new()
	skip_btn.text       = "跳过"
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.custom_minimum_size = Vector2(120, 48)
	skip_btn.add_theme_font_size_override("font_size", 20)
	skip_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	skip_btn.offset_left   = (vp.x - 120.0) * 0.5
	skip_btn.offset_right  = -(vp.x - 120.0) * 0.5
	skip_btn.offset_top    = -58
	skip_btn.offset_bottom = -10
	skip_btn.pressed.connect(_on_skip)
	add_child(skip_btn)

	_build_upgrade_overlay()


func _build_upgrade_overlay() -> void:
	_upgrade_overlay = Control.new()
	_upgrade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_upgrade_overlay.z_index = 100
	_upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upgrade_overlay.hide()
	add_child(_upgrade_overlay)

	# 遮罩：点击此区域（非卡牌）关闭 overlay
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(_on_shade_input)
	_upgrade_overlay.add_child(shade)

	# 居中卡牌渲染器
	var vp     := get_viewport_rect().size
	var card_h := minf(vp.y * 0.68, 580.0)
	var card_w := card_h / CARD_ASPECT
	var card_x := (vp.x - card_w) * 0.5
	var card_y := (vp.y - card_h) * 0.5 - 36.0

	_overlay_renderer = CardRendererScript.new()
	_overlay_renderer.position     = Vector2(card_x, card_y)
	_overlay_renderer.size         = Vector2(card_w, card_h)
	_overlay_renderer.mouse_filter = Control.MOUSE_FILTER_STOP
	_upgrade_overlay.add_child(_overlay_renderer)

	# 确认升级按钮（卡牌正下方）
	var confirm := Button.new()
	confirm.text              = "确认升级"
	confirm.focus_mode        = Control.FOCUS_NONE
	confirm.custom_minimum_size = Vector2(160, 48)
	confirm.add_theme_font_size_override("font_size", 20)
	confirm.mouse_filter      = Control.MOUSE_FILTER_STOP
	confirm.position          = Vector2((vp.x - 160.0) * 0.5, card_y + card_h + 20.0)
	confirm.pressed.connect(_on_confirm_upgrade)
	_upgrade_overlay.add_child(confirm)


# 点击遮罩（非卡牌区域）关闭升级预览
func _on_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_upgrade_overlay.hide()
		_selected_index = -1


# activated 信号：(card_data)；bind 追加 deck_index → 回调收到 (card_data, deck_index)
func _on_card_clicked(card_data: Dictionary, deck_index: int) -> void:
	_selected_index = deck_index
	var upgraded_data := card_data.duplicate(true)
	upgraded_data["is_upgraded"] = true
	_overlay_renderer.setup(upgraded_data)
	_upgrade_overlay.show()


func _on_confirm_upgrade() -> void:
	if _selected_index < 0:
		return
	var base_id := GameState.deck[_selected_index].trim_suffix("+")
	GameState.deck[_selected_index] = base_id + "+"
	Log.info("BonfireUpgrade", "升级卡牌：%s+ (index=%d)" % [base_id, _selected_index])
	get_tree().change_scene_to_file(GAME_MAP_SCENE)


func _on_skip() -> void:
	get_tree().change_scene_to_file(GAME_MAP_SCENE)
