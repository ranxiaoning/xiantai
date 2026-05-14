## BonfireUpgrade.gd
## 篝火升级卡牌全屏场景。
extends Control

const GAME_MAP_SCENE     := "res://scenes/GameMap.tscn"
const CardViewScene      = preload("res://scenes/CardView.tscn")
const CardRendererScript = preload("res://scripts/CardRenderer.gd")
const MenuUiStyle        = preload("res://scripts/ui/MenuUiStyle.gd")
const SafeNodeUiStyle    = preload("res://scripts/ui/SafeNodeUiStyle.gd")
const MAP_BG             = preload("res://assets/bg/map.png")

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
	var vp := get_viewport_rect().size

	var bg_tex := TextureRect.new()
	bg_tex.name = "BG"
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.texture = MAP_BG
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg_tex)

	var bg := ColorRect.new()
	bg.name = "BonfireDim"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.020, 0.012, 0.008, 0.72)
	add_child(bg)

	var panel_w := minf(vp.x * 0.92, 1180.0)
	var panel_h := minf(vp.y * 0.86, 640.0)
	var panel := PanelContainer.new()
	panel.name = "BonfirePanel"
	SafeNodeUiStyle.apply_modal_panel(panel, "bonfire")
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.offset_left = -panel_w * 0.5
	panel.offset_top = -panel_h * 0.5
	panel.offset_right = panel_w * 0.5
	panel.offset_bottom = panel_h * 0.5
	add_child(panel)

	var pad := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(side, 24)
	for side in ["margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 18)
	panel.add_child(pad)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 12)
	pad.add_child(root_box)

	var title_wrap := HBoxContainer.new()
	title_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	root_box.add_child(title_wrap)

	var title_pill := PanelContainer.new()
	title_pill.name = "BonfireTitlePill"
	SafeNodeUiStyle.apply_title_pill(title_pill, "red")
	title_wrap.add_child(title_pill)

	var title_pad := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		title_pad.add_theme_constant_override(side, 18)
	for side in ["margin_top", "margin_bottom"]:
		title_pad.add_theme_constant_override(side, 6)
	title_pill.add_child(title_pad)

	var title := Label.new()
	title.text = "🔥 篝火 · 选择一张卡牌升级"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuUiStyle.apply_heading(title, 28, Color(1.0, 0.88, 0.46, 1.0))
	title_pad.add_child(title)

	var hint := Label.new()
	hint.text = "点击卡牌预览升级效果并确认。已升级卡牌已置灰。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuUiStyle.apply_body(hint, 15, Color(0.82, 0.86, 0.84, 0.90))
	root_box.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.name = "BonfireCardScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_box.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "BonfireCardGrid"
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", H_SEP)
	grid.add_theme_constant_override("v_separation", H_SEP)
	scroll.add_child(grid)

	var card_w := int((panel_w - PAD_X - H_SEP * (COLS - 1)) / float(COLS))
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
			SafeNodeUiStyle.apply_choice_state(view, false, false, true, false)
		else:
			view.setup(card_data, null, false)
			view.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			view.mouse_entered.connect(func() -> void:
				SafeNodeUiStyle.animate_choice_hover(view, true)
			)
			view.mouse_exited.connect(func() -> void:
				SafeNodeUiStyle.animate_choice_hover(view, false)
			)
			view.activated.connect(_on_card_clicked.bind(i))

		grid.add_child(view)

	var skip_btn := Button.new()
	skip_btn.name = "BonfireSkipBtn"
	skip_btn.text       = "跳过"
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.custom_minimum_size = Vector2(120, 48)
	skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	MenuUiStyle.apply_button(skip_btn, "secondary", 20)
	skip_btn.pressed.connect(_on_skip)
	root_box.add_child(skip_btn)

	_build_upgrade_overlay()


func _build_upgrade_overlay() -> void:
	_upgrade_overlay = Control.new()
	_upgrade_overlay.name = "UpgradeOverlay"
	_upgrade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_upgrade_overlay.z_index = 100
	_upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upgrade_overlay.hide()
	add_child(_upgrade_overlay)

	# 遮罩：点击此区域（非卡牌）关闭 overlay
	var shade := ColorRect.new()
	shade.name = "UpgradePreviewScrim"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	SafeNodeUiStyle.apply_scrim(shade, 0.76)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(_on_shade_input)
	_upgrade_overlay.add_child(shade)

	var vp     := get_viewport_rect().size
	var card_h := minf(vp.y * 0.68, 580.0)
	var card_w := card_h / CARD_ASPECT

	var panel_w := card_w + 72.0
	var panel_h := card_h + 128.0
	var preview_panel := PanelContainer.new()
	preview_panel.name = "UpgradePreviewPanel"
	SafeNodeUiStyle.apply_modal_panel(preview_panel, "bonfire")
	preview_panel.set_anchors_preset(Control.PRESET_CENTER)
	preview_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	preview_panel.offset_left = -panel_w * 0.5
	preview_panel.offset_top = -panel_h * 0.5
	preview_panel.offset_right = panel_w * 0.5
	preview_panel.offset_bottom = panel_h * 0.5
	_upgrade_overlay.add_child(preview_panel)

	var pad := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 18)
	preview_panel.add_child(pad)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	pad.add_child(box)

	_overlay_renderer = CardRendererScript.new()
	_overlay_renderer.custom_minimum_size = Vector2(card_w, card_h)
	_overlay_renderer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_overlay_renderer.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(_overlay_renderer)

	# 确认升级按钮（卡牌正下方）
	var confirm := Button.new()
	confirm.name = "UpgradeConfirmBtn"
	confirm.text              = "确认升级"
	confirm.focus_mode        = Control.FOCUS_NONE
	confirm.custom_minimum_size = Vector2(160, 48)
	confirm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	MenuUiStyle.apply_button(confirm, "primary", 20)
	confirm.mouse_filter      = Control.MOUSE_FILTER_STOP
	confirm.pressed.connect(_on_confirm_upgrade)
	box.add_child(confirm)


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
