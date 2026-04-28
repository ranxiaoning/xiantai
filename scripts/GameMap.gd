## GameMap.gd
## 16层动态地图场景控制器
extends Control

const BATTLE_SCENE    := "res://scenes/Battle.tscn"
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

# ── 布局常量 ───────────────────────────────────────────────────────
const FLOOR_COUNT    := 16
const FLOOR_SPACING  := 90      # 层间y距离（像素），增大给图片留出空间
const MAP_H_PADDING  := 40      # 顶部/底部 padding
const MAP_W          := 1280    # 地图容器宽度
const NODE_W         := 72      # 节点图片宽（正方形适合圆形徽章）
const NODE_H         := 72
const COL_SPACING    := 240.0

# 总地图高度
const MAP_TOTAL_H := (FLOOR_COUNT - 1) * FLOOR_SPACING + MAP_H_PADDING * 2

# 节点颜色（通过 modulate 控制可访问/已访问/未到达状态）
const COLOR_ACCESSIBLE := Color(1.0,  1.0,  1.0,  1.0)   # 亮白可点击
const COLOR_VISITED    := Color(0.4,  0.4,  0.4,  0.85)  # 灰暗已访问
const COLOR_FUTURE     := Color(0.6,  0.6,  0.65, 0.55)  # 半透明灰未到达
const COLOR_DARK       := Color(0.3,  0.3,  0.3,  0.4)   # 暗（不可达）

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
var _draw_layer: Control = null        # MapDrawLayer 实例
var _node_buttons: Dictionary = {}     # node_id -> Button
var _pending_node_id: String = ""      # 当前弹窗对应的节点id


func _ready() -> void:
	MusicManager.play("map")
	node_popup.hide()
	victory_panel.hide()

	# 确保 GameState 有地图数据
	if GameState.map_floors.is_empty():
		GameState.start_run("chen_tian_feng")  # 兜底：正常从 CharacterSelect 传入

	_build_map()
	_update_hp_label()

	# 等一帧后滚动到当前层
	await get_tree().process_frame
	_scroll_to_current_floor()

	# 若已完成所有层，显示胜利面板
	if GameState.map_current_floor > FLOOR_COUNT:
		_show_victory()

	Log.info("GameMap", "地图加载完成，当前层=%d" % GameState.map_current_floor)


# ── 构建地图 ──────────────────────────────────────────────────────

func _build_map() -> void:
	# 清除旧内容
	for child in map_container.get_children():
		child.queue_free()
	_node_buttons.clear()

	# 设置容器高度
	map_container.custom_minimum_size = Vector2(MAP_W, MAP_TOTAL_H)

	# 创建绘制层
	_draw_layer = load("res://scripts/MapDrawLayer.gd").new()
	_draw_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_container.add_child(_draw_layer)

	var nodes: Dictionary = GameState.map_nodes
	var floors: Array     = GameState.map_floors

	# 先绘制连线（在按钮下方）
	for node_id in nodes:
		var nd: Dictionary = nodes[node_id]
		var src := _node_center(int(nd["floor"]), int(nd["col"]), int(nd["total_cols"]))
		for next_id in nd["next_ids"]:
			if nodes.has(next_id):
				var nnd: Dictionary = nodes[next_id]
				var dst := _node_center(int(nnd["floor"]), int(nnd["col"]), int(nnd["total_cols"]))
				_draw_layer.add_line(src, dst, bool(nd["visited"]))
	_draw_layer.refresh()

	# 创建节点按钮
	for node_id in nodes:
		var nd: Dictionary = nodes[node_id]
		_create_node_button(node_id, nd)

	_update_node_visuals()


## 加载贴图：优先走已导入缓存；降级时用 FileAccess 读 res:// 字节流，
## 逐格式尝试解码（避免绝对路径中文问题，也兼容 WebP/JPG 改名为 .png 的情况）
func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex:
			return tex
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("GameMap: 无法打开 %s" % path)
		return null
	var data := file.get_buffer(file.get_length())
	file.close()
	var img := Image.new()
	if img.load_png_from_buffer(data) == OK \
	or img.load_webp_from_buffer(data) == OK \
	or img.load_jpg_from_buffer(data) == OK:
		return ImageTexture.create_from_image(img)
	push_warning("GameMap: 不支持的图片格式 %s" % path)
	return null


func _create_node_button(node_id: String, nd: Dictionary) -> void:
	var btn := TextureButton.new()
	var ntype: String = nd["type"]
	var tex_path: String = NODE_TEXTURES.get(ntype, NODE_TEXTURES["normal"])
	btn.texture_normal = _load_texture(tex_path)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.custom_minimum_size = Vector2(NODE_W, NODE_H)
	btn.size = Vector2(NODE_W, NODE_H)

	var center := _node_center(int(nd["floor"]), int(nd["col"]), int(nd["total_cols"]))
	btn.position = center - Vector2(NODE_W * 0.5, NODE_H * 0.5)

	btn.pressed.connect(_on_node_btn_pressed.bind(node_id))
	map_container.add_child(btn)
	_node_buttons[node_id] = btn


# ── 节点坐标计算 ──────────────────────────────────────────────────

func _node_center(floor: int, col: int, total_cols: int) -> Vector2:
	var y := (FLOOR_COUNT - floor) * FLOOR_SPACING + MAP_H_PADDING
	var x := MAP_W / 2.0 + (col - (total_cols - 1) / 2.0) * COL_SPACING
	return Vector2(x, y)


# ── 节点视觉状态更新 ─────────────────────────────────────────────

func _update_node_visuals() -> void:
	var nodes: Dictionary       = GameState.map_nodes
	var accessible: Array[String] = GameState.map_accessible_ids

	for node_id in _node_buttons:
		var btn: BaseButton   = _node_buttons[node_id]
		var nd: Dictionary    = nodes[node_id]
		var visited: bool     = bool(nd["visited"])
		var is_accessible: bool = accessible.has(node_id)
		var floor: int        = int(nd["floor"])

		if visited:
			btn.modulate = COLOR_VISITED
			btn.disabled = true
		elif is_accessible:
			btn.modulate = COLOR_ACCESSIBLE
			btn.disabled = false
		elif floor <= GameState.map_current_floor:
			btn.modulate = COLOR_DARK
			btn.disabled = true
		else:
			btn.modulate = COLOR_FUTURE
			btn.disabled = true

	# 重绘连线（更新访问状态颜色）
	if _draw_layer:
		_draw_layer.clear_lines()
		var floors: Array = GameState.map_floors
		for node_id in nodes:
			var nd: Dictionary = nodes[node_id]
			var src := _node_center(int(nd["floor"]), int(nd["col"]), int(nd["total_cols"]))
			for next_id in nd["next_ids"]:
				if nodes.has(next_id):
					var nnd: Dictionary = nodes[next_id]
					var dst := _node_center(int(nnd["floor"]), int(nnd["col"]), int(nnd["total_cols"]))
					_draw_layer.add_line(src, dst, bool(nd["visited"]))
		_draw_layer.refresh()


func _update_hp_label() -> void:
	var hp_max: int = GameState.character.get("hp_max", 60)
	hp_label.text = "HP %d / %d" % [GameState.current_hp, hp_max]


# ── 滚动到当前层 ─────────────────────────────────────────────────

func _scroll_to_current_floor() -> void:
	# 滚动到「下一个可选层」(map_current_floor+1)，初始时 map_current_floor=0 → 定位到第1层
	var floor := clampi(GameState.map_current_floor + 1, 1, FLOOR_COUNT)
	var center_y := (FLOOR_COUNT - floor) * FLOOR_SPACING + MAP_H_PADDING
	# ScrollContainer 的 scroll_vertical 是容器内偏移量
	var viewport_h := map_scroll.size.y
	var target_scroll := int(center_y - viewport_h * 0.5)
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
