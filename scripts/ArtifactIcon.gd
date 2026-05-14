## ArtifactIcon.gd
## 程序化宝物图标：用于地图/战斗 HUD 的 36x36 可点击宝物格。
extends Control

signal activated(artifact: Dictionary, source: Control)

const ICON_SIZE := Vector2(36, 36)

var artifact: Dictionary = {}
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


func setup(data: Dictionary) -> void:
	artifact = data.duplicate(true)
	tooltip_text = build_tooltip(artifact)
	queue_redraw()


func play_acquire_flash() -> void:
	pivot_offset = size * 0.5
	scale = Vector2(1.16, 1.16)
	modulate = Color(1.45, 1.35, 1.0, 1.0)
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate", Color.WHITE, 0.55)


static func rarity_label(rarity: String) -> String:
	match rarity:
		"yellow": return "黄品"
		"mystique": return "玄品"
		"earth": return "地品"
		"heaven": return "天品"
		"origin": return "起源"
		_: return rarity


static func build_tooltip(data: Dictionary) -> String:
	var text := "%s · %s\n%s" % [
		data.get("name", "宝物"),
		rarity_label(str(data.get("rarity", "yellow"))),
		data.get("effect_desc", ""),
	]
	var detail := str(data.get("artifact_detail", ""))
	if not detail.is_empty():
		text += "\n-----\n" + detail
	return text


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		activated.emit(artifact, self)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		r = Rect2(Vector2.ZERO, ICON_SIZE)

	var bg := Color(0.045, 0.040, 0.035, 0.94)
	if _hovered:
		bg = Color(0.10, 0.085, 0.060, 0.98)
	draw_rect(r, bg, true)

	var inset := Rect2(r.position + Vector2(5, 5), r.size - Vector2(10, 10))
	_draw_symbol(str(artifact.get("id", "")), inset)
	_draw_rarity_border(r, str(artifact.get("rarity", "yellow")))


func _draw_rarity_border(r: Rect2, rarity: String) -> void:
	var border := _rarity_color(rarity)
	draw_rect(r.grow(-1), border, false, 2.0)
	if rarity == "origin":
		draw_rect(r.grow(-4), Color(1.0, 0.95, 0.70, 0.9), false, 1.0)
	if _hovered:
		draw_rect(r.grow(-3), Color(1.0, 0.90, 0.55, 0.22), false, 2.0)


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"mystique": return Color(0.66, 0.48, 0.94, 1.0)
		"earth": return Color(0.28, 0.78, 0.36, 1.0)
		"heaven": return Color(0.94, 0.28, 0.18, 1.0)
		"origin": return Color(0.28, 0.92, 0.92, 1.0)
		_: return Color(0.88, 0.68, 0.24, 1.0)


func _draw_symbol(id: String, r: Rect2) -> void:
	match id:
		"R-01": _draw_scabbard(r)
		"R-02": _draw_armor(r)
		"R-03": _draw_gem(r, Color(0.18, 0.86, 0.95), Color(0.75, 1.0, 1.0))
		"R-04": _draw_ring(r, Color(0.80, 0.07, 0.12), Color(1.0, 0.42, 0.38))
		"R-05": _draw_bracer(r)
		"R-06": _draw_hairpin(r)
		"R-07": _draw_tassel(r)
		"R-08": _draw_furnace(r)
		"R-09": _draw_lightning_stone(r)
		"R-10": _draw_chain(r)
		"R-11": _draw_eye(r)
		"R-12": _draw_lantern(r)
		"R-13": _draw_sword_stone(r)
		"R-14": _draw_heart_lamp(r)
		"R-15": _draw_many_swords(r)
		"R-16": _draw_silk_armor(r)
		"R-17": _draw_scale_bead(r)
		"R-18": _draw_mirror(r)
		"R-19": _draw_bottle(r)
		"R-20": _draw_scroll(r)
		"R-21": _draw_broken_blade(r)
		"R-22": _draw_reincarnation_mark(r)
		"R-S01": _draw_origin_sword(r)
		"R-S02": _draw_origin_shield(r)
		"R-S03": _draw_origin_coin(r)
		"R-S06": _draw_origin_meridian(r)
		"R-S08": _draw_origin_page(r)
		"EVENT_R_BRONZE_GOLEM": _draw_golem(r)
		_: _draw_gem(r, Color(0.82, 0.62, 0.24), Color(1.0, 0.86, 0.40))


func _draw_filled_polygon(points: PackedVector2Array, color: Color) -> void:
	var colors := PackedColorArray()
	for _i in range(points.size()):
		colors.append(color)
	draw_polygon(points, colors)


func _draw_scabbard(r: Rect2) -> void:
	_draw_filled_polygon(PackedVector2Array([r.position + Vector2(8, 2), r.position + Vector2(18, 2), r.position + Vector2(16, 25), r.position + Vector2(6, 25)]), Color(0.42, 0.23, 0.12))
	draw_line(r.position + Vector2(9, 6), r.position + Vector2(17, 14), Color(0.95, 0.68, 0.22), 2.0)
	draw_line(r.position + Vector2(7, 20), r.position + Vector2(17, 18), Color(0.17, 0.10, 0.06), 2.0)


func _draw_armor(r: Rect2) -> void:
	_draw_filled_polygon(PackedVector2Array([r.position + Vector2(5, 3), r.position + Vector2(21, 3), r.position + Vector2(23, 17), r.position + Vector2(13, 25), r.position + Vector2(3, 17)]), Color(0.68, 0.37, 0.20))
	draw_line(r.position + Vector2(7, 8), r.position + Vector2(18, 20), Color(0.22, 0.12, 0.08), 2.0)
	draw_line(r.position + Vector2(15, 4), r.position + Vector2(10, 16), Color(1.0, 0.72, 0.38), 1.5)


func _draw_gem(r: Rect2, base: Color, shine: Color) -> void:
	var c := r.get_center()
	_draw_filled_polygon(PackedVector2Array([c + Vector2(0, -12), c + Vector2(10, -3), c + Vector2(7, 10), c + Vector2(0, 13), c + Vector2(-7, 10), c + Vector2(-10, -3)]), base)
	draw_circle(c + Vector2(-3, -4), 3.0, shine)
	draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), Color(1.0, 1.0, 1.0, 0.35), 1.0)


func _draw_ring(r: Rect2, base: Color, shine: Color) -> void:
	var c := r.get_center()
	draw_circle(c, 11.0, base)
	draw_circle(c, 6.0, Color(0.045, 0.040, 0.035, 1.0))
	draw_line(c + Vector2(-5, -8), c + Vector2(7, -4), shine, 2.0)


func _draw_bracer(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(5, 5), Vector2(16, 18)), Color(0.34, 0.46, 0.50), true)
	draw_line(r.position + Vector2(7, 8), r.position + Vector2(20, 8), Color(0.74, 0.90, 0.95), 2.0)
	draw_line(r.position + Vector2(7, 19), r.position + Vector2(20, 19), Color(0.18, 0.24, 0.28), 2.0)


func _draw_hairpin(r: Rect2) -> void:
	draw_line(r.position + Vector2(6, 22), r.position + Vector2(22, 4), Color(0.86, 0.86, 0.82), 3.0)
	draw_circle(r.position + Vector2(22, 4), 4.0, Color(0.30, 0.92, 0.82))
	draw_line(r.position + Vector2(9, 16), r.position + Vector2(18, 22), Color(0.65, 0.95, 0.90), 1.5)


func _draw_tassel(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(9, 2), Vector2(9, 7)), Color(0.68, 0.10, 0.08), true)
	for x in [8, 12, 16, 20]:
		draw_line(r.position + Vector2(x, 9), r.position + Vector2(x - 2, 25), Color(0.82, 0.08, 0.06), 2.0)
	draw_line(r.position + Vector2(7, 4), r.position + Vector2(21, 4), Color(0.96, 0.74, 0.25), 1.5)


func _draw_furnace(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(5, 10), Vector2(18, 12)), Color(0.47, 0.28, 0.18), true)
	draw_rect(Rect2(r.position + Vector2(9, 5), Vector2(10, 7)), Color(0.62, 0.36, 0.18), true)
	draw_circle(r.position + Vector2(14, 16), 4.0, Color(1.0, 0.46, 0.12))
	draw_line(r.position + Vector2(5, 23), r.position + Vector2(1, 27), Color(0.30, 0.18, 0.12), 2.0)


func _draw_lightning_stone(r: Rect2) -> void:
	_draw_gem(r, Color(0.28, 0.45, 0.68), Color(0.84, 0.95, 1.0))
	var p := r.position
	_draw_filled_polygon(PackedVector2Array([p + Vector2(14, 3), p + Vector2(9, 14), p + Vector2(15, 13), p + Vector2(10, 25), p + Vector2(22, 10), p + Vector2(16, 11)]), Color(1.0, 0.88, 0.16))


func _draw_chain(r: Rect2) -> void:
	for i in range(3):
		var c := r.position + Vector2(8 + i * 6, 9 + i * 4)
		draw_circle(c, 5.0, Color(0.26, 0.70, 0.92))
		draw_circle(c, 2.8, Color(0.045, 0.040, 0.035))
	draw_line(r.position + Vector2(7, 8), r.position + Vector2(23, 24), Color(0.86, 0.95, 1.0, 0.6), 1.5)


func _draw_eye(r: Rect2) -> void:
	var c := r.get_center()
	_draw_filled_polygon(PackedVector2Array([c + Vector2(-12, 0), c + Vector2(-4, -7), c + Vector2(9, -5), c + Vector2(13, 0), c + Vector2(8, 6), c + Vector2(-5, 7)]), Color(0.46, 0.22, 0.76))
	draw_circle(c + Vector2(1, 0), 5.0, Color(0.12, 0.02, 0.20))
	draw_line(c + Vector2(1, -4), c + Vector2(1, 4), Color(0.92, 0.38, 1.0), 2.0)


func _draw_lantern(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(8, 7), Vector2(12, 16)), Color(0.16, 0.32, 0.24), true)
	draw_circle(r.position + Vector2(14, 15), 6.0, Color(0.24, 0.90, 0.42, 0.85))
	draw_line(r.position + Vector2(10, 5), r.position + Vector2(18, 5), Color(0.74, 0.58, 0.26), 2.0)
	draw_line(r.position + Vector2(14, 23), r.position + Vector2(14, 27), Color(0.74, 0.58, 0.26), 2.0)


func _draw_sword_stone(r: Rect2) -> void:
	_draw_gem(r, Color(0.32, 0.38, 0.48), Color(0.78, 0.88, 1.0))
	draw_line(r.position + Vector2(14, 4), r.position + Vector2(14, 22), Color(0.92, 0.92, 0.84), 2.0)
	draw_line(r.position + Vector2(9, 12), r.position + Vector2(19, 12), Color(0.92, 0.72, 0.30), 1.5)


func _draw_heart_lamp(r: Rect2) -> void:
	draw_circle(r.position + Vector2(11, 10), 5.0, Color(0.88, 0.18, 0.12))
	draw_circle(r.position + Vector2(17, 10), 5.0, Color(0.88, 0.18, 0.12))
	_draw_filled_polygon(PackedVector2Array([r.position + Vector2(6, 12), r.position + Vector2(22, 12), r.position + Vector2(14, 24)]), Color(0.88, 0.18, 0.12))
	draw_circle(r.position + Vector2(14, 15), 4.0, Color(1.0, 0.74, 0.18))


func _draw_many_swords(r: Rect2) -> void:
	for x in [8, 14, 20]:
		draw_line(r.position + Vector2(x, 4), r.position + Vector2(x, 24), Color(0.88, 0.90, 0.82), 2.0)
		draw_line(r.position + Vector2(x - 4, 14), r.position + Vector2(x + 4, 14), Color(0.88, 0.65, 0.26), 1.5)


func _draw_silk_armor(r: Rect2) -> void:
	_draw_filled_polygon(PackedVector2Array([r.position + Vector2(6, 3), r.position + Vector2(20, 3), r.position + Vector2(24, 16), r.position + Vector2(13, 25), r.position + Vector2(3, 16)]), Color(0.82, 0.86, 0.78))
	draw_line(r.position + Vector2(7, 8), r.position + Vector2(21, 17), Color(0.96, 0.98, 0.92), 1.2)
	draw_line(r.position + Vector2(20, 8), r.position + Vector2(7, 18), Color(0.96, 0.98, 0.92), 1.2)


func _draw_scale_bead(r: Rect2) -> void:
	_draw_gem(r, Color(0.18, 0.62, 0.50), Color(0.70, 1.0, 0.86))
	for y in [8, 13, 18]:
		draw_line(r.position + Vector2(8, y), r.position + Vector2(20, y + 2), Color(0.08, 0.30, 0.26), 1.5)


func _draw_mirror(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c, 11.0, Color(0.72, 0.78, 0.86))
	draw_circle(c, 8.0, Color(0.14, 0.28, 0.36))
	draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), Color(0.88, 1.0, 1.0), 2.0)


func _draw_bottle(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(10, 3), Vector2(8, 7)), Color(0.52, 0.75, 0.74), true)
	_draw_filled_polygon(PackedVector2Array([r.position + Vector2(7, 10), r.position + Vector2(21, 10), r.position + Vector2(24, 24), r.position + Vector2(4, 24)]), Color(0.28, 0.76, 0.68))
	draw_circle(r.position + Vector2(14, 18), 4.0, Color(0.86, 1.0, 0.92))


func _draw_scroll(r: Rect2) -> void:
	_draw_filled_polygon(PackedVector2Array([r.position + Vector2(6, 4), r.position + Vector2(23, 7), r.position + Vector2(19, 25), r.position + Vector2(4, 21)]), Color(0.78, 0.64, 0.34))
	draw_line(r.position + Vector2(9, 10), r.position + Vector2(19, 12), Color(1.0, 0.86, 0.34), 2.0)
	draw_line(r.position + Vector2(8, 16), r.position + Vector2(17, 18), Color(0.30, 0.18, 0.08), 1.5)


func _draw_broken_blade(r: Rect2) -> void:
	_draw_filled_polygon(PackedVector2Array([r.position + Vector2(11, 3), r.position + Vector2(20, 5), r.position + Vector2(15, 15), r.position + Vector2(21, 18), r.position + Vector2(8, 27), r.position + Vector2(12, 17), r.position + Vector2(6, 15)]), Color(0.78, 0.82, 0.88))
	draw_line(r.position + Vector2(9, 24), r.position + Vector2(18, 16), Color(0.92, 0.20, 0.14), 2.0)


func _draw_reincarnation_mark(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c, 11.0, Color(0.42, 0.24, 0.68))
	draw_circle(c, 7.0, Color(0.045, 0.040, 0.035))
	draw_circle(c, 3.5, Color(0.82, 0.55, 1.0))
	draw_line(c + Vector2(-10, 0), c + Vector2(10, 0), Color(0.82, 0.55, 1.0), 1.5)


func _draw_origin_sword(r: Rect2) -> void:
	_draw_many_swords(r)
	draw_circle(r.get_center(), 12.0, Color(0.20, 0.92, 0.90, 0.20))


func _draw_origin_shield(r: Rect2) -> void:
	_draw_armor(r)
	draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(20, 20)), Color(0.20, 0.92, 0.90, 0.18), false, 2.0)


func _draw_origin_coin(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c, 11.0, Color(0.88, 0.66, 0.20))
	draw_circle(c, 7.0, Color(0.20, 0.92, 0.90, 0.7))
	draw_line(c + Vector2(-5, 0), c + Vector2(5, 0), Color(1.0, 0.95, 0.70), 2.0)


func _draw_origin_meridian(r: Rect2) -> void:
	_draw_gem(r, Color(0.12, 0.72, 0.82), Color(0.90, 1.0, 0.95))
	draw_line(r.position + Vector2(7, 20), r.position + Vector2(22, 7), Color(1.0, 0.95, 0.70), 2.0)
	draw_circle(r.position + Vector2(9, 18), 2.0, Color(1.0, 0.95, 0.70))
	draw_circle(r.position + Vector2(19, 10), 2.0, Color(1.0, 0.95, 0.70))


func _draw_origin_page(r: Rect2) -> void:
	_draw_scroll(r)
	draw_circle(r.position + Vector2(18, 9), 4.0, Color(0.20, 0.92, 0.90, 0.75))


func _draw_golem(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(6, 6), Vector2(17, 16)), Color(0.58, 0.34, 0.18), true)
	draw_circle(r.position + Vector2(11, 13), 2.0, Color(0.18, 0.80, 0.68))
	draw_circle(r.position + Vector2(18, 13), 2.0, Color(0.18, 0.80, 0.68))
	draw_line(r.position + Vector2(9, 20), r.position + Vector2(21, 20), Color(0.22, 0.12, 0.08), 2.0)
