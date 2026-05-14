## Programmatic battle status icon for player/enemy card status bars.
extends Control

const ICON_SIZE := Vector2(32, 32)

var data: Dictionary = {}
var _hovered := false


func _ready() -> void:
	custom_minimum_size = ICON_SIZE
	size = ICON_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void:
		_hovered = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hovered = false
		queue_redraw()
	)


func _get_minimum_size() -> Vector2:
	return ICON_SIZE


func setup(entry: Dictionary) -> void:
	data = entry.duplicate(true)
	tooltip_text = str(data.get("tooltip", ""))
	custom_minimum_size = ICON_SIZE
	size = ICON_SIZE
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		r = Rect2(Vector2.ZERO, ICON_SIZE)

	var kind := str(data.get("kind", "neutral"))
	var border := _kind_color(kind)
	var bg := Color(0.035, 0.038, 0.045, 0.94)
	if _hovered:
		bg = Color(0.085, 0.090, 0.105, 0.98)
	draw_rect(r, bg, true)
	draw_rect(r.grow(-1.0), border, false, 1.6)
	if _hovered:
		draw_rect(r.grow(-3.0), Color(1.0, 0.96, 0.70, 0.22), false, 1.5)

	var inset := Rect2(r.position + Vector2(5, 4), r.size - Vector2(10, 10))
	_draw_symbol(str(data.get("id", "")), inset)
	_draw_value_badge(r, int(data.get("value", 0)))


func _kind_color(kind: String) -> Color:
	match kind:
		"core":
			return Color(0.92, 0.72, 0.24, 1.0)
		"positive":
			return Color(0.28, 0.78, 0.42, 1.0)
		"negative":
			return Color(0.90, 0.24, 0.20, 1.0)
		"temporary":
			return Color(0.42, 0.72, 0.95, 1.0)
		_:
			return Color(0.58, 0.62, 0.68, 1.0)


func _draw_value_badge(r: Rect2, value: int) -> void:
	var text := str(value)
	var font := get_theme_default_font()
	var font_size := 11
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var w := maxf(13.0, text_size.x + 5.0)
	var badge := Rect2(r.position + Vector2(r.size.x - w - 1.0, r.size.y - 14.0), Vector2(w, 13.0))
	draw_rect(badge, Color(0.0, 0.0, 0.0, 0.76), true)
	draw_rect(badge, Color(1.0, 0.92, 0.62, 0.45), false, 1.0)
	draw_string(font, badge.position + Vector2((w - text_size.x) * 0.5, 10.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


func _draw_symbol(id: String, r: Rect2) -> void:
	match id:
		"base_ling_li_regen":
			_draw_drop(r, Color(0.12, 0.82, 0.92), false)
		"bonus_ling_li_regen":
			_draw_drop(r, Color(0.36, 0.95, 1.0), true)
		"dao_xing", "enemy_dao_xing":
			_draw_dao_mark(r)
		"xin_liu":
			_draw_heart_swirl(r)
		"bu_qin":
			_draw_shield(r, Color(0.25, 0.62, 0.95))
		"jing_ci":
			_draw_thorns(r)
		"lie_shang":
			_draw_crack(r)
		"ku_jie":
			_draw_wither(r)
		"xu_ruo":
			_draw_down_arrow(r)
		"zhen_she":
			_draw_stun(r)
		"next_attack_bonus":
			_draw_sword(r, Color(0.95, 0.25, 0.18))
		"next_turn_dao_xing":
			_draw_clock_dao(r)
		"extra_draw_next_turn":
			_draw_cards(r)
		"death_save_charges":
			_draw_heart_guard(r)
		"debuff_ward_charges":
			_draw_ward(r)
		"enemy_action_delay":
			_draw_delay(r)
		"overflow":
			_draw_plus(r)
		_:
			_draw_plus(r)


func _draw_filled_polygon(points: PackedVector2Array, color: Color) -> void:
	var colors := PackedColorArray()
	for _i in range(points.size()):
		colors.append(color)
	draw_polygon(points, colors)


func _draw_drop(r: Rect2, color: Color, plus: bool) -> void:
	var c := r.get_center()
	_draw_filled_polygon(PackedVector2Array([
		c + Vector2(0, -10),
		c + Vector2(8, -1),
		c + Vector2(5, 9),
		c + Vector2(0, 12),
		c + Vector2(-5, 9),
		c + Vector2(-8, -1),
	]), color)
	draw_circle(c + Vector2(-3, -3), 3.0, Color(0.85, 1.0, 1.0, 0.75))
	if plus:
		draw_line(c + Vector2(-5, 3), c + Vector2(5, 3), Color.WHITE, 2.0)
		draw_line(c + Vector2(0, -2), c + Vector2(0, 8), Color.WHITE, 2.0)


func _draw_dao_mark(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c, 10.0, Color(0.80, 0.58, 0.16))
	draw_arc(c, 12.0, -PI * 0.15, PI * 1.15, 36, Color(1.0, 0.88, 0.34), 2.0, true)
	draw_line(c + Vector2(-1, -9), c + Vector2(-1, 8), Color(1.0, 0.96, 0.78), 2.0)
	draw_line(c + Vector2(-6, -1), c + Vector2(6, -1), Color(1.0, 0.96, 0.78), 1.6)
	draw_line(c + Vector2(-5, 8), c + Vector2(5, 8), Color(0.32, 0.16, 0.04), 2.0)


func _draw_heart_swirl(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c + Vector2(-4, -3), 4.5, Color(0.24, 0.82, 0.48))
	draw_circle(c + Vector2(3, -3), 4.5, Color(0.24, 0.82, 0.48))
	_draw_filled_polygon(PackedVector2Array([c + Vector2(-9, -1), c + Vector2(8, -1), c + Vector2(0, 10)]), Color(0.24, 0.82, 0.48))
	draw_arc(c, 8.0, -PI * 0.25, PI * 1.05, 28, Color(0.82, 1.0, 0.78), 1.6, true)


func _draw_shield(r: Rect2, color: Color) -> void:
	var c := r.get_center()
	_draw_filled_polygon(PackedVector2Array([
		c + Vector2(0, -11),
		c + Vector2(9, -6),
		c + Vector2(7, 6),
		c + Vector2(0, 12),
		c + Vector2(-7, 6),
		c + Vector2(-9, -6),
	]), color)
	draw_line(c + Vector2(0, -8), c + Vector2(0, 8), Color(0.86, 0.96, 1.0), 1.8)


func _draw_thorns(r: Rect2) -> void:
	var c := r.get_center()
	for angle in [0.0, PI * 0.4, PI * 0.8, PI * 1.2, PI * 1.6]:
		var tip := c + Vector2(cos(angle), sin(angle)) * 12.0
		var base := c + Vector2(cos(angle), sin(angle)) * 4.0
		draw_line(base, tip, Color(0.86, 0.62, 0.22), 2.0)
	draw_circle(c, 5.0, Color(0.36, 0.72, 0.34))


func _draw_crack(r: Rect2) -> void:
	var p := r.position
	draw_circle(r.get_center(), 10.0, Color(0.72, 0.08, 0.08))
	draw_line(p + Vector2(13, 1), p + Vector2(9, 9), Color(1.0, 0.72, 0.62), 2.0)
	draw_line(p + Vector2(9, 9), p + Vector2(15, 13), Color(1.0, 0.72, 0.62), 2.0)
	draw_line(p + Vector2(15, 13), p + Vector2(10, 22), Color(1.0, 0.72, 0.62), 2.0)


func _draw_wither(r: Rect2) -> void:
	var c := r.get_center()
	draw_arc(c, 10.0, PI * 0.1, PI * 1.65, 36, Color(0.60, 0.34, 0.86), 3.0, true)
	draw_line(c + Vector2(-8, 8), c + Vector2(8, -8), Color(0.18, 0.10, 0.25), 3.0)
	draw_line(c + Vector2(-6, -4), c + Vector2(2, 3), Color(0.86, 0.72, 1.0), 1.5)


func _draw_down_arrow(r: Rect2) -> void:
	var c := r.get_center()
	draw_line(c + Vector2(0, -10), c + Vector2(0, 6), Color(0.70, 0.76, 0.82), 4.0)
	_draw_filled_polygon(PackedVector2Array([c + Vector2(-7, 4), c + Vector2(7, 4), c + Vector2(0, 12)]), Color(0.70, 0.76, 0.82))


func _draw_stun(r: Rect2) -> void:
	var c := r.get_center()
	for offset in [-7.0, 0.0, 7.0]:
		draw_line(c + Vector2(offset - 2, -10), c + Vector2(offset + 3, -2), Color(1.0, 0.86, 0.18), 2.0)
		draw_line(c + Vector2(offset + 3, -2), c + Vector2(offset - 2, 6), Color(1.0, 0.86, 0.18), 2.0)
	draw_circle(c + Vector2(0, 8), 3.0, Color(1.0, 0.66, 0.12))


func _draw_sword(r: Rect2, color: Color) -> void:
	var p := r.position
	draw_line(p + Vector2(6, 21), p + Vector2(21, 4), Color(0.92, 0.92, 0.86), 3.0)
	draw_line(p + Vector2(8, 23), p + Vector2(22, 9), color, 1.6)
	draw_line(p + Vector2(5, 17), p + Vector2(12, 24), Color(0.86, 0.62, 0.22), 2.0)


func _draw_clock_dao(r: Rect2) -> void:
	var c := r.get_center()
	draw_arc(c, 10.0, 0.0, TAU, 40, Color(0.95, 0.72, 0.22), 2.2, true)
	draw_line(c, c + Vector2(0, -7), Color(1.0, 0.95, 0.72), 1.8)
	draw_line(c, c + Vector2(6, 3), Color(1.0, 0.95, 0.72), 1.8)
	draw_line(c + Vector2(-5, 9), c + Vector2(5, 9), Color(0.95, 0.72, 0.22), 1.6)


func _draw_cards(r: Rect2) -> void:
	var p := r.position
	draw_rect(Rect2(p + Vector2(7, 5), Vector2(12, 16)), Color(0.26, 0.40, 0.70), true)
	draw_rect(Rect2(p + Vector2(10, 8), Vector2(12, 16)), Color(0.48, 0.72, 0.95), true)
	draw_line(p + Vector2(12, 12), p + Vector2(19, 12), Color.WHITE, 1.4)
	draw_line(p + Vector2(12, 16), p + Vector2(18, 16), Color.WHITE, 1.2)


func _draw_heart_guard(r: Rect2) -> void:
	_draw_shield(r, Color(0.84, 0.82, 0.68))
	var c := r.get_center() + Vector2(0, 1)
	draw_circle(c + Vector2(-3, -2), 2.8, Color(0.92, 0.18, 0.18))
	draw_circle(c + Vector2(3, -2), 2.8, Color(0.92, 0.18, 0.18))
	_draw_filled_polygon(PackedVector2Array([c + Vector2(-6, 0), c + Vector2(6, 0), c + Vector2(0, 7)]), Color(0.92, 0.18, 0.18))


func _draw_ward(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c, 11.0, Color(0.22, 0.44, 0.90))
	draw_circle(c, 7.0, Color(0.04, 0.07, 0.12))
	draw_arc(c, 8.5, -PI * 0.25, PI * 1.25, 32, Color(0.74, 0.95, 1.0), 2.0, true)


func _draw_delay(r: Rect2) -> void:
	var c := r.get_center()
	draw_line(c + Vector2(-6, -10), c + Vector2(6, -10), Color(0.78, 0.78, 0.82), 2.0)
	draw_line(c + Vector2(-6, 10), c + Vector2(6, 10), Color(0.78, 0.78, 0.82), 2.0)
	draw_line(c + Vector2(-5, -8), c + Vector2(5, 8), Color(0.78, 0.78, 0.82), 2.0)
	draw_line(c + Vector2(5, -8), c + Vector2(-5, 8), Color(0.78, 0.78, 0.82), 2.0)
	draw_line(c + Vector2(-11, 0), c + Vector2(-7, 0), Color(0.50, 0.70, 0.95), 2.0)
	draw_line(c + Vector2(7, 0), c + Vector2(11, 0), Color(0.50, 0.70, 0.95), 2.0)


func _draw_plus(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c, 10.0, Color(0.42, 0.46, 0.52))
	draw_line(c + Vector2(-6, 0), c + Vector2(6, 0), Color.WHITE, 2.2)
	draw_line(c + Vector2(0, -6), c + Vector2(0, 6), Color.WHITE, 2.2)
