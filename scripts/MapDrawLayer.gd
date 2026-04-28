## MapDrawLayer.gd
## 绘制地图连线的 Control 层，覆盖在 MapContainer 上。
extends Control

## 连线数据：每条连线 = [src_center: Vector2, dst_center: Vector2, is_visited: bool]
var _lines: Array = []

const COLOR_DEFAULT  := Color(0.45, 0.45, 0.55, 0.5)
const COLOR_VISITED  := Color(0.75, 0.70, 0.30, 0.8)
const LINE_WIDTH     := 2.5


func clear_lines() -> void:
	_lines.clear()
	queue_redraw()


func add_line(src: Vector2, dst: Vector2, is_visited: bool) -> void:
	_lines.append([src, dst, is_visited])


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	for entry in _lines:
		var src: Vector2    = entry[0]
		var dst: Vector2    = entry[1]
		var visited: bool   = entry[2]
		var color: Color    = COLOR_VISITED if visited else COLOR_DEFAULT
		draw_line(src, dst, color, LINE_WIDTH, true)
