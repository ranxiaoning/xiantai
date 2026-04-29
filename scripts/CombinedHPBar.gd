class_name CombinedHPBar
extends Control

const _HP_COLOR     := Color(0.82, 0.10, 0.10, 1.0)
const _EMPTY_COLOR  := Color(0.09, 0.09, 0.09, 1.0)
const _SHIELD_COLOR := Color(0.92, 0.92, 0.92, 1.0)

var _hp:     int = 0
var _hp_max: int = 1
var _shield: int = 0
var _label:  Label


func _ready() -> void:
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func set_values(hp: int, hp_max: int, shield: int) -> void:
	_hp     = max(hp, 0)
	_hp_max = max(hp_max, 1)
	_shield = max(shield, 0)
	if _label:
		var txt := "HP %d / %d" % [_hp, _hp_max]
		if _shield > 0:
			txt += "  护体 %d" % _shield
		_label.text = txt
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	var total  := float(_hp_max + _shield)
	var hp_w   := w * float(_hp_max) / total
	var fill_w := hp_w * float(_hp) / float(_hp_max)

	# depleted HP background
	draw_rect(Rect2(0.0, 0.0, hp_w, h), _EMPTY_COLOR)
	# current HP (red)
	if fill_w > 0.0:
		draw_rect(Rect2(0.0, 0.0, fill_w, h), _HP_COLOR)
	# shield extension (white), appears beyond the HP section
	if _shield > 0:
		draw_rect(Rect2(hp_w, 0.0, w - hp_w, h), _SHIELD_COLOR)
	# thin border
	draw_rect(Rect2(0.0, 0.0, w, h), Color(0.0, 0.0, 0.0, 0.5), false, 1.0)
