extends RefCounted

const FONT_TITLE = preload("res://assets/fonts/NotoSerifSC-Regular.otf")
const FONT_BODY = preload("res://assets/fonts/NotoSansSC-Regular.otf")

const PANEL_JADE = preload("res://assets/ui/menu/panel_jade_9.png")
const PANEL_DARK = preload("res://assets/ui/menu/panel_dark_9.png")
const PANEL_SCROLL = preload("res://assets/ui/menu/panel_scroll_9.png")
const PANEL_STAT = preload("res://assets/ui/menu/panel_stat_9.png")
const PANEL_ALTAR = preload("res://assets/ui/menu/panel_altar_9.png")

const BTN_PRIMARY_NORMAL = preload("res://assets/ui/menu/button_primary_normal_9.png")
const BTN_PRIMARY_HOVER = preload("res://assets/ui/menu/button_primary_hover_9.png")
const BTN_PRIMARY_PRESSED = preload("res://assets/ui/menu/button_primary_pressed_9.png")
const BTN_SECONDARY_NORMAL = preload("res://assets/ui/menu/button_secondary_normal_9.png")
const BTN_SECONDARY_HOVER = preload("res://assets/ui/menu/button_secondary_hover_9.png")
const BTN_SECONDARY_PRESSED = preload("res://assets/ui/menu/button_secondary_pressed_9.png")

const GOLD := Color(0.86, 0.70, 0.36, 1.0)
const GOLD_LIGHT := Color(1.0, 0.91, 0.58, 1.0)
const JADE_DARK := Color(0.08, 0.22, 0.24, 1.0)
const TEXT_MAIN := Color(0.98, 0.95, 0.84, 1.0)
const TEXT_SOFT := Color(0.78, 0.88, 0.90, 1.0)
const TEXT_MUTED := Color(0.56, 0.68, 0.74, 1.0)


static func apply_heading(label: Label, font_size: int = 52, color: Color = TEXT_MAIN) -> void:
	label.add_theme_font_override("font", FONT_TITLE)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.035, 0.040, 0.60))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 2)


static func apply_body(label: Label, font_size: int = 15, color: Color = TEXT_SOFT) -> void:
	label.add_theme_font_override("font", FONT_BODY)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.025, 0.030, 0.42))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 1)


static func apply_panel(panel: PanelContainer, variant: String = "jade") -> void:
	var tex: Texture2D = PANEL_JADE
	var margin := 24
	var content := 0
	match variant:
		"dark":
			tex = PANEL_DARK
			margin = 24
		"gold", "jade":
			tex = PANEL_JADE
			margin = 24
		"soft", "scroll":
			tex = PANEL_SCROLL
			margin = 22
		"stat":
			tex = PANEL_STAT
			margin = 18
		"altar", "stage":
			tex = PANEL_ALTAR
			margin = 28
		"empty":
			panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			return
	panel.add_theme_stylebox_override("panel", _texture_style(tex, margin, content))


static func apply_modal_panel(panel: PanelContainer, variant: String = "default") -> void:
	var panel_variant := "dark"
	match variant:
		"map":
			panel_variant = "altar"
		"event":
			panel_variant = "scroll"
		"bonfire":
			panel_variant = "altar"
		_:
			panel_variant = "dark"
	apply_panel(panel, panel_variant)


static func apply_result_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _flat(Color(0.10, 0.085, 0.045, 0.74), Color(0.86, 0.66, 0.34, 0.58), 1, 6))


static func apply_choice_card(panel: PanelContainer, selected: bool = false, disabled: bool = false) -> void:
	var bg := Color(0.055, 0.070, 0.078, 0.76)
	var border := Color(0.62, 0.50, 0.30, 0.58)
	var width := 1
	if selected:
		bg = Color(0.18, 0.135, 0.045, 0.92)
		border = GOLD_LIGHT
		width = 2
	elif disabled:
		bg = Color(0.045, 0.045, 0.050, 0.52)
		border = Color(0.34, 0.32, 0.27, 0.50)
	var style := _flat(bg, border, width, 7)
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", style)


static func apply_scrim(rect: ColorRect, alpha: float = 0.74) -> void:
	rect.color = Color(0.008, 0.012, 0.017, alpha)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP


static func apply_title_pill(panel: PanelContainer, variant: String = "gold") -> void:
	var bg := Color(0.13, 0.10, 0.055, 0.86)
	var border := Color(0.92, 0.72, 0.34, 0.72)
	if variant == "red":
		bg = Color(0.16, 0.055, 0.040, 0.86)
		border = Color(0.98, 0.48, 0.28, 0.74)
	elif variant == "blue":
		bg = Color(0.045, 0.085, 0.105, 0.82)
		border = Color(0.42, 0.82, 0.92, 0.62)
	var style := _flat(bg, border, 1, 6)
	style.content_margin_left = 14
	style.content_margin_top = 6
	style.content_margin_right = 14
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)


static func apply_button(btn: Button, kind: String = "secondary", font_size: int = 17) -> void:
	var primary := kind == "primary"
	var gold_target_state := primary or kind == "secondary"
	var normal_tex := BTN_PRIMARY_NORMAL if primary else BTN_SECONDARY_NORMAL
	var hover_tex := BTN_PRIMARY_HOVER if gold_target_state else BTN_SECONDARY_HOVER
	var pressed_tex := BTN_PRIMARY_PRESSED if primary else BTN_SECONDARY_PRESSED
	var tex_margin := 28 if primary else 24
	var hover_margin := 28 if gold_target_state else tex_margin
	var content_y := 12 if primary else 10
	var hover_content_y := 12 if gold_target_state else content_y
	btn.add_theme_font_override("font", FONT_BODY)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_stylebox_override("normal", _texture_style(normal_tex, tex_margin, content_y))
	btn.add_theme_stylebox_override("hover", _texture_style(hover_tex, hover_margin, hover_content_y))
	btn.add_theme_stylebox_override("pressed", _texture_style(pressed_tex, tex_margin, content_y))
	btn.add_theme_stylebox_override("focus", _texture_style(hover_tex, hover_margin, hover_content_y))
	btn.add_theme_stylebox_override("disabled", _texture_style(pressed_tex, tex_margin, content_y))
	btn.add_theme_color_override("font_color", JADE_DARK if primary else TEXT_MAIN)
	btn.add_theme_color_override("font_hover_color", Color(0.05, 0.14, 0.15, 1.0) if gold_target_state else GOLD_LIGHT)
	btn.add_theme_color_override("font_pressed_color", Color(0.98, 0.93, 0.72, 1.0) if primary else TEXT_MUTED)
	btn.add_theme_color_override("font_focus_color", Color(0.05, 0.14, 0.15, 1.0) if gold_target_state else GOLD_LIGHT)


static func apply_character_select_button(btn: Button, primary: bool = false, font_size: int = 16) -> void:
	var normal_bg := Color(0.025, 0.125, 0.135, 0.88)
	var hover_bg := Color(0.042, 0.180, 0.188, 0.96)
	var pressed_bg := Color(0.058, 0.205, 0.205, 0.98)
	var border := Color(0.82, 0.68, 0.38, 0.78)
	var hover_border := Color(1.0, 0.93, 0.62, 1.0)
	var font_color := TEXT_MAIN
	var hover_font := GOLD_LIGHT
	var pressed_font := GOLD_LIGHT
	if primary:
		normal_bg = Color(0.88, 0.72, 0.38, 0.96)
		hover_bg = Color(0.98, 0.82, 0.46, 0.98)
		pressed_bg = Color(0.68, 0.50, 0.22, 0.98)
		border = Color(1.0, 0.92, 0.60, 0.95)
		font_color = JADE_DARK
		hover_font = JADE_DARK
		pressed_font = Color(0.04, 0.12, 0.12, 1.0)
	var normal := _button_flat_rect(normal_bg, border, 1)
	var hover := _button_flat_rect(hover_bg, hover_border, 2)
	var pressed := _button_flat_rect(pressed_bg, hover_border, 2)
	var focus := _button_flat_rect(Color(0.0, 0.0, 0.0, 0.0), hover_border, 2)
	btn.add_theme_font_override("font", FONT_BODY)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_stylebox_override("disabled", _button_flat_rect(Color(0.04, 0.055, 0.058, 0.56), Color(0.34, 0.32, 0.25, 0.62), 1))
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", hover_font)
	btn.add_theme_color_override("font_pressed_color", pressed_font)
	btn.add_theme_color_override("font_focus_color", font_color)


static func apply_main_menu_button(btn: Button, font_size: int = 18) -> void:
	var normal := _button_bar(
		Color(0.020, 0.145, 0.150, 0.78),
		Color(0.82, 0.70, 0.42, 0.56),
		1
	)
	var hover := _button_bar(
		Color(1.0, 0.82, 0.36, 0.94),
		Color(1.0, 0.94, 0.62, 1.0),
		2
	)
	var pressed := _button_bar(
		Color(0.68, 0.46, 0.16, 0.96),
		Color(0.98, 0.84, 0.42, 1.0),
		2
	)
	var disabled := _button_bar(
		Color(0.035, 0.055, 0.058, 0.56),
		Color(0.35, 0.32, 0.25, 0.48),
		1
	)
	var focus := _button_focus_ring()
	btn.add_theme_font_override("font", FONT_BODY)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", TEXT_MAIN)
	btn.add_theme_color_override("font_hover_color", JADE_DARK)
	btn.add_theme_color_override("font_pressed_color", Color(0.98, 0.92, 0.72, 1.0))
	btn.add_theme_color_override("font_focus_color", TEXT_MAIN)


static func apply_option_button(btn: OptionButton) -> void:
	apply_button(btn, "secondary", 15)


static func apply_options_panel(panel: PanelContainer) -> void:
	var style := _flat(Color(0.018, 0.075, 0.082, 0.94), Color(0.86, 0.69, 0.36, 0.86), 2, 8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.56)
	style.shadow_size = 18
	style.corner_detail = 8
	panel.add_theme_stylebox_override("panel", style)


static func apply_options_section_label(label: Label) -> void:
	apply_body(label, 15, GOLD_LIGHT)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.035, 0.035, 0.78))
	label.add_theme_constant_override("shadow_outline_size", 1)


static func apply_options_row_label(label: Label) -> void:
	apply_body(label, 15, Color(0.96, 0.94, 0.84, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.025, 0.030, 0.70))
	label.add_theme_constant_override("shadow_outline_size", 1)


static func apply_options_value_label(label: Label) -> void:
	apply_body(label, 15, Color(1.0, 0.94, 0.70, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.025, 0.030, 0.78))
	label.add_theme_constant_override("shadow_outline_size", 1)


static func apply_options_option_button(btn: OptionButton) -> void:
	_apply_options_button_base(btn, false, 15)


static func apply_options_action_button(btn: Button, primary: bool = false) -> void:
	_apply_options_button_base(btn, primary, 17)


static func apply_options_slider(slider: HSlider) -> void:
	var track := _flat(Color(0.010, 0.050, 0.056, 0.95), Color(0.74, 0.60, 0.34, 0.78), 1, 4)
	track.content_margin_top = 7
	track.content_margin_bottom = 7
	var grabber_area := _flat(Color(0.90, 0.72, 0.34, 0.96), Color(0, 0, 0, 0), 0, 4)
	grabber_area.content_margin_top = 7
	grabber_area.content_margin_bottom = 7
	slider.custom_minimum_size.y = 36
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", grabber_area)
	slider.add_theme_icon_override("grabber", _stamp_texture(Vector2i(22, 22), Color(1.0, 0.86, 0.42, 1.0), Color(1.0, 0.95, 0.68, 1.0)))
	slider.add_theme_icon_override("grabber_highlight", _stamp_texture(Vector2i(24, 24), Color(1.0, 0.91, 0.54, 1.0), Color(1.0, 0.98, 0.78, 1.0)))


static func apply_check_button(btn: CheckButton) -> void:
	btn.add_theme_font_override("font", FONT_BODY)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", TEXT_SOFT)
	btn.add_theme_color_override("font_hover_color", TEXT_MAIN)


static func apply_slider(slider: HSlider) -> void:
	var grabber := _flat(GOLD_LIGHT, Color(1.0, 0.96, 0.72, 1.0), 1, 5)
	var grabber_area := _flat(Color(0.90, 0.74, 0.34, 0.82), Color(0, 0, 0, 0), 0, 3)
	var track := _flat(Color(0.032, 0.090, 0.098, 0.82), Color(0.70, 0.57, 0.31, 0.68), 1, 3)
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", grabber_area)
	slider.add_theme_icon_override("grabber", _box_texture(grabber, Vector2i(18, 18)))
	slider.add_theme_icon_override("grabber_highlight", _box_texture(grabber, Vector2i(20, 20)))


static func _texture_style(texture: Texture2D, texture_margin: int, content_margin: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = texture_margin
	style.texture_margin_top = texture_margin
	style.texture_margin_right = texture_margin
	style.texture_margin_bottom = texture_margin
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style


static func _apply_options_button_base(btn: Button, primary: bool, font_size: int) -> void:
	var normal_bg := Color(0.055, 0.155, 0.160, 0.96)
	var hover_bg := Color(0.080, 0.225, 0.220, 0.98)
	var pressed_bg := Color(0.030, 0.095, 0.105, 0.98)
	var normal_border := Color(0.78, 0.62, 0.34, 0.84)
	var hover_border := GOLD_LIGHT
	var font_color := TEXT_MAIN
	var hover_font := GOLD_LIGHT
	if primary:
		normal_bg = Color(0.88, 0.70, 0.34, 0.96)
		hover_bg = Color(1.0, 0.82, 0.42, 0.98)
		pressed_bg = Color(0.70, 0.52, 0.24, 0.98)
		normal_border = Color(1.0, 0.91, 0.58, 0.92)
		hover_border = Color(1.0, 0.97, 0.76, 1.0)
		font_color = JADE_DARK
		hover_font = Color(0.035, 0.11, 0.12, 1.0)
	btn.add_theme_font_override("font", FONT_BODY)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_stylebox_override("normal", _button_flat(normal_bg, normal_border))
	btn.add_theme_stylebox_override("hover", _button_flat(hover_bg, hover_border))
	btn.add_theme_stylebox_override("pressed", _button_flat(pressed_bg, normal_border))
	btn.add_theme_stylebox_override("focus", _button_flat(hover_bg, hover_border))
	btn.add_theme_stylebox_override("disabled", _button_flat(Color(0.04, 0.06, 0.065, 0.62), Color(0.30, 0.28, 0.22, 0.70)))
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", hover_font)
	btn.add_theme_color_override("font_pressed_color", Color(0.98, 0.93, 0.72, 1.0) if not primary else Color(0.04, 0.10, 0.10, 1.0))
	btn.add_theme_color_override("font_focus_color", hover_font)


static func _button_flat(bg: Color, border: Color) -> StyleBoxFlat:
	var style := _flat(bg, border, 2, 5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	style.shadow_size = 5
	return style


static func _button_flat_rect(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := _flat(bg, border, border_width, 4)
	style.content_margin_left = 18
	style.content_margin_top = 9
	style.content_margin_right = 18
	style.content_margin_bottom = 9
	style.shadow_color = Color(0.0, 0.018, 0.020, 0.32)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 1)
	return style


static func _flat(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style


static func _button_bar(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := _flat(bg, border, border_width, 4)
	style.content_margin_left = 20
	style.content_margin_top = 11
	style.content_margin_right = 20
	style.content_margin_bottom = 11
	style.shadow_color = Color(0.0, 0.012, 0.015, 0.34)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 2)
	return style


static func _button_focus_ring() -> StyleBoxFlat:
	var style := _flat(Color(0, 0, 0, 0), Color(1.0, 0.91, 0.58, 0.96), 2, 4)
	style.draw_center = false
	style.content_margin_left = 20
	style.content_margin_top = 11
	style.content_margin_right = 20
	style.content_margin_bottom = 11
	return style


static func _box_texture(style: StyleBoxFlat, size: Vector2i) -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(style.bg_color)
	return ImageTexture.create_from_image(image)


static func _stamp_texture(size: Vector2i, fill: Color, border: Color) -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2((size.x - 1) * 0.5, (size.y - 1) * 0.5)
	var radius := Vector2(maxf(1.0, center.x), maxf(1.0, center.y))
	for x in range(size.x):
		for y in range(size.y):
			var dist := absf(float(x) - center.x) / radius.x + absf(float(y) - center.y) / radius.y
			if dist <= 1.0:
				image.set_pixel(x, y, border if dist > 0.74 else fill)
	return ImageTexture.create_from_image(image)
