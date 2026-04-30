## GameMap.gd
## 16层动态地图场景控制器
extends Control

const BATTLE_SCENE    := "res://scenes/Battle.tscn"
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

# ── 布局常量 ───────────────────────────────────────────────────────
const FLOOR_COUNT    := 16
const FLOOR_SPACING  := 140     # 层间y距离（像素）
const MAP_H_PADDING  := 60      # 顶部/底部 padding
const MAP_W          := 1280    # 地图容器宽度
const NODE_W         := 72      # 节点图片宽（正方形适合圆形徽章）
const NODE_H         := 72
const COL_SPACING    := 280.0

# 总地图高度（多一层容纳起始节点）
const MAP_TOTAL_H := FLOOR_COUNT * FLOOR_SPACING + MAP_H_PADDING * 2

# 起始节点
const START_NODE_ID  := "__start__"
const START_NODE_TEX := "res://assets/nodes/start.png"

# 节点颜色（通过 modulate 控制状态）
const COLOR_CURRENT    := Color(1.0,  0.88, 0.15, 1.0)   # 金色：当前所在节点
const COLOR_ACCESSIBLE := Color(1.0,  1.0,  1.0,  1.0)   # 亮白：本层可选
const COLOR_VISITED    := Color(0.4,  0.4,  0.4,  0.85)  # 灰暗：已经过
const COLOR_FUTURE     := Color(0.6,  0.6,  0.65, 0.55)  # 半透明：未到达
const COLOR_DARK       := Color(0.3,  0.3,  0.3,  0.4)   # 暗：本层不可达

const SCALE_CURRENT    := Vector2(1.2, 1.2)  # 当前节点放大比例
const SCALE_NORMAL     := Vector2.ONE

# 节点类型 → 图片路径
const NODE_TEXTURES := {
	"normal":  "res://assets/nodes/monster.png",
	"elite":   "res://assets/nodes/elite.png",
	"bonfire": "res://assets/nodes/rest.png",
	"shop":    "res://assets/nodes/shop.png",
	"event":   "res://assets/nodes/adventure.png",
	"boss":    "res://assets/nodes/boss.png",
}

# ── 节点引用 ──────────────────────────────────────────────────────
@onready var hp_label:       Label          = %HPLabel
@onready var _stone_label:   Label          = %SpiritStoneLabel
@onready var map_scroll:     ScrollContainer = $MapScroll
@onready var map_container:  Control        = $MapScroll/MapContainer
@onready var node_popup:     PanelContainer = $NodePopup
@onready var popup_title:    Label          = %PopupTitle
@onready var popup_desc:     Label          = %PopupDesc
@onready var popup_btn1:     Button         = %PopupBtn1
@onready var popup_btn2:     Button         = %PopupBtn2
@onready var popup_close_btn:Button         = %PopupCloseBtn
@onready var victory_panel:  PanelContainer = $VictoryPanel
@onready var victory_label:  Label          = %VictoryLabel
@onready var victory_btn:    Button         = %VictoryBtn

# ── 内部状态 ──────────────────────────────────────────────────────
var _draw_layer: Control = null        # 连线层（最底层）
var _ring_layer: Control = null        # 光环层（最顶层，盖在节点之上）
var _node_buttons: Dictionary = {}     # node_id -> Button
var _start_btn: TextureButton = null   # 起始节点按钮
var _pending_node_id: String = ""      # 当前弹窗对应的节点id
var _circle_mat: ShaderMaterial = null # 所有节点共享的圆形裁切 shader
var _pulse_tween: Tween = null         # 当前节点脉冲动画
var _pulse_target: BaseButton = null   # 当前被脉冲动画控制的节点
var _tex_cache: Dictionary = {}        # res://路径 → Texture2D 缓存（避免重复读文件）


func _ready() -> void:
	MusicManager.play("map")
	node_popup.hide()
	victory_panel.hide()
	node_popup.z_index = 100
	node_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	victory_panel.z_index = 100
	victory_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# 确保 GameState 有地图数据
	if GameState.map_floors.is_empty():
		GameState.start_run("chen_tian_feng")  # 兜底：正常从 CharacterSelect 传入

	_build_map()
	_update_hp_label()
	_update_stone_label()

	# 等一帧后滚动到当前层
	await get_tree().process_frame
	_scroll_to_current_floor()

	# 若已完成所有层，显示胜利面板
	if GameState.map_current_floor > FLOOR_COUNT:
		_show_victory()

	Log.info("GameMap", "地图加载完成，当前层=%d" % GameState.map_current_floor)


# ── 构建地图 ──────────────────────────────────────────────────────

func _build_map() -> void:
	Log.info("GameMap", "开始构建地图...")
	# 清除旧内容
	for child in map_container.get_children():
		child.queue_free()
	_node_buttons.clear()

	# 设置容器高度
	map_container.custom_minimum_size = Vector2(MAP_W, MAP_TOTAL_H)
	map_container.size = Vector2(MAP_W, MAP_TOTAL_H)

	# 创建绘制层
	_draw_layer = load("res://scripts/MapDrawLayer.gd").new()
	_configure_map_layer(_draw_layer, 0)
	map_container.add_child(_draw_layer)

	var nodes: Dictionary = GameState.map_nodes
	var floors: Array     = GameState.map_floors
	Log.info("GameMap", "节点数量: %d, 层数: %d" % [nodes.size(), floors.size()])

	# 先绘制连线（在按钮下方）
	for node_id in nodes:
		var nd: Dictionary = nodes[node_id]
		var src := _node_center(int(nd["floor"]), int(nd["col"]), int(nd["total_cols"]))
		for next_id in nd["next_ids"]:
			if nodes.has(next_id):
				var nnd: Dictionary = nodes[next_id]
				var dst := _node_center(int(nnd["floor"]), int(nnd["col"]), int(nnd["total_cols"]))
				# 初始时均为 FUTURE (2)
				_draw_layer.add_line(src, dst, 2)
	_draw_layer.refresh()

	# 创建节点按钮
	for node_id in nodes:
		var nd: Dictionary = nodes[node_id]
		_create_node_button(node_id, nd)
	Log.info("GameMap", "节点按钮创建完成: %d" % _node_buttons.size())

	# 创建起始节点（位于第1层正下方）
	_create_start_node()

	# 光环层：加在所有按钮之后，确保渲染在节点上方
	_ring_layer = load("res://scripts/MapDrawLayer.gd").new()
	_configure_map_layer(_ring_layer, 20)
	map_container.add_child(_ring_layer)

	_update_node_visuals()


func _configure_map_layer(layer: Control, z: int) -> void:
	layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	layer.custom_minimum_size = Vector2(MAP_W, MAP_TOTAL_H)
	layer.offset_left = 0.0
	layer.offset_top = 0.0
	layer.offset_right = MAP_W
	layer.offset_bottom = MAP_TOTAL_H
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = z


## 圆形裁切 ShaderMaterial（懒加载，所有节点共享同一实例）
func _get_circle_mat() -> ShaderMaterial:
	if _circle_mat:
		return _circle_mat
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - 0.5;
	float d = length(uv);
	// smoothstep 抗锯齿：0.47~0.50 之间平滑淡出
	float alpha = 1.0 - smoothstep(0.47, 0.50, d);
	vec4 col = texture(TEXTURE, UV);
	COLOR = vec4(col.rgb, col.a * alpha);
}
"""
	_circle_mat = ShaderMaterial.new()
	_circle_mat.shader = shader
	return _circle_mat


## 加载贴图：绕过 ResourceLoader（import valid=false 会触发 ERROR），
## 直接通过绝对路径读取字节流，用魔术字节判断真实格式后解码。
## 结果缓存在 _tex_cache，相同路径只读一次磁盘。
func _load_texture(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]

	# 绝对路径（兼容中文目录；res:// 虚拟路径在中文绝对路径下 FileAccess 可能失败）
	var abs_path: String = ProjectSettings.globalize_path(path)
	var open_path: String = abs_path if FileAccess.file_exists(abs_path) else path
	var file := FileAccess.open(open_path, FileAccess.READ)
	if not file:
		push_warning("GameMap: 无法打开贴图 %s" % path)
		_tex_cache[path] = null
		return null

	var data := file.get_buffer(file.get_length())
	file.close()

	if data.size() < 4:
		push_warning("GameMap: 贴图文件过小 %s" % path)
		_tex_cache[path] = null
		return null

	var img := Image.new()
	var b0 := data[0]; var b1 := data[1]; var b2 := data[2]; var b3 := data[3]
	var loaded := false
	if b0 == 0xFF and b1 == 0xD8 and b2 == 0xFF:
		loaded = img.load_jpg_from_buffer(data) == OK   # JPEG（含 .jpg 改名为 .png 的情况）
	elif b0 == 0x89 and b1 == 0x50 and b2 == 0x4E and b3 == 0x47:
		loaded = img.load_png_from_buffer(data) == OK   # PNG
	elif b0 == 0x52 and b1 == 0x49 and b2 == 0x46 and b3 == 0x46:
		loaded = img.load_webp_from_buffer(data) == OK  # WebP（RIFF 容器）
	else:
		loaded = img.load_png_from_buffer(data) == OK \
			or img.load_webp_from_buffer(data) == OK \
			or img.load_jpg_from_buffer(data) == OK

	if not loaded:
		push_warning("GameMap: 不支持的贴图格式 %s" % path)
		_tex_cache[path] = null
		return null

	var tex := ImageTexture.create_from_image(img)
	_tex_cache[path] = tex
	return tex


func _create_node_button(node_id: String, nd: Dictionary) -> void:
	var btn := TextureButton.new()
	var ntype: String = nd["type"]
	var tex_path: String = NODE_TEXTURES.get(ntype, NODE_TEXTURES["normal"])
	btn.texture_normal = _load_texture(tex_path)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.custom_minimum_size = Vector2(NODE_W, NODE_H)
	btn.size = Vector2(NODE_W, NODE_H)
	btn.material = _get_circle_mat()  # 圆形裁切，去掉背景
	btn.z_index = 10

	var center := _node_center(int(nd["floor"]), int(nd["col"]), int(nd["total_cols"]))
	btn.position = center - Vector2(NODE_W * 0.5, NODE_H * 0.5)

	btn.pivot_offset = Vector2(NODE_W * 0.5, NODE_H * 0.5)
	btn.pressed.connect(_on_node_btn_pressed.bind(node_id))
	map_container.add_child(btn)
	_node_buttons[node_id] = btn


func _create_start_node() -> void:
	_start_btn = TextureButton.new()
	_start_btn.texture_normal = _load_texture(START_NODE_TEX)
	_start_btn.ignore_texture_size = true
	_start_btn.stretch_mode = TextureButton.STRETCH_SCALE
	_start_btn.custom_minimum_size = Vector2(NODE_W, NODE_H)
	_start_btn.size = Vector2(NODE_W, NODE_H)
	_start_btn.material = _get_circle_mat()
	_start_btn.z_index = 10
	var center := _start_node_center()
	_start_btn.position = center - Vector2(NODE_W * 0.5, NODE_H * 0.5)
	_start_btn.pivot_offset = Vector2(NODE_W * 0.5, NODE_H * 0.5)
	_start_btn.pressed.connect(_on_start_node_pressed)
	map_container.add_child(_start_btn)


func _start_node_center() -> Vector2:
	# 起始节点位于地图最底部（比第1层再低一个 FLOOR_SPACING）
	return Vector2(MAP_W / 2.0, FLOOR_COUNT * FLOOR_SPACING + MAP_H_PADDING)


# ── 节点坐标计算 ──────────────────────────────────────────────────

func _node_center(floor: int, col: int, total_cols: int) -> Vector2:
	var y := (FLOOR_COUNT - floor) * FLOOR_SPACING + MAP_H_PADDING
	var x := MAP_W / 2.0 + (col - (total_cols - 1) / 2.0) * COL_SPACING
	
	# Add consistent random offset based on floor and col
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(floor) + "_" + str(col) + "_seed") # Fixed seed for consistency
	var offset_x = rng.randf_range(-30.0, 30.0)
	var offset_y = rng.randf_range(-15.0, 15.0)
	
	return Vector2(x + offset_x, y + offset_y)


# ── 节点视觉状态更新 ─────────────────────────────────────────────

func _update_node_visuals() -> void:
	var nodes: Dictionary       = GameState.map_nodes
	var accessible: Array[String] = GameState.map_accessible_ids

	var current_id: String = GameState.map_last_node_id

	for node_id in _node_buttons:
		var btn: BaseButton     = _node_buttons[node_id]
		var nd: Dictionary      = nodes[node_id]
		var visited: bool       = bool(nd["visited"])
		var is_accessible: bool = accessible.has(node_id)
		var is_current: bool    = (node_id == current_id and visited)
		var floor: int          = int(nd["floor"])

		if is_current:
			# 当前所在节点：金色高亮 + 放大
			btn.modulate = COLOR_CURRENT
			btn.scale    = SCALE_CURRENT
			btn.disabled = true
		elif visited:
			# 已经过（非当前）：灰暗缩回正常大小
			btn.modulate = COLOR_VISITED
			btn.scale    = SCALE_NORMAL
			btn.disabled = true
		elif is_accessible:
			# 本层可选：亮白
			btn.modulate = COLOR_ACCESSIBLE
			btn.scale    = SCALE_NORMAL
			btn.disabled = false
		elif floor <= GameState.map_current_floor:
			# 本层其他不可达节点
			btn.modulate = COLOR_DARK
			btn.scale    = SCALE_NORMAL
			btn.disabled = true
		else:
			# 未到达的未来节点
			btn.modulate = COLOR_FUTURE
			btn.scale    = SCALE_NORMAL
			btn.disabled = true

	# 更新当前节点光环位置 + 脉冲动画
	if _ring_layer:
		var ring_center := Vector2(-9999.0, -9999.0)
		var pulse_target: BaseButton = null

		var cid := GameState.map_last_node_id
		if cid != "" and nodes.has(cid):
			# 已进入地图，最后访问的普通节点
			var cnd: Dictionary = nodes[cid]
			ring_center  = _node_center(int(cnd["floor"]), int(cnd["col"]), int(cnd["total_cols"]))
			pulse_target = _node_buttons.get(cid)
		elif not GameState.map_started and _start_btn != null:
			# 尚未出发：光环停在起始节点
			ring_center  = _start_node_center()
			pulse_target = _start_btn

		_ring_layer.set_ring_center(ring_center)

		_set_pulse_target(pulse_target)

	# 更新起始节点状态
	if _start_btn:
		if GameState.map_started:
			_start_btn.modulate = COLOR_VISITED
			_start_btn.scale = SCALE_NORMAL
			_start_btn.disabled = true
		else:
			_start_btn.modulate = COLOR_ACCESSIBLE
			_start_btn.disabled = false

	# 重绘连线（更新访问状态颜色）
	if _draw_layer:
		_draw_layer.clear_lines()
		# 起始节点 → 第1层各节点的连线
		var start_center := _start_node_center()
		var floor1_ids: Array = GameState.map_floors[0] if GameState.map_floors.size() > 0 else []
		for nid in floor1_ids:
			if nodes.has(nid):
				var fn: Dictionary = nodes[nid]
				var dst := _node_center(int(fn["floor"]), int(fn["col"]), int(fn["total_cols"]))
				var state = 0 if GameState.map_started else 1
				_draw_layer.add_line(start_center, dst, state)
		# 常规层间连线
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
						state = 1 # ACCESSIBLE
					_draw_layer.add_line(src, dst, state)
		_draw_layer.refresh()


func _set_pulse_target(target: BaseButton) -> void:
	if _pulse_target == target and _pulse_tween and _pulse_tween.is_running():
		return

	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null

	if _pulse_target and is_instance_valid(_pulse_target):
		_pulse_target.scale = SCALE_NORMAL

	_pulse_target = target
	if not _pulse_target:
		return

	_pulse_target.pivot_offset = _pulse_target.size * 0.5
	_pulse_target.scale = Vector2(1.08, 1.08)
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_pulse_target, "scale", Vector2(1.25, 1.25), 0.65)
	_pulse_tween.tween_property(_pulse_target, "scale", Vector2(1.06, 1.06), 0.65)


func _update_hp_label() -> void:
	var hp_max: int = GameState.character.get("hp_max", 60)
	hp_label.text = "HP %d / %d" % [GameState.current_hp, hp_max]


func _update_stone_label() -> void:
	_stone_label.text = "灵石 %d" % GameState.spirit_stones


# ── 滚动到当前层 ─────────────────────────────────────────────────

func _scroll_to_current_floor() -> void:
	var center_y: int
	if not GameState.map_started:
		# 未开始：定位到起始节点
		center_y = int(FLOOR_COUNT * FLOOR_SPACING + MAP_H_PADDING)
	else:
		# 已开始：定位到下一个可选层
		var floor := clampi(GameState.map_current_floor + 1, 1, FLOOR_COUNT)
		center_y = (FLOOR_COUNT - floor) * FLOOR_SPACING + MAP_H_PADDING
	var viewport_h := map_scroll.size.y
	var target_scroll := int(center_y - viewport_h * 0.6)
	target_scroll = clampi(target_scroll, 0, maxi(int(MAP_TOTAL_H - viewport_h), 0))
	map_scroll.scroll_vertical = target_scroll


# ── 节点点击处理 ─────────────────────────────────────────────────

func _on_node_btn_pressed(node_id: String) -> void:
	var nd: Dictionary = GameState.map_nodes.get(node_id, {})
	if nd.is_empty():
		return
	var ntype: String = nd["type"]

	# 访问节点（标记状态、更新accessible）
	GameState.visit_map_node(node_id)
	_pending_node_id = node_id

	match ntype:
		"normal", "elite", "boss":
			# 直接进入战斗
			get_tree().change_scene_to_file(BATTLE_SCENE)
		"bonfire":
			_show_bonfire_popup(node_id)
		"shop":
			_show_shop_popup(node_id)
		"event":
			_show_event_popup(node_id)
		_:
			_on_popup_close()


func _on_start_node_pressed() -> void:
	_pending_node_id = START_NODE_ID
	_show_start_popup()


func _show_start_popup() -> void:
	popup_title.text = "轮回再起"
	popup_desc.text = (
		"你缓缓睁开双眼。\n\n"
		+ "眼前是登仙台的大门——这道景，是那么熟悉。\n\n"
		+ "多少次了？你已记不清了。\n"
		+ "每一次轮回，记忆会稍稍清晰一些。\n\n"
		+ "今日，你握剑的手比昨日更稳。\n\n"
		+ "登仙台在等你。"
	)
	popup_btn1.visible = false
	popup_btn2.visible = false
	popup_close_btn.text = "踏入轮回"
	node_popup.show()


func _show_bonfire_popup(node_id: String) -> void:
	var heal := int(GameState.character.get("hp_max", 60) * 0.3)
	GameState.apply_hp_change(heal)
	_update_hp_label()

	popup_title.text   = "🔥 篝火"
	popup_desc.text    = "你在篝火旁调息，伤势稍有恢复。\n\n[已回复 %d 点生命值]" % heal
	popup_btn1.text    = "升级卡牌（未实装）"
	popup_btn1.visible = true
	popup_btn2.visible = false
	popup_close_btn.text = "继续前行"
	node_popup.show()


func _show_shop_popup(_node_id: String) -> void:
	popup_title.text   = "💰 黑市"
	popup_desc.text    = "神秘商人向你展示货架上的奇物……\n\n（商店系统尚未实装）"
	popup_btn1.visible = false
	popup_btn2.visible = false
	popup_close_btn.text = "继续前行"
	node_popup.show()


func _show_event_popup(_node_id: String) -> void:
	popup_title.text   = "❓ 执念"
	popup_desc.text    = "一道残影出现在你面前，似乎有话要说……\n\n（事件系统尚未实装）"
	popup_btn1.visible = false
	popup_btn2.visible = false
	popup_close_btn.text = "继续前行"
	node_popup.show()


# ── 弹窗信号 ─────────────────────────────────────────────────────

func _on_popup_btn1_pressed() -> void:
	# 预留：篝火升级 / 商店购买
	pass


func _on_popup_btn2_pressed() -> void:
	# 预留：第二操作
	pass


func _on_popup_close_btn_pressed() -> void:
	node_popup.hide()
	if _pending_node_id == START_NODE_ID:
		# 起始节点确认后解锁第1层，滚动过去
		GameState.start_map()
		_on_popup_close()
		await get_tree().process_frame
		_scroll_to_current_floor()
	else:
		_on_popup_close()


func _on_popup_close() -> void:
	_update_node_visuals()
	_update_hp_label()
	# 若已访问所有16层（Boss已击败），显示胜利面板
	if GameState.map_current_floor > FLOOR_COUNT:
		_show_victory()


# ── 胜利面板 ─────────────────────────────────────────────────────

func _show_victory() -> void:
	victory_label.text = (
		"恭喜！\n\n你穿越了第一重天的所有试炼，\n剥皮仙君在你剑下化为虚无。\n\n"
		+ "登仙之路，才刚刚开始……"
	)
	victory_panel.show()


func _on_victory_btn_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
