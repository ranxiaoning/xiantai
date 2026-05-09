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


# hovered 信号：(card_data, rect)；bind 追加 upgraded_data → 回调收到 (card_data, rect, upgraded_data)
func _on_card_hovered(original_cd: Dictionary, rect: Rect2, upgraded_data: Dictionary) -> void:
	_card_zoom_overlay.show_card(upgraded_data, "", rect)


# activated 信号：(card_data)；bind 追加 deck_index → 回调收到 (card_data, deck_index)
func _on_card_selected(_card_data: Dictionary, deck_index: int) -> void:
	var base_id := GameState.deck[deck_index].trim_suffix("+")
	GameState.deck[deck_index] = base_id + "+"
	Log.info("BonfireUpgrade", "升级卡牌：%s+ (index=%d)" % [base_id, deck_index])
	get_tree().change_scene_to_file(GAME_MAP_SCENE)


func _on_skip() -> void:
	get_tree().change_scene_to_file(GAME_MAP_SCENE)
