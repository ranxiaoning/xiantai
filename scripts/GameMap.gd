## GameMap.gd
## 16层动态地图场景控制器
extends Control

const BATTLE_SCENE    := "res://scenes/Battle.tscn"
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const CardViewScene   = preload("res://scenes/CardView.tscn")
const CardZoomOverlayScript = preload("res://scripts/CardZoomOverlay.gd")

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
@onready var hp_label:        Label           = %HPLabel
@onready var _stone_label:    Label           = %SpiritStoneLabel
@onready var _deck_btn:       Button          = %DeckBtn
@onready var _bag_prev:       Button          = $Header/BagBar/BagPrevBtn
@onready var _bag_next:       Button          = $Header/BagBar/BagNextBtn
@onready var _bag_slots:      HBoxContainer   = $Header/BagBar/BagSlotContainer
@onready var _intro_overlay:  Control         = $IntroOverlay
@onready var _intro_label:    Label           = $IntroOverlay/IntroLabel
@onready var _art_prev:       Button          = $TreasureBar/TreasurePrevBtn
@onready var _art_next:       Button          = $TreasureBar/TreasureNextBtn
@onready var _art_slots:      HBoxContainer   = $TreasureBar/TreasureSlotContainer
@onready var _deck_overlay:   Control         = %DeckOverlay
@onready var _deck_count:     Label           = %DeckCount
@onready var _deck_grid:      GridContainer   = %DeckGrid
@onready var _deck_scroll:    ScrollContainer = $DeckOverlay/DeckPanel/DeckPad/DeckVBox/DeckScroll
@onready var map_scroll:      ScrollContainer = $MapScroll
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

# ── 背包栏 ────────────────────────────────────────────────────────
const SLOTS_PER_PAGE := 5
var _bag_page := 0

# ── 宝物栏 ────────────────────────────────────────────────────────
const ART_PER_PAGE := 10
var _art_page := 0

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
var _card_zoom_overlay = null
var _deck_upgrade_check: CheckBox = null
var _deck_preview_upgraded := false
var _test_mode := false


func _ready() -> void:
	MusicManager.play("map")
	node_popup.hide()
	victory_panel.hide()
	_deck_overlay.hide()
	node_popup.z_index = 100
	node_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	victory_panel.z_index = 100
	victory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_build_card_zoom_overlay()
	_build_deck_upgrade_check()
	_build_test_mode_toggle()
	var in_game_menu := InGameMenu.new()
	add_child(in_game_menu)
	in_game_menu.abandon_confirmed.connect(_on_menu_abandon_confirmed)
	in_game_menu.return_to_menu_confirmed.connect(_on_menu_return_confirmed)

	# 确保 GameState 有地图数据
	if GameState.map_floors.is_empty():
		GameState.start_run("chen_tian_feng")  # 兜底：正常从 CharacterSelect 传入

	_build_map()
	_update_hp_label()
	_update_stone_label()
	_bag_prev.pressed.connect(_on_bag_prev)
	_bag_next.pressed.connect(_on_bag_next)
	_refresh_bag()
	_art_prev.pressed.connect(_on_art_prev)
	_art_next.pressed.connect(_on_art_next)
	_refresh_artifacts()
	if not GameState.map_intro_played:
		GameState.map_intro_played = true
		_play_intro_animation()
	else:
		_intro_overlay.hide()

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
		var is_accessible: bool = accessible.has(node_id) or (_test_mode and GameState.map_started)
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
	_stone_label.text = "%d" % GameState.spirit_stones


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
	_update_hp_label()

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
	popup_btn1.text    = "升级卡牌"
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
	node_popup.hide()
	get_tree().change_scene_to_file("res://scenes/BonfireUpgrade.tscn")


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


# ── 卡组查看 ──────────────────────────────────────────────────────────

func _on_deck_btn_pressed() -> void:
	_open_deck()


func _on_deck_close_btn_pressed() -> void:
	if _card_zoom_overlay:
		_card_zoom_overlay.hide_card()
	_deck_overlay.hide()


func _on_dim_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _card_zoom_overlay and _card_zoom_overlay.visible:
			_card_zoom_overlay.hide_card()
			return
		_deck_overlay.hide()


func _get_deck_card_size() -> Vector2i:
	const COLS := 5
	const H_SEP := 10
	const PAD_X := 96
	const CARD_ASPECT := 2752.0 / 1536.0
	var vp := get_viewport_rect().size
	var card_w := int((vp.x - PAD_X - H_SEP * (COLS - 1)) / float(COLS))
	var card_h := int(card_w * CARD_ASPECT)
	return Vector2i(card_w, card_h)


func _open_deck() -> void:
	# 缩略卡按 5 列铺满弹窗宽度；高度自然形成纵向滚动。
	const COLS    := 5
	const H_SEP   := 10
	const PAD_X   := 96
	const CARD_ASPECT := 2752.0 / 1536.0
	var vp        := get_viewport_rect().size
	var card_w    := int((vp.x - PAD_X - H_SEP * (COLS - 1)) / float(COLS))
	var card_h    := int(card_w * CARD_ASPECT)
	_deck_grid.add_theme_constant_override("h_separation", H_SEP)
	_deck_grid.add_theme_constant_override("v_separation", H_SEP)
	_populate_deck_grid(card_w, card_h)
	_deck_scroll.scroll_horizontal = 0
	_deck_scroll.scroll_vertical = 0
	_deck_overlay.show()
	call_deferred("_reset_deck_scroll")


func _populate_deck_grid(card_w: int, card_h: int) -> void:
	for child in _deck_grid.get_children():
		child.queue_free()

	var deck: Array[String] = GameState.deck
	_deck_count.text = "%d 张" % deck.size()

	for card_id in deck:
		var card_data := CardDatabase.get_card(card_id)
		if card_data.is_empty():
			continue
		var display_card := _make_deck_display_card(card_data)

		var view: Control = CardViewScene.instantiate()
		view.custom_minimum_size = Vector2(card_w, card_h)
		view.mouse_filter        = Control.MOUSE_FILTER_STOP
		view.setup(display_card, null, true)
		view.set_hover_motion_enabled(false)
		view.play_blocked.connect(_show_deck_card_zoom.bind(display_card, view))
		_deck_grid.add_child(view)


func _build_card_zoom_overlay() -> void:
	_card_zoom_overlay = CardZoomOverlayScript.new()
	add_child(_card_zoom_overlay)


func _build_deck_upgrade_check() -> void:
	_deck_upgrade_check = CheckBox.new()
	_deck_upgrade_check.text = "查看升级"
	_deck_upgrade_check.button_pressed = _deck_preview_upgraded
	_deck_upgrade_check.focus_mode = Control.FOCUS_NONE
	_deck_upgrade_check.anchor_left = 0.0
	_deck_upgrade_check.anchor_top = 1.0
	_deck_upgrade_check.anchor_right = 0.0
	_deck_upgrade_check.anchor_bottom = 1.0
	_deck_upgrade_check.offset_left = 24.0
	_deck_upgrade_check.offset_top = -58.0
	_deck_upgrade_check.offset_right = 170.0
	_deck_upgrade_check.offset_bottom = -22.0
	_deck_upgrade_check.z_index = 20
	_deck_upgrade_check.add_theme_font_size_override("font_size", 18)
	_deck_upgrade_check.add_theme_color_override("font_color", Color(0.95, 0.84, 0.44))
	_deck_upgrade_check.toggled.connect(_on_deck_preview_upgrade_toggled)
	_deck_overlay.add_child(_deck_upgrade_check)


func _make_deck_display_card(card_data: Dictionary) -> Dictionary:
	if not _deck_preview_upgraded:
		return card_data
	var display_card := card_data.duplicate(true)
	display_card["is_upgraded"] = true
	return display_card


func _on_deck_preview_upgrade_toggled(pressed: bool) -> void:
	_deck_preview_upgraded = pressed
	var card_size := _get_deck_card_size()
	_populate_deck_grid(card_size.x, card_size.y)


func _show_deck_card_zoom(_blocked_card: Dictionary, card_data: Dictionary, source_view: Control) -> void:
	_card_zoom_overlay.show_card(card_data, "", source_view.get_global_rect())


func _reset_deck_scroll() -> void:
	_deck_scroll.scroll_horizontal = 0
	_deck_scroll.scroll_vertical = 0


# ── 背包道具栏 ────────────────────────────────────────────────────

func _refresh_bag() -> void:
	for c in _bag_slots.get_children():
		c.queue_free()

	var items: Array = GameState.consumables
	var start := _bag_page * SLOTS_PER_PAGE

	for i in range(SLOTS_PER_PAGE):
		var idx := start + i
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(44, 44)
		btn.add_theme_font_size_override("font_size", 11)
		btn.focus_mode = Control.FOCUS_NONE

		if idx < items.size():
			var item: Dictionary = items[idx]
			btn.add_theme_stylebox_override("normal",   _bag_slot_style(true))
			btn.add_theme_stylebox_override("hover",    _bag_slot_style(true, true))
			btn.add_theme_stylebox_override("pressed",  _bag_slot_style(true))
			btn.add_theme_stylebox_override("disabled", _bag_slot_style(true))
			btn.add_theme_stylebox_override("focus",    _bag_slot_style(true))
			btn.text = (item.get("name", "?") as String).left(2)
			btn.tooltip_text = "%s\n%s" % [item.get("name", ""), item.get("effect_desc", "")]
			btn.pressed.connect(_on_use_item.bind(idx))
		else:
			var empty_style := _bag_slot_style(false)
			btn.add_theme_stylebox_override("normal",   empty_style)
			btn.add_theme_stylebox_override("hover",    empty_style)
			btn.add_theme_stylebox_override("pressed",  empty_style)
			btn.add_theme_stylebox_override("disabled", empty_style)
			btn.add_theme_stylebox_override("focus",    empty_style)
			btn.text = ""
			btn.disabled = true
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_bag_slots.add_child(btn)

	# 第一页不显示左箭头；当前页能容下所有物品时不显示右箭头
	_bag_prev.visible = (_bag_page > 0)
	_bag_next.visible = ((_bag_page + 1) * SLOTS_PER_PAGE < items.size())


func _bag_slot_style(filled: bool, hovered: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.corner_radius_top_left    = 22
	s.corner_radius_top_right   = 22
	s.corner_radius_bottom_left = 22
	s.corner_radius_bottom_right = 22
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	if filled:
		s.bg_color     = Color(0.28, 0.22, 0.10, 0.9) if not hovered else Color(0.38, 0.30, 0.14, 0.95)
		s.border_color = Color(0.82, 0.70, 0.28, 0.95)
	else:
		s.bg_color     = Color(0.08, 0.08, 0.08, 0.45)
		s.border_color = Color(0.45, 0.40, 0.28, 0.35)
	return s


func _on_bag_prev() -> void:
	_bag_page = maxi(0, _bag_page - 1)
	_refresh_bag()


func _on_bag_next() -> void:
	_bag_page += 1
	_refresh_bag()


func _on_use_item(idx: int) -> void:
	GameState.remove_consumable(idx)
	var max_page := maxi(0, ceili(float(GameState.consumables.size()) / SLOTS_PER_PAGE) - 1)
	_bag_page = mini(_bag_page, max_page)
	_refresh_bag()


# ── 宝物栏 ───────────────────────────────────────────────────────

func _refresh_artifacts() -> void:
	for c in _art_slots.get_children():
		c.queue_free()

	var arts: Array = GameState.artifacts
	var start := _art_page * ART_PER_PAGE
	var count := mini(ART_PER_PAGE, arts.size() - start)

	for i in range(count):
		var art: Dictionary = arts[start + i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(36, 36)
		btn.add_theme_font_size_override("font_size", 10)
		btn.focus_mode = Control.FOCUS_NONE
		var rarity: String = art.get("rarity", "yellow")
		btn.add_theme_stylebox_override("normal",  _art_slot_style(rarity))
		btn.add_theme_stylebox_override("hover",   _art_slot_style(rarity, true))
		btn.add_theme_stylebox_override("pressed", _art_slot_style(rarity))
		btn.add_theme_stylebox_override("focus",   _art_slot_style(rarity))
		btn.text = (art.get("name", "?") as String).left(2)
		btn.tooltip_text = "[%s] %s\n%s" % [
			art.get("type", "passive"), art.get("name", ""), art.get("effect_desc", "")
		]
		_art_slots.add_child(btn)

	_art_prev.visible = (_art_page > 0)
	_art_next.visible = ((_art_page + 1) * ART_PER_PAGE < arts.size())


func _art_slot_style(rarity: String, hovered: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.corner_radius_top_left    = 5
	s.corner_radius_top_right   = 5
	s.corner_radius_bottom_left = 5
	s.corner_radius_bottom_right = 5
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	var bg: Color
	var border: Color
	match rarity:
		"mystique":
			bg     = Color(0.15, 0.12, 0.30, 0.9)
			border = Color(0.60, 0.50, 0.90, 0.9)
		"earth":
			bg     = Color(0.10, 0.22, 0.10, 0.9)
			border = Color(0.30, 0.75, 0.30, 0.9)
		"heaven":
			bg     = Color(0.25, 0.08, 0.08, 0.9)
			border = Color(0.90, 0.30, 0.20, 0.9)
		_:  # yellow
			bg     = Color(0.25, 0.20, 0.08, 0.9)
			border = Color(0.80, 0.68, 0.22, 0.9)
	if hovered:
		bg = Color(bg.r + 0.08, bg.g + 0.08, bg.b + 0.05, bg.a)
	s.bg_color     = bg
	s.border_color = border
	return s


func _on_art_prev() -> void:
	_art_page = maxi(0, _art_page - 1)
	_refresh_artifacts()


func _on_art_next() -> void:
	_art_page += 1
	_refresh_artifacts()


# ── 测试模式开关 ──────────────────────────────────────────────────

func _build_test_mode_toggle() -> void:
	var toggle := CheckBox.new()
	toggle.text = "[DEV] 自由移动"
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.button_pressed = false
	toggle.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	toggle.offset_left   = -170.0
	toggle.offset_top    = -34.0
	toggle.offset_right  = -6.0
	toggle.offset_bottom = -6.0
	toggle.z_index = 50
	toggle.add_theme_font_size_override("font_size", 13)
	toggle.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	toggle.toggled.connect(_on_test_mode_toggled)
	add_child(toggle)


func _on_test_mode_toggled(pressed: bool) -> void:
	_test_mode = pressed
	_update_node_visuals()


func _on_menu_abandon_confirmed() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_menu_return_confirmed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


# ── 入场演出 ──────────────────────────────────────────────────────

func _play_intro_animation() -> void:
	_intro_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_intro_label, "modulate:a", 1.0, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.6)
	tw.tween_property(_intro_label, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	tw.tween_callback(_intro_overlay.hide)
