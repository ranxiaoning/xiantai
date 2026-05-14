extends Control

const COUNT = 34
var _p: Array = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	randomize()
	var s := get_viewport_rect().size
	for i in COUNT:
		_p.append({
			"pos":   Vector2(randf() * s.x, randf() * s.y),
			"vel":   Vector2(randf_range(-4.0, 4.0), randf_range(-13.0, -4.0)),
			"size":  randf_range(1.2, 2.6),
			"phase": randf() * TAU,
			"spd":   randf_range(0.8, 1.5),
			"gold":  randf() > 0.4,
		})
	set_process(true)

func _process(delta: float) -> void:
	var s := get_viewport_rect().size
	for pt in _p:
		pt["phase"] += delta * pt["spd"]
		pt["pos"] += (pt["vel"] as Vector2) * delta
		pt["pos"].x += sin(pt["phase"] * 0.7) * 6.0 * delta
		if pt["pos"].y < -10.0:
			pt["pos"] = Vector2(randf() * s.x, s.y + 5.0)
	queue_redraw()

func _draw() -> void:
	for pt in _p:
		var a: float = sin(pt["phase"]) * 0.5 + 0.5
		var r: float = pt["size"]
		var c: Color
		if pt["gold"]:
			c = Color(1.0, 0.82, 0.35, a * 0.58)
		else:
			c = Color(0.78, 0.90, 1.0, a * 0.42)
		var glow := c; glow.a *= 0.22
		draw_circle(pt["pos"], r * 3.8, glow)
		var mid := c; mid.a *= 0.50
		draw_circle(pt["pos"], r * 1.9, mid)
		draw_circle(pt["pos"], r, c)
