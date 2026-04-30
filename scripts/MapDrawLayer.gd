## MapDrawLayer.gd
## 绘制地图连线的 Control 层，覆盖在 MapContainer 上。
extends Control

enum LineState { VISITED, ACCESSIBLE, FUTURE }

## 连线数据：每条连线 = [src_center: Vector2, dst_center: Vector2, state: LineState]
var _lines: Array = []

const COLOR_VISITED      := Color(0.86, 0.66, 0.28, 0.95)  # 已走过路径：金色实线
const COLOR_ACCESSIBLE   := Color(1.0, 0.88, 0.45, 0.95)   # 当前可选路径：亮金实线
const COLOR_FUTURE       := Color(0.52, 0.57, 0.68, 0.58)  # 未来路径：蓝灰实线

const COLOR_CURRENT_RING := Color(1.0,  0.88, 0.15, 1.0)   # 当前节点光环
const COLOR_LINE_SHADOW  := Color(0.0, 0.0, 0.0, 0.42)
const LINE_WIDTH         := 5.0                              # 连线宽度
const NODE_EDGE_GAP      := 38.0                             # 连线端点避开节点中心

# 当前节点光环（中心坐标；(-9999,-9999) 表示不显示）
var _ring_center: Vector2 = Vector2(-9999.0, -9999.0)


func clear_lines() -> void:
	_lines.clear()
	queue_redraw()


func add_line(src: Vector2, dst: Vector2, state: int) -> void:
	_lines.append([src, dst, state])


func set_ring_center(center: Vector2) -> void:
	_ring_center = center
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _get_bezier_points(p0: Vector2, p1: Vector2, p2: Vector2, segments: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var q0 := p0.lerp(p1, t)
		var q1 := p1.lerp(p2, t)
		pts.append(q0.lerp(q1, t))
	return pts


func _get_curve_points(src: Vector2, dst: Vector2) -> PackedVector2Array:
	var mid := (src + dst) * 0.5
	var dir := (dst - src).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var offset_mag := (src.x + src.y) * 0.1
	var control := mid + perp * (20.0 + sin(offset_mag) * 10.0)
	return _get_bezier_points(src, control, dst)


func _trim_to_node_edge(src: Vector2, dst: Vector2) -> Array:
	var delta := dst - src
	var length := delta.length()
	if length <= NODE_EDGE_GAP * 2.0:
		return [src, dst]
	var dir := delta / length
	return [src + dir * NODE_EDGE_GAP, dst - dir * NODE_EDGE_GAP]


func _draw() -> void:
	# 绘制连线
	for entry in _lines:
		var endpoints := _trim_to_node_edge(entry[0], entry[1])
		var src: Vector2 = endpoints[0]
		var dst: Vector2 = endpoints[1]
		var state: int = entry[2]
		var pts := _get_curve_points(src, dst)
		
		draw_polyline(pts, COLOR_LINE_SHADOW, LINE_WIDTH + 3.0, true)
		
		match state:
			LineState.VISITED:
				draw_polyline(pts, COLOR_VISITED, LINE_WIDTH, true)
			LineState.ACCESSIBLE:
				draw_polyline(pts, COLOR_ACCESSIBLE, LINE_WIDTH, true)
			LineState.FUTURE:
				draw_polyline(pts, COLOR_FUTURE, LINE_WIDTH * 0.8, true)

	# 当前节点光环（外层 glow + 内层实环）
	if _ring_center.x > -9000.0:
		draw_arc(_ring_center, 44.0, 0.0, TAU, 64, Color(1.0, 0.85, 0.1, 0.3), 10.0, true)
		draw_arc(_ring_center, 41.0, 0.0, TAU, 64, COLOR_CURRENT_RING, 3.5, true)
