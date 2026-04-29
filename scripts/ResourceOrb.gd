extends Control

@export var title: String = ""
@export var current_value: int = 0
@export var max_value: int = 1
@export var fill_color: Color = Color(0.0, 0.8, 0.9)
@export var ring_color: Color = Color(0.45, 0.95, 1.0)
@export var back_color: Color = Color(0.02, 0.04, 0.06, 0.86)


func _ready() -> void:
	custom_minimum_size = Vector2(82, 82)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_values(value: int, max_v: int, label: String = "") -> void:
	current_value = value
	max_value = maxi(max_v, 1)
	if not label.is_empty():
		title = label
	queue_redraw()


func _draw() -> void:
	var radius: float = minf(size.x, size.y) * 0.42
	var center := size * 0.5
	var pct: float = clampf(float(current_value) / float(max_value), 0.0, 1.0)

	draw_circle(center, radius + 7.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(center, radius + 3.0, back_color)
	draw_arc(center, radius + 4.0, 0.0, TAU, 80, Color(1, 1, 1, 0.14), 2.0, true)
	draw_arc(center, radius + 1.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 80, ring_color, 5.0, true)

	for i in range(24):
		var a := TAU * float(i) / 24.0
		var inner := center + Vector2(cos(a), sin(a)) * (radius + 9.0)
		var outer := center + Vector2(cos(a), sin(a)) * (radius + 13.0)
		var c := ring_color
		c.a = 0.18 if i % 3 != 0 else 0.45
		draw_line(inner, outer, c, 1.0)

	var fill := fill_color
	fill.a = 0.18 + pct * 0.22
	draw_circle(center, radius - 5.0, fill)

	var value_text := "%d" % current_value
	var slash_text := "/%d" % max_value
	var font := get_theme_default_font()
	var value_size := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 23)
	var slash_size := font.get_string_size(slash_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	var total_w := value_size.x + slash_size.x + 1.0
	var base := center + Vector2(-total_w * 0.5, -5.0)
	draw_string(font, base, value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
	draw_string(font, base + Vector2(value_size.x + 1.0, 0), slash_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.9, 0.95))

	var title_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	draw_string(font, center + Vector2(-title_size.x * 0.5, 22.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ring_color)
