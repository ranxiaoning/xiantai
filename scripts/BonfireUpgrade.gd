## BonfireUpgrade.gd
## 篝火升级卡牌全屏场景。
extends Control

const GAME_MAP_SCENE    := "res://scenes/GameMap.tscn"
const CardViewScene     = preload("res://scenes/CardView.tscn")
const CardRendererScript = preload("res://scripts/CardRenderer.gd")

const COLS        := 5
const H_SEP       := 10
const CARD_ASPECT := 2752.0 / 1536.0
const PAD_X       := 96.0

var _preview_shade: ColorRect
var _preview_renderer


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
		view.setup(card_data, null, false)

		if already_upgraded:
			view.modulate.a = 0.4
			view.set_usable(false)
		else:
			var upgraded_data := card_data.duplicate(true)
			upgraded_data["is_upgraded"] = true
			view.hovered.connect(_on_card_hovered.bind(upgraded_data))
			view.unhovered.connect(_on_card_unhovered)
			view.activated.connect(_on_card_selected.bind(i))

		grid.add_child(view)

	# 升级预览浮层：MOUSE_FILTER_IGNORE 保证不拦截底层卡牌的鼠标事件
	_preview_shade = ColorRect.new()
	_preview_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_shade.color = Color(0.0, 0.0, 0.0, 0.55)
	_preview_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_shade.z_index = 200
	_preview_shade.hide()
	add_child(_preview_shade)

	_preview_renderer = CardRendererScript.new()
	_preview_renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_renderer.z_index = 201
	_preview_renderer.hide()
	add_child(_preview_renderer)
	_layout_preview()

	var skip_btn := Button.new()
	skip_btn.text       = "跳过"
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.add_theme_font_size_override("font_size", 20)
	skip_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	skip_btn.offset_left   = vp.x * 0.35
	skip_btn.offset_right  = -vp.x * 0.35
	skip_btn.offset_top    = -58
	skip_btn.offset_bottom = -8
	skip_btn.z_index       = 202
	skip_btn.pressed.connect(_on_skip)
	add_child(skip_btn)


func _layout_preview() -> void:
	if _preview_renderer == null:
		return
	var vp := get_viewport_rect().size
	var card_h := minf(vp.y - 72.0, 660.0)
	var card_w := card_h / CARD_ASPECT
	if card_w > vp.x - 72.0:
		card_w = vp.x - 72.0
		card_h = card_w * CARD_ASPECT
	_preview_renderer.size     = Vector2(card_w, card_h)
	_preview_renderer.position = (vp - Vector2(card_w, card_h)) * 0.5


# hovered 信号：(card_data, rect)；bind 追加 upgraded_data → 回调收到 (card_data, rect, upgraded_data)
func _on_card_hovered(_original_cd: Dictionary, _rect: Rect2, upgraded_data: Dictionary) -> void:
	_preview_renderer.setup(upgraded_data)
	_preview_renderer.show()
	_preview_shade.show()


func _on_card_unhovered() -> void:
	_preview_renderer.hide()
	_preview_shade.hide()


# activated 信号：(card_data)；bind 追加 deck_index → 回调收到 (card_data, deck_index)
func _on_card_selected(_card_data: Dictionary, deck_index: int) -> void:
	var base_id := GameState.deck[deck_index].trim_suffix("+")
	GameState.deck[deck_index] = base_id + "+"
	Log.info("BonfireUpgrade", "升级卡牌：%s+ (index=%d)" % [base_id, deck_index])
	get_tree().change_scene_to_file(GAME_MAP_SCENE)


func _on_skip() -> void:
	get_tree().change_scene_to_file(GAME_MAP_SCENE)
