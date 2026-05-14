## InGameMenu.gd
## 局内暂停菜单：右上角汉堡按钮，含放弃/返回/设置三项。
## 父场景 add_child 后连接 abandon_confirmed / return_to_menu_confirmed 信号。
class_name InGameMenu
extends Control

signal abandon_confirmed
signal return_to_menu_confirmed

const GOLD     := Color(0.82, 0.68, 0.39, 1.0)
const GOLD_DIM := Color(0.48, 0.39, 0.23, 1.0)
const INK      := Color(0.035, 0.052, 0.065, 0.92)
const INK_DARK := Color(0.018, 0.027, 0.036, 0.96)
const WHITE70  := Color(1.0, 1.0, 1.0, 0.70)

var _menu_btn:      Button
var _dim_bg:        ColorRect
var _menu_panel:    PanelContainer
var _confirm_panel: PanelContainer
var _confirm_label: Label
var _ok_btn:        Button
var _settings_overlay: Control
var _res_option:       OptionButton
var _display_mode_option: OptionButton
var _master_slider:    HSlider
var _master_label:     Label
var _music_slider:     HSlider
var _music_label:      Label
var _sfx_slider:       HSlider
var _sfx_label:        Label
var _lang_option:      OptionButton

var _pending_signal: String = ""   # "abandon" | "return"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 150
	_build_dim_bg()
	_build_menu_btn()
	_build_menu_panel()
	_build_confirm_panel()
	_build_settings_overlay()


# ── 样式工具 ────────────────────────────────────────────────────────

func _apply_panel_style(panel: PanelContainer, bg: Color, border: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	s.shadow_size = 8
	panel.add_theme_stylebox_override("panel", s)


func _apply_btn_style(btn: Button, bg: Color, border: Color,
		hover_bg: Color, font_color: Color) -> void:
	var mk := func(c_bg: Color, c_bor: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = c_bg
		s.border_color = c_bor
		s.set_border_width_all(1)
		s.set_corner_radius_all(4)
		return s
	btn.add_theme_stylebox_override("normal",  mk.call(bg,       border))
	btn.add_theme_stylebox_override("hover",   mk.call(hover_bg, GOLD))
	btn.add_theme_stylebox_override("pressed", mk.call(GOLD_DIM, GOLD))
	btn.add_theme_color_override("font_color",       font_color)
	btn.add_theme_color_override("font_hover_color", font_color.lightened(0.15))
	btn.add_theme_font_size_override("font_size", 13)


func _make_menu_item(label_text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(160, 32)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_btn_style(btn,
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.08),
		color)
	return btn


func _add_row_label(row: HBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(72, 0)
	lbl.add_theme_color_override("font_color", WHITE70)
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)


func _make_volume_row(parent: VBoxContainer, label_text: String) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	_add_row_label(row, label_text)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_NONE
	row.add_child(slider)
	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(38, 0)
	val_lbl.add_theme_color_override("font_color", WHITE70)
	val_lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(val_lbl)
	return [slider, val_lbl]


# ── 构建 ─────────────────────────────────────────────────────────────

func _build_dim_bg() -> void:
	_dim_bg = ColorRect.new()
	_dim_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim_bg.color = Color(0.0, 0.0, 0.0, 0.55)
	_dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_bg.hide()
	_dim_bg.gui_input.connect(_on_dim_bg_input)
	add_child(_dim_bg)


func _build_menu_btn() -> void:
	_menu_btn = Button.new()
	_menu_btn.text = "☰"
	_menu_btn.focus_mode = Control.FOCUS_NONE
	_menu_btn.custom_minimum_size = Vector2(40, 36)
	_menu_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_menu_btn.offset_left   = -46.0
	_menu_btn.offset_top    = 6.0
	_menu_btn.offset_right  = -6.0
	_menu_btn.offset_bottom = 42.0
	_menu_btn.add_theme_font_size_override("font_size", 18)
	_apply_btn_style(_menu_btn, INK_DARK, GOLD_DIM, INK, GOLD)
	_menu_btn.pressed.connect(_on_menu_btn_pressed)
	add_child(_menu_btn)


func _build_menu_panel() -> void:
	_menu_panel = PanelContainer.new()
	_apply_panel_style(_menu_panel, INK_DARK, GOLD_DIM)
	_menu_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_menu_panel.offset_left   = -200.0
	_menu_panel.offset_top    = 48.0
	_menu_panel.offset_right  = -6.0
	_menu_panel.offset_bottom = 48.0

	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	_menu_panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	margin.add_child(inner)

	var abandon_item := _make_menu_item("放弃本局游戏", Color(1.0, 0.50, 0.40, 1.0))
	abandon_item.pressed.connect(_on_abandon_pressed)
	inner.add_child(abandon_item)

	var return_item := _make_menu_item("返回主菜单", WHITE70)
	return_item.pressed.connect(_on_return_pressed)
	inner.add_child(return_item)

	var settings_item := _make_menu_item("设置", WHITE70)
	settings_item.pressed.connect(_on_settings_pressed)
	inner.add_child(settings_item)

	inner.add_child(HSeparator.new())

	var close_item := _make_menu_item("关闭菜单", Color(0.55, 0.55, 0.55, 1.0))
	close_item.pressed.connect(_close_menu)
	inner.add_child(close_item)

	_menu_panel.hide()
	add_child(_menu_panel)


func _build_confirm_panel() -> void:
	_confirm_panel = PanelContainer.new()
	_apply_panel_style(_confirm_panel, INK_DARK, GOLD_DIM)
	_confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	_confirm_panel.offset_left   = -160.0
	_confirm_panel.offset_top    = -72.0
	_confirm_panel.offset_right  =  160.0
	_confirm_panel.offset_bottom =  72.0

	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	_confirm_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	_confirm_label = Label.new()
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_label.add_theme_color_override("font_color", WHITE70)
	_confirm_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_confirm_label)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var cancel_btn := Button.new()
	cancel_btn.text = "取消"
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.custom_minimum_size = Vector2(88, 32)
	_apply_btn_style(cancel_btn, INK, GOLD_DIM, Color(0.12, 0.17, 0.22, 0.9), WHITE70)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	btn_row.add_child(cancel_btn)

	_ok_btn = Button.new()
	_ok_btn.text = "确定"
	_ok_btn.focus_mode = Control.FOCUS_NONE
	_ok_btn.custom_minimum_size = Vector2(88, 32)
	_apply_btn_style(_ok_btn,
		Color(0.55, 0.22, 0.18, 0.95),
		GOLD_DIM,
		Color(0.70, 0.28, 0.22, 1.0),
		Color(1.0, 0.90, 0.80, 1.0))
	_ok_btn.pressed.connect(_on_ok_pressed)
	btn_row.add_child(_ok_btn)

	_confirm_panel.hide()
	add_child(_confirm_panel)


func _build_settings_overlay() -> void:
	_settings_overlay = Control.new()
	_settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_overlay.add_child(dim)

	var panel := PanelContainer.new()
	_apply_panel_style(panel, INK_DARK, GOLD_DIM)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -250.0
	panel.offset_top    = -250.0
	panel.offset_right  =  250.0
	panel.offset_bottom =  250.0
	_settings_overlay.add_child(panel)

	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# 标题行 + 关闭按钮
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)
	var title_lbl := Label.new()
	title_lbl.text = "设置"
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", GOLD)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_lbl)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(28, 28)
	_apply_btn_style(close_btn, INK, GOLD_DIM, INK_DARK, WHITE70)
	close_btn.pressed.connect(_close_settings)
	title_row.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# 显示模式行
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 10)
	vbox.add_child(mode_row)
	_add_row_label(mode_row, "显示模式")
	_display_mode_option = OptionButton.new()
	_display_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_display_mode_option.focus_mode = Control.FOCUS_NONE
	_display_mode_option.add_item("窗口化")
	_display_mode_option.add_item("无边框窗口")
	_display_mode_option.add_item("全屏")
	_display_mode_option.item_selected.connect(func(idx: int) -> void:
		GlobalSettings.set_display_mode(idx)
		_res_option.disabled = idx == GlobalSettings.DISPLAY_MODE_FULLSCREEN)
	mode_row.add_child(_display_mode_option)

	# 分辨率行
	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 10)
	vbox.add_child(res_row)
	_add_row_label(res_row, "分辨率")
	_res_option = OptionButton.new()
	_res_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_res_option.focus_mode = Control.FOCUS_NONE
	for res: Vector2i in GlobalSettings.RESOLUTIONS:
		_res_option.add_item("%d × %d" % [res.x, res.y])
	_res_option.item_selected.connect(
		func(idx: int) -> void: GlobalSettings.resolution_index = idx)
	res_row.add_child(_res_option)

	# 主音量
	var mr: Array = _make_volume_row(vbox, "主音量")
	_master_slider = mr[0]
	_master_label  = mr[1]
	_master_slider.value_changed.connect(func(v: float) -> void:
		GlobalSettings.master_volume = v
		GlobalSettings.apply_audio()
		_master_label.text = "%d%%" % roundi(v * 100))

	# 音乐音量
	var msr: Array = _make_volume_row(vbox, "音乐")
	_music_slider = msr[0]
	_music_label  = msr[1]
	_music_slider.value_changed.connect(func(v: float) -> void:
		GlobalSettings.music_volume = v
		GlobalSettings.apply_audio()
		_music_label.text = "%d%%" % roundi(v * 100))

	# 音效音量
	var sfxr: Array = _make_volume_row(vbox, "音效")
	_sfx_slider = sfxr[0]
	_sfx_label  = sfxr[1]
	_sfx_slider.value_changed.connect(func(v: float) -> void:
		GlobalSettings.sfx_volume = v
		GlobalSettings.apply_audio()
		_sfx_label.text = "%d%%" % roundi(v * 100))

	# 语言行
	var lang_row := HBoxContainer.new()
	vbox.add_child(lang_row)
	_add_row_label(lang_row, "语言")
	_lang_option = OptionButton.new()
	_lang_option.focus_mode = Control.FOCUS_NONE
	_lang_option.add_item("中文")
	_lang_option.add_item("English")
	_lang_option.item_selected.connect(func(idx: int) -> void:
		GlobalSettings.language = "zh_CN" if idx == 0 else "en"
		GlobalSettings.apply_language())
	lang_row.add_child(_lang_option)

	vbox.add_child(HSeparator.new())

	# 应用并关闭按钮
	var apply_btn := Button.new()
	apply_btn.text = "应用并关闭"
	apply_btn.focus_mode = Control.FOCUS_NONE
	apply_btn.custom_minimum_size = Vector2(0, 34)
	_apply_btn_style(apply_btn,
		Color(0.22, 0.35, 0.22, 0.90),
		GOLD_DIM,
		Color(0.28, 0.45, 0.28, 1.0),
		Color(0.85, 1.0, 0.75, 1.0))
	apply_btn.pressed.connect(_on_apply_settings)
	vbox.add_child(apply_btn)

	_settings_overlay.hide()
	add_child(_settings_overlay)


# ── 设置加载 / 应用 ───────────────────────────────────────────────────

func _load_settings_to_ui() -> void:
	_display_mode_option.selected     = GlobalSettings.display_mode
	_res_option.selected             = GlobalSettings.resolution_index
	_res_option.disabled             = (
		GlobalSettings.display_mode == GlobalSettings.DISPLAY_MODE_FULLSCREEN
	)
	_master_slider.value = GlobalSettings.master_volume
	_music_slider.value  = GlobalSettings.music_volume
	_sfx_slider.value    = GlobalSettings.sfx_volume
	_master_label.text   = "%d%%" % roundi(GlobalSettings.master_volume * 100)
	_music_label.text    = "%d%%" % roundi(GlobalSettings.music_volume  * 100)
	_sfx_label.text      = "%d%%" % roundi(GlobalSettings.sfx_volume    * 100)
	_lang_option.selected = 0 if GlobalSettings.language == "zh_CN" else 1


func _on_apply_settings() -> void:
	GlobalSettings.apply_display()
	GlobalSettings.save_settings()
	_close_settings()


# ── 事件处理 ─────────────────────────────────────────────────────────

func _on_dim_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed \
			and _menu_panel.visible:
		_close_menu()


func _on_menu_btn_pressed() -> void:
	_dim_bg.show()
	_menu_panel.show()


func _close_menu() -> void:
	_menu_panel.hide()
	_dim_bg.hide()


func _on_abandon_pressed() -> void:
	_menu_panel.hide()
	_pending_signal = "abandon"
	_confirm_label.text = "确认放弃本局游戏？\n所有进度将会清除。"
	_confirm_panel.show()


func _on_return_pressed() -> void:
	_menu_panel.hide()
	_pending_signal = "return"
	_confirm_label.text = "确认返回主菜单？\n当前进度将会保留。"
	_confirm_panel.show()


func _on_cancel_pressed() -> void:
	_confirm_panel.hide()
	_dim_bg.hide()
	_pending_signal = ""


func _on_ok_pressed() -> void:
	_confirm_panel.hide()
	_dim_bg.hide()
	var sig := _pending_signal
	_pending_signal = ""
	if sig == "abandon":
		abandon_confirmed.emit()
	elif sig == "return":
		return_to_menu_confirmed.emit()


func _on_settings_pressed() -> void:
	_menu_panel.hide()
	_dim_bg.hide()
	_load_settings_to_ui()
	_settings_overlay.show()


func _close_settings() -> void:
	_settings_overlay.hide()
