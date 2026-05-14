extends RefCounted

const MenuUiStyle = preload("res://scripts/ui/MenuUiStyle.gd")

const CHOICE_META_SELECTED := "safe_node_selected"
const CHOICE_META_HOVERED := "safe_node_hovered"
const CHOICE_META_DISABLED := "safe_node_disabled"
const CHOICE_META_TWEEN := "safe_node_choice_tween"
const CHOICE_HOVER_SCALE := Vector2(1.02, 1.02)
const CHOICE_NORMAL_SCALE := Vector2.ONE
const CHOICE_ANIM_SECS := 0.12


static func apply_modal_panel(panel: PanelContainer, variant: String = "default") -> void:
	var panel_variant := "dark"
	match variant:
		"map", "bonfire":
			panel_variant = "altar"
		"event":
			panel_variant = "scroll"
		_:
			panel_variant = "dark"
	MenuUiStyle.apply_panel(panel, panel_variant)


static func apply_result_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _flat(Color(0.10, 0.085, 0.045, 0.74), Color(0.86, 0.66, 0.34, 0.58), 1, 6))


static func apply_choice_card(panel: PanelContainer, selected: bool = false, disabled: bool = false) -> void:
	apply_choice_state(panel, selected, false, disabled, false)


static func apply_choice_state(control: Control, selected: bool = false, hovered: bool = false, disabled: bool = false, animate: bool = true) -> void:
	if control == null:
		return
	hovered = hovered and not disabled
	control.set_meta(CHOICE_META_SELECTED, selected)
	control.set_meta(CHOICE_META_HOVERED, hovered)
	control.set_meta(CHOICE_META_DISABLED, disabled)

	var bg := Color(0.055, 0.070, 0.078, 0.76)
	var border := Color(0.62, 0.50, 0.30, 0.58)
	var width := 1
	var target_modulate := Color(1, 1, 1, 1)
	var target_scale := CHOICE_NORMAL_SCALE

	if disabled:
		bg = Color(0.045, 0.045, 0.050, 0.52)
		border = Color(0.34, 0.32, 0.27, 0.50)
		target_modulate = Color(0.72, 0.72, 0.72, 0.58)
	elif selected and hovered:
		bg = Color(0.22, 0.170, 0.060, 0.96)
		border = Color(1.0, 0.95, 0.68, 1.0)
		width = 2
		target_modulate = Color(1.0, 0.98, 0.88, 1.0)
		target_scale = CHOICE_HOVER_SCALE
	elif selected:
		bg = Color(0.18, 0.135, 0.045, 0.92)
		border = Color(1.0, 0.91, 0.58, 1.0)
		width = 2
		target_modulate = Color(1.0, 0.96, 0.82, 1.0)
	elif hovered:
		bg = Color(0.085, 0.105, 0.100, 0.88)
		border = Color(0.95, 0.78, 0.38, 0.96)
		width = 2
		target_modulate = Color(1.0, 0.98, 0.88, 1.0)
		target_scale = CHOICE_HOVER_SCALE

	if control is PanelContainer:
		var style := _flat(bg, border, width, 7)
		style.content_margin_left = 0
		style.content_margin_top = 0
		style.content_margin_right = 0
		style.content_margin_bottom = 0
		(control as PanelContainer).add_theme_stylebox_override("panel", style)

	control.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	control.z_index = 30 if hovered else (20 if selected else 0)
	_apply_choice_transform(control, target_scale, target_modulate, animate)


static func animate_choice_hover(control: Control, hovered: bool, disabled: bool = false) -> void:
	apply_choice_state(control, false, hovered, disabled, true)


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


static func _apply_choice_transform(control: Control, target_scale: Vector2, target_modulate: Color, animate: bool) -> void:
	if control.size != Vector2.ZERO:
		control.pivot_offset = control.size * 0.5
	elif control.custom_minimum_size != Vector2.ZERO:
		control.pivot_offset = control.custom_minimum_size * 0.5

	if control.has_meta(CHOICE_META_TWEEN):
		var old_tween = control.get_meta(CHOICE_META_TWEEN)
		if old_tween is Tween and is_instance_valid(old_tween):
			(old_tween as Tween).kill()

	if animate and control.is_inside_tree():
		var tween := control.create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(control, "scale", target_scale, CHOICE_ANIM_SECS)
		tween.tween_property(control, "modulate", target_modulate, CHOICE_ANIM_SECS)
		control.set_meta(CHOICE_META_TWEEN, tween)
	else:
		control.scale = target_scale
		control.modulate = target_modulate
