## GameState.gd  (Autoload: GameState)
## 保存整局 run 的状态，在场景切换间持久存在。
extends Node

const _MapGenerator = preload("res://scripts/MapGenerator.gd")

# ── 角色 ──────────────────────────────────────────────────────────
var character: Dictionary = {}

# ── 当前生命值 ────────────────────────────────────────────────────
var current_hp: int = 0

# ── 牌组（卡牌 id 列表，反映当前构筑）────────────────────────────
var deck: Array[String] = []

# ── 跨战斗的永久增益 ──────────────────────────────────────────────
var ling_li_regen_bonus: int = 0   # 引灵归元叠加
var dao_xing_battle_start: int = 0 # 威名远播等跨战斗道行加成

# ── 地图进度（旧版，兼容保留）──────────────────────────────────────
var spawn_node_visited: bool = false
var pending_battle_node: String = ""  # 即将进入的战斗节点 id

# ── 新地图系统 ─────────────────────────────────────────────────────
var map_nodes: Dictionary = {}          # node_id -> node_dict
var map_floors: Array = []              # floors[i] = [node_id, ...]
var map_current_floor: int = 0          # 当前所在层（0表示未开始）
var map_accessible_ids: Array[String] = []  # 当前可点击的节点id
var map_last_node_id: String = ""       # 上一个访问的节点id
var pending_battle_node_type: String = ""   # 即将进入的战斗节点类型
var pending_battle_node_floor: int = 0      # 即将进入的战斗节点层数


func start_run(char_id: String) -> void:
	character = CharacterDatabase.get_character(char_id)
	current_hp = character["hp_max"]
	deck = CardDatabase.get_starting_deck_ids()
	ling_li_regen_bonus = 0
	dao_xing_battle_start = character.get("talent_dao_xing", 0)
	spawn_node_visited = false
	pending_battle_node = ""
	# 生成新地图
	var map_data: Dictionary = _MapGenerator.generate()
	map_nodes = map_data["nodes"]
	map_floors = map_data["floors"]
	map_current_floor = 0
	map_last_node_id = ""
	pending_battle_node_type = ""
	pending_battle_node_floor = 0
	# 初始可访问节点 = 第1层所有节点
	map_accessible_ids.clear()
	if map_floors.size() > 0:
		for nid in map_floors[0]:
			map_accessible_ids.append(nid)
	Log.info("GameState", "新局开始：%s  HP=%d  地图层数=%d" % [character["name"], current_hp, map_floors.size()])


func get_ling_li_regen() -> int:
	return character.get("ling_li_regen", 3) + ling_li_regen_bonus


func on_battle_won() -> void:
	Log.info("GameState", "战斗胜利，HP剩余 %d" % current_hp)


func apply_hp_change(delta: int) -> void:
	current_hp = clampi(current_hp + delta, 0, character.get("hp_max", 60))


## 访问地图节点：标记已访问、推进楼层、更新可访问列表
func visit_map_node(node_id: String) -> void:
	if not map_nodes.has(node_id):
		push_warning("GameState.visit_map_node: 未知节点 %s" % node_id)
		return
	var nd: Dictionary = map_nodes[node_id]
	nd["visited"] = true
	map_last_node_id = node_id
	map_current_floor = int(nd["floor"])
	pending_battle_node = node_id
	pending_battle_node_type = nd["type"]
	pending_battle_node_floor = int(nd["floor"])

	# 更新下一层可访问节点
	map_accessible_ids.clear()
	for next_id in nd["next_ids"]:
		map_accessible_ids.append(next_id)

	Log.info("GameState", "访问节点 %s（类型=%s 层=%d）" % [node_id, nd["type"], map_current_floor])


## 获取节点数据（安全拷贝）
func get_map_node(node_id: String) -> Dictionary:
	if map_nodes.has(node_id):
		return map_nodes[node_id].duplicate(false)
	return {}
