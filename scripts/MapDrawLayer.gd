## MapDrawLayer.gd
## 绘制地图连线的 Control 层，覆盖在 MapContainer 上。
extends Control

## 连线数据：每条连线 = [src_center: Vector2, dst_center: Vector2, is_visited: bool]
var _lines: Array = []

const COLOR_LINE         := Color(0.0,  0.0,  0.0,  0.85)  # 所有连线：黑色
const COLOR_CURRENT_RING := Color(1.0,  0.88, 0.15, 1.0)   # 当前节点光环
const LINE_WIDTH         := 4.0                              # 连线宽度

# 当前节点光环（中心坐标；(-9999,-9999) 表示不显示）
var _ring_center: Vector2 = Vector2(-9999.0, -9999.0)


func clear_lines() -> void:
	_lines.clear()
	queue_redraw()


func add_line(src: Vector2, dst: Vector2, is_visited: bool) -> void:
	_lines.append([src, dst, is_visited])


func set_ring_center(center: Vector2) -> void:
	_ring_center = center
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	# 连线（全部黑色，不区分是否已访问）
	for entry in _lines:
		var src: Vector2 = entry[0]
		var dst: Vector2 = entry[1]
		draw_line(src, dst, COLOR_LINE, LINE_WIDTH, true)

	# 当前节点光环（外层 glow + 内层实环）
	if _ring_center.x > -9000.0:
		draw_arc(_ring_center, 44.0, 0.0, TAU, 64, Color(1.0, 0.85, 0.1, 0.3), 10.0, true)
		draw_arc(_ring_center, 41.0, 0.0, TAU, 64, COLOR_CURRENT_RING, 3.5, true)
