extends Control

@export var title: String = ""
@export var current_value: int = 0
@export var max_value: int = 1
@export var fill_color: Color = Color(0.0, 0.8, 0.9)
@export var ring_color: Color = Color(0.45, 0.95, 1.0)
@export var back_color: Color = Color(0.02, 0.04, 0.06, 0.86)

var _display_pct: float = 0.0
var _target_pct: float = 0.0
var _wave_phase: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(82, 82)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_wave_phase += delta * 3.8
	var before := _display_pct
	_display_pct = move_toward(_display_pct, _target_pct, delta * 2.8)
	if _display_pct > 0.0 or absf(before - _display_pct) > 0.001:
		queue_redraw()


func set_values(value: int, max_v: int, label: String = "") -> void:
	current_value = value
	max_value = maxi(max_v, 1)
	_target_pct = clampf(float(current_value) / float(max_value), 0.0, 1.0)
	if not label.is_empty():
		title = label
	queue_redraw()


func _draw() -> void:
	var radius: float = minf(size.x, size.y) * 0.42
	var center := size * 0.5

	# 投影
	draw_circle(center + Vector2(2, 3), radius + 4.0, Color(0.0, 0.0, 0.0, 0.38))
	# 背景球体
	draw_circle(center, radius + 2.0, back_color)

	# 水体填充
	_draw_water_fill(center, radius - 1.0, _display_pct)

	# 球体立体感叠层（画在水面之上，模拟玻璃球）
	_draw_sphere_shading(center, radius - 1.0)

	# 边缘细线
	draw_arc(center, radius + 2.0, 0.0, TAU, 80, ring_color.darkened(0.4), 1.2, true)

	# 数字
	var value_text := "%d" % current_value
	var slash_text := "/%d" % max_value
	var font := get_theme_default_font()
	var value_size := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	var slash_size := font.get_string_size(slash_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	var total_w := value_size.x + slash_size.x + 1.0
	var base := center + Vector2(-total_w * 0.5, -4.0)
	draw_string(font, base, value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	draw_string(font, base + Vector2(value_size.x + 1.0, 0), slash_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ring_color.lightened(0.3))

	var title_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
	draw_string(font, center + Vector2(-title_size.x * 0.5, 21.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ring_color)


func _draw_sphere_shading(center: Vector2, radius: float) -> void:
	# 底部暗角（让下半部分更深，增加深度感）
	var shadow_steps := 6
	for i in range(shadow_steps):
		var t := float(i) / float(shadow_steps)
		var r := radius * lerpf(1.0, 0.3, t)
		var offset := Vector2(0, radius * 0.35 * (1.0 - t))
		var a := 0.12 * (1.0 - t)
		draw_circle(center + offset, r, Color(0.0, 0.0, 0.0, a))

	# 左上高光主体（模拟光源在左上方的球面反光）
	var spec_center := center + Vector2(-radius * 0.26, -radius * 0.26)
	var spec_steps := 5
	for i in range(spec_steps):
		var t := float(i) / float(spec_steps)
		var r := radius * lerpf(0.30, 0.02, t * t)
		var a := lerpf(0.55, 0.0, t * t)
		draw_circle(spec_center, r, Color(1.0, 1.0, 1.0, a))

	# 右下边缘反光（rim light）
	var rim := ring_color.lightened(0.25)
	rim.a = 0.40
	draw_arc(center, radius - 1.5, PI * 0.25, PI * 0.82, 40, rim, 3.0, true)

	# 顶部薄薄的亮边（增加玻璃感）
	var top_rim := Color.WHITE
	top_rim.a = 0.18
	draw_arc(center, radius - 0.5, PI * 1.1, PI * 1.9, 40, top_rim, 1.5, true)


func _draw_water_fill(center: Vector2, radius: float, pct: float) -> void:
	if pct <= 0.001:
		return

	var surface_y := center.y + radius - radius * 2.0 * pct
	surface_y = clampf(surface_y, center.y - radius + 1.0, center.y + radius - 1.0)
	var top_points := PackedVector2Array()
	var wave_steps := 40
	var wave_amp := minf(2.2, radius * 0.07) * lerpf(0.6, 1.0, pct)

	for i in range(wave_steps + 1):
		var t := float(i) / float(wave_steps)
		var dy := surface_y - center.y
		var half_width := sqrt(maxf(radius * radius - dy * dy, 0.0))
		var x := -half_width + half_width * 2.0 * t
		var wave := sin(t * TAU * 1.6 + _wave_phase) * wave_amp
		wave += sin(t * TAU * 0.8 + _wave_phase * 1.4 + 1.0) * wave_amp * 0.45
		var y := surface_y + wave
		var circle_half_height := sqrt(maxf(radius * radius - x * x, 0.0))
		y = clampf(y, center.y - circle_half_height + 1.0, center.y + circle_half_height - 1.0)
		var point := center + Vector2(x, y - center.y)
		top_points.append(point)

	var water := fill_color.darkened(0.05)
	water.a = 1.0
	var bottom := center.y + radius
	var top := maxf(center.y - radius, surface_y - wave_amp * 1.6)
	for yi in range(int(floor(top)), int(ceil(bottom)) + 1):
		var y := float(yi)
		var y_delta := y - center.y
		var half_width := sqrt(maxf(radius * radius - y_delta * y_delta, 0.0))
		if half_width <= 0.0:
			continue
		var left := center.x - half_width
		var right := center.x + half_width
		var t_left := 0.0
		var t_right := 1.0
		var wave_left := surface_y + sin(t_left * TAU * 1.6 + _wave_phase) * wave_amp
		wave_left += sin(t_left * TAU * 0.8 + _wave_phase * 1.4 + 1.0) * wave_amp * 0.45
		var wave_right := surface_y + sin(t_right * TAU * 1.6 + _wave_phase) * wave_amp
		wave_right += sin(t_right * TAU * 0.8 + _wave_phase * 1.4 + 1.0) * wave_amp * 0.45
		if y >= minf(wave_left, wave_right):
			draw_line(Vector2(left, y), Vector2(right, y), water, 1.2, false)

	var wave_highlight := fill_color.lightened(0.45)
	wave_highlight.a = 1.0
	draw_polyline(top_points, wave_highlight, 2.0, true)

	var wave_glow := fill_color.lightened(0.22)
	wave_glow.a = 0.55
	var glow_points := PackedVector2Array()
	for p in top_points:
		glow_points.append(p + Vector2(0, 2.5))
	draw_polyline(glow_points, wave_glow, 1.5, true)
