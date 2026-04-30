# GameMap UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重构《无尽仙台》的 GameMap 界面，采用“云海浮岛”视觉风格，实现节点错落排布、贝塞尔曲线连线以及浮岛呼吸动画，增强修真沉浸感。

**Architecture:** 
1. 扩展 `scripts/GameMap.gd`，在 `_node_center()` 引入基于种子的随机坐标偏移；在 `_process()` 中更新节点的浮动 Y 偏移。
2. 重写 `scripts/MapDrawLayer.gd`，利用 `draw_polyline` 绘制平滑的贝塞尔实线，并自行实现等距分段以绘制虚线。
3. 修改 `scenes/GameMap.tscn`，替换 `Header` 和 `NodePopup` 的样式属性（引入暗黑渐变及修仙风格配色）。

**Tech Stack:** Godot 4.3 (GDScript), CanvasItem drawing.

---

### Task 1: Update Node Positioning & Animation

**Files:**
- Modify: `scripts/GameMap.gd`

- [ ] **Step 1: Modify `_node_center` for random offset**
In `scripts/GameMap.gd`, modify `_node_center` to use a seeded random generator so positions are consistently offset.

```gdscript
# Replace _node_center method:
func _node_center(floor: int, col: int, total_cols: int) -> Vector2:
	var y := (FLOOR_COUNT - floor) * FLOOR_SPACING + MAP_H_PADDING
	var x := MAP_W / 2.0 + (col - (total_cols - 1) / 2.0) * COL_SPACING
	
	# Add consistent random offset based on floor and col
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(floor) + "_" + str(col) + "_seed") # Fixed seed for consistency
	var offset_x = rng.randf_range(-30.0, 30.0)
	var offset_y = rng.randf_range(-15.0, 15.0)
	
	return Vector2(x + offset_x, y + offset_y)
```

- [ ] **Step 2: Add floating animation variables**
Add variables to manage floating animation at the top of `GameMap.gd`.

```gdscript
# Under class variables:
var _node_float_data: Dictionary = {} # node_id -> {"phase": float, "speed": float, "base_y": float}
```

- [ ] **Step 3: Initialize floating data**
In `_create_node_button`, initialize the phase and speed for the animation.

```gdscript
# At the end of _create_node_button:
var rng = RandomNumberGenerator.new()
rng.randomize()
_node_float_data[node_id] = {
    "phase": rng.randf_range(0.0, TAU),
    "speed": rng.randf_range(1.5, 2.5),
    "base_y": btn.position.y
}
```

- [ ] **Step 4: Implement `_process` for animation**
Add the `_process` method to update the Y position of the floating islands.

```gdscript
func _process(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	for node_id in _node_buttons:
		if _node_float_data.has(node_id):
			var data = _node_float_data[node_id]
			var btn: TextureButton = _node_buttons[node_id]
			var y_offset = sin(time * data["speed"] + data["phase"]) * 6.0
			btn.position.y = data["base_y"] + y_offset
```

- [ ] **Step 5: Manual verification**
Run the project and start a game. Verify that the map nodes are no longer in a strict grid and they slowly float up and down.

- [ ] **Step 6: Commit**
```bash
git add scripts/GameMap.gd
git commit -m "feat(map): add node coordinate jitter and floating animation"
```

---

### Task 2: Implement Bezier Curves in MapDrawLayer

**Files:**
- Modify: `scripts/MapDrawLayer.gd`
- Modify: `scripts/GameMap.gd` (to pass node states)

- [ ] **Step 1: Update line data structure in `MapDrawLayer.gd`**
Modify `add_line` to accept a state (0: visited, 1: accessible, 2: future) instead of boolean.

```gdscript
# In MapDrawLayer.gd
enum LineState { VISITED, ACCESSIBLE, FUTURE }

const COLOR_VISITED      := Color(0.15, 0.15, 0.15, 0.95)  # 深灰实线
const COLOR_ACCESSIBLE   := Color(0.9, 0.85, 0.7, 0.9)     # 亮金色虚线
const COLOR_FUTURE       := Color(0.6, 0.6, 0.65, 0.4)     # 灰色半透明虚线

func add_line(src: Vector2, dst: Vector2, state: int) -> void:
	_lines.append([src, dst, state])
```

- [ ] **Step 2: Add curve and dashed line drawing functions**
In `MapDrawLayer.gd`, implement Bezier curve evaluation and custom dashed line drawing.

```gdscript
# Helper function to evaluate quadratic bezier
func _get_bezier_points(p0: Vector2, p1: Vector2, p2: Vector2, segments: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var q0 = p0.lerp(p1, t)
		var q1 = p1.lerp(p2, t)
		pts.append(q0.lerp(q1, t))
	return pts

# Helper to draw dashed polyline
func _draw_dashed_polyline(pts: PackedVector2Array, color: Color, width: float, dash_length: float, space_length: float):
	var distance = 0.0
	var is_drawing = true
	for i in range(pts.size() - 1):
		var p_start = pts[i]
		var p_end = pts[i+1]
		var segment_len = p_start.distance_to(p_end)
		var dir = (p_end - p_start).normalized()
		
		var current_p = p_start
		var remaining = segment_len
		
		while remaining > 0:
			var step = dash_length if is_drawing else space_length
			if remaining < step:
				if is_drawing:
					draw_line(current_p, p_end, color, width, true)
				distance += remaining
				remaining = 0
			else:
				var next_p = current_p + dir * step
				if is_drawing:
					draw_line(current_p, next_p, color, width, true)
				current_p = next_p
				remaining -= step
				is_drawing = !is_drawing
```

- [ ] **Step 3: Update `_draw()` in `MapDrawLayer.gd`**
Use the new curve logic to draw the lines.

```gdscript
func _draw() -> void:
	for entry in _lines:
		var src: Vector2 = entry[0]
		var dst: Vector2 = entry[1]
		var state: int = entry[2]
		
		# 控制点：向右偏移一定距离制造弧度
		var mid = (src + dst) / 2.0
		var ctrl = mid + Vector2(40.0, 0.0) # Bend to the right slightly
		var pts = _get_bezier_points(src, ctrl, dst, 20)
		
		if state == LineState.VISITED:
			draw_polyline(pts, COLOR_VISITED, LINE_WIDTH, true)
		elif state == LineState.ACCESSIBLE:
			_draw_dashed_polyline(pts, COLOR_ACCESSIBLE, LINE_WIDTH, 10.0, 6.0)
		else:
			_draw_dashed_polyline(pts, COLOR_FUTURE, LINE_WIDTH, 8.0, 8.0)

	if _ring_center.x > -9000.0:
		draw_arc(_ring_center, 44.0, 0.0, TAU, 64, Color(1.0, 0.85, 0.1, 0.3), 10.0, true)
		draw_arc(_ring_center, 41.0, 0.0, TAU, 64, COLOR_CURRENT_RING, 3.5, true)
```

- [ ] **Step 4: Update GameMap.gd to pass the correct state**
In `GameMap.gd`'s `_update_node_visuals`, calculate if the line targets an accessible node or future node.

```gdscript
# In GameMap.gd, inside _update_node_visuals() for line drawing
		for node_id in nodes:
			var nd: Dictionary = nodes[node_id]
			var src := _node_center(int(nd["floor"]), int(nd["col"]), int(nd["total_cols"]))
			for next_id in nd["next_ids"]:
				if nodes.has(next_id):
					var nnd: Dictionary = nodes[next_id]
					var dst := _node_center(int(nnd["floor"]), int(nnd["col"]), int(nnd["total_cols"]))
					
					var state = 2 # FUTURE by default
					if bool(nd["visited"]) and bool(nnd["visited"]):
						state = 0 # VISITED
					elif bool(nd["visited"]) and accessible.has(next_id):
						state = 1 # ACCESSIBLE
					elif node_id == START_NODE_ID and GameState.map_started == false:
						state = 1 # ACCESSIBLE for start lines
						
					_draw_layer.add_line(src, dst, state)
```
*Note: Also modify the start node logic in `_update_node_visuals` to pass state instead of boolean.*

```gdscript
		# 起始节点 → 第1层各节点的连线
		var start_center := _start_node_center()
		var floor1_ids: Array = GameState.map_floors[0] if GameState.map_floors.size() > 0 else []
		for nid in floor1_ids:
			if nodes.has(nid):
				var fn: Dictionary = nodes[nid]
				var dst := _node_center(int(fn["floor"]), int(fn["col"]), int(fn["total_cols"]))
				var state = 0 if GameState.map_started else 1
				_draw_layer.add_line(start_center, dst, state)
```

- [ ] **Step 5: Run Manual Tests**
Open the game map. Check that lines are now curved. Visited lines are solid dark gray. The immediate next lines are bright dashed. Distant lines are dull dashed.

- [ ] **Step 6: Commit**
```bash
git add scripts/MapDrawLayer.gd scripts/GameMap.gd
git commit -m "feat(map): implement bezier curves and dotted path rendering based on reachability"
```

---

### Task 3: UI Theming Update (Tscn modification)

**Files:**
- Create: `scripts/temp_modify_tscn.gd` (Temporary script to edit Tscn programmatically to avoid manual GUI work, then delete it)
- Modify: `scenes/GameMap.tscn`

- [ ] **Step 1: Write temporary script to modify GameMap.tscn**

```gdscript
# Create temp_modify_tscn.gd
extends SceneTree

func _init():
    var packed_scene = load("res://scenes/GameMap.tscn")
    var scene: Node = packed_scene.instantiate()
    
    # 1. Update Header Background (ColorRect instead of transparent)
    var header = scene.get_node("Header")
    var header_bg = ColorRect.new()
    header_bg.name = "HeaderBG"
    header_bg.color = Color(0.0, 0.0, 0.0, 0.7)
    header_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    header.add_child(header_bg)
    header.move_child(header_bg, 0)
    header_bg.owner = scene
    
    # 2. Update Popup styling
    var popup: PanelContainer = scene.get_node("NodePopup")
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.12, 0.1, 0.1, 0.95)
    style.border_width_left = 2; style.border_width_top = 2; style.border_width_right = 2; style.border_width_bottom = 2
    style.border_color = Color(0.7, 0.6, 0.4, 1.0)
    style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
    popup.add_theme_stylebox_override("panel", style)
    
    # Save the updated scene
    var new_packed = PackedScene.new()
    new_packed.pack(scene)
    ResourceSaver.save(new_packed, "res://scenes/GameMap.tscn")
    
    print("GameMap.tscn updated successfully.")
    quit()
```

- [ ] **Step 2: Run the script to apply changes**
```bash
# Godot CLI needs to run the script
# godot --headless -s scripts/temp_modify_tscn.gd
```

- [ ] **Step 3: Cleanup temporary script**
```bash
# rm scripts/temp_modify_tscn.gd
```

- [ ] **Step 4: Manual UI Verification**
Run the game, open the map. The header should have a dark translucent background. Click a node, the popup should have a dark brown/gray background with a golden border and rounded corners.

- [ ] **Step 5: Commit**
```bash
git add scenes/GameMap.tscn
git commit -m "style(map): apply Xianxia theme styling to header and popups"
```
