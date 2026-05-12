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
var dao_xing_battle_start: int = 0 # 事件获得的跨战斗道行加成

# ── 灵石（局内货币）─────────────────────────────────────────────
var spirit_stones: int = 0

# ── 背包（丹药/符箓/阵法，共享上限）──────────────────────────────
const BAG_CAPACITY: int = 10
var consumables: Array = []  # 每项：{id, name, type, effect_desc}

# ── 宝物（Artifact，无上限，独立于背包）──────────────────────────
var artifacts: Array = []  # 每项：{id, name, rarity, type, effect_desc, flavor, active_used}

# ── 黑市/物品状态 ───────────────────────────────────────────────
var active_formation_id: String = ""
var shop_remove_service_uses: int = 0

# ── 新地图系统 ─────────────────────────────────────────────────────
var map_nodes: Dictionary = {}          # node_id -> node_dict
var map_floors: Array = []              # floors[i] = [node_id, ...]
var map_current_floor: int = 0          # 当前所在层（0表示未开始）
var map_accessible_ids: Array[String] = []  # 当前可点击的节点id
var map_last_node_id: String = ""       # 上一个访问的节点id
var map_started: bool = false           # 是否已经过起始节点进入地图
var map_intro_played: bool = false       # 当前 run 是否已播放过重天标题入场动画
var pending_battle_node_type: String = ""   # 即将进入的战斗节点类型
var pending_battle_node_floor: int = 0      # 即将进入的战斗节点层数

# ── 奇遇事件追踪 ──────────────────────────────────────────────────
var pending_event_id: String = ""          # 即将进入的事件 id
var visited_events: Array[String] = []     # 已触发的事件（同局不重复）
var event_chain_flags: Dictionary = {}     # 连锁任务标记，如 {"Q210_accepted": true}
var event_battle_enemy_id: String = ""     # 事件战斗专用的敌人 id


func start_run(char_id: String) -> void:
	character = CharacterDatabase.get_character(char_id)
	current_hp = character["hp_max"]
	deck = CardDatabase.get_starting_deck_ids()
	ling_li_regen_bonus = 0
	spirit_stones = 100
	consumables.clear()
	artifacts.clear()
	active_formation_id = ""
	shop_remove_service_uses = 0
	dao_xing_battle_start = 0
	
	# 生成新地图
	var map_data: Dictionary = _MapGenerator.generate()
	map_nodes = map_data["nodes"]
	map_floors = map_data["floors"]
	map_current_floor = 0
	map_last_node_id = ""
	map_started = false
	map_intro_played = false
	pending_battle_node_type = ""
	pending_battle_node_floor = 0
	pending_event_id = ""
	visited_events.clear()
	event_chain_flags.clear()
	event_battle_enemy_id = ""
	# 初始不解锁任何节点——等玩家点击起始节点后再开放第1层
	map_accessible_ids.clear()
	Log.info("GameState", "新局开始：%s  HP=%d  地图层数=%d" % [character["name"], current_hp, map_floors.size()])


func reset_run() -> void:
	character = {}
	current_hp = 0
	deck.clear()
	ling_li_regen_bonus = 0
	spirit_stones = 0
	consumables.clear()
	artifacts.clear()
	active_formation_id = ""
	shop_remove_service_uses = 0
	map_nodes = {}
	map_floors = []
	map_current_floor = 0
	map_accessible_ids.clear()
	map_last_node_id = ""
	map_started = false
	map_intro_played = false
	pending_battle_node_type = ""
	pending_battle_node_floor = 0
	pending_event_id = ""
	visited_events.clear()
	event_chain_flags.clear()
	event_battle_enemy_id = ""
	Log.info("GameState", "已放弃本局，数据已清除")


func get_ling_li_regen() -> int:
	return character.get("ling_li_regen", 3) + ling_li_regen_bonus


func get_hp_regen() -> int:
	return int(character.get("hp_regen", 0))


func on_battle_won() -> void:
	var healed := apply_map_node_hp_regen("战斗胜利")
	Log.info("GameState", "战斗胜利，HP剩余 %d，节点回复 +%d" % [current_hp, healed])


func apply_map_node_hp_regen(reason: String = "经过节点") -> int:
	var before := current_hp
	apply_hp_change(get_hp_regen())
	var healed := current_hp - before
	if healed > 0:
		Log.info("GameState", "%s：生命回复 +%d → %d/%d" % [
			reason,
			healed,
			current_hp,
			character.get("hp_max", 60),
		])
	return healed


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
	pending_battle_node_type = nd["type"]
	pending_battle_node_floor = int(nd["floor"])

	if not ["normal", "elite", "boss"].has(str(nd["type"])):
		apply_map_node_hp_regen("经过%s节点" % str(nd["type"]))

	# 更新下一层可访问节点
	map_accessible_ids.clear()
	for next_id in nd["next_ids"]:
		map_accessible_ids.append(next_id)

	Log.info("GameState", "访问节点 %s（类型=%s 层=%d）" % [node_id, nd["type"], map_current_floor])


## 玩家点击起始节点确认后调用：解锁第1层所有节点
func start_map() -> void:
	map_started = true
	map_accessible_ids.clear()
	if map_floors.size() > 0:
		for nid in map_floors[0]:
			map_accessible_ids.append(nid)
	Log.info("GameState", "起始节点已确认，第1层已解锁")


## 获取节点数据（安全拷贝）
func get_map_node(node_id: String) -> Dictionary:
	if map_nodes.has(node_id):
		return map_nodes[node_id].duplicate(false)
	return {}


func add_artifact(item: Dictionary) -> void:
	artifacts.append(item)


func remove_artifact(index: int) -> void:
	if index >= 0 and index < artifacts.size():
		artifacts.remove_at(index)


func add_consumable(item: Dictionary) -> bool:
	if consumables.size() >= BAG_CAPACITY:
		return false
	consumables.append(item)
	return true


func remove_consumable(index: int) -> void:
	if index >= 0 and index < consumables.size():
		consumables.remove_at(index)


func add_spirit_stones(amount: int) -> void:
	spirit_stones += amount
	Log.info("GameState", "获得 %d 灵石，现有 %d" % [amount, spirit_stones])


func spend_spirit_stones(cost: int) -> bool:
	if cost < 0 or spirit_stones < cost:
		return false
	spirit_stones -= cost
	Log.info("GameState", "花费 %d 灵石，现有 %d" % [cost, spirit_stones])
	return true


func buy_shop_card(card_id: String, price: int) -> bool:
	if not spend_spirit_stones(price):
		return false
	deck.append(card_id)
	Log.info("GameState", "黑市购买卡牌：%s" % card_id)
	return true


func buy_shop_item(item: Dictionary, price: int) -> bool:
	if consumables.size() >= BAG_CAPACITY:
		return false
	if not spend_spirit_stones(price):
		return false
	consumables.append(item.duplicate(true))
	Log.info("GameState", "黑市购买物品：%s" % item.get("name", item.get("id", "")))
	return true


func buy_shop_artifact(artifact: Dictionary, price: int) -> bool:
	for owned in artifacts:
		if owned.get("id", "") == artifact.get("id", ""):
			return false
	if not spend_spirit_stones(price):
		return false
	var item := artifact.duplicate(true)
	item["active_used"] = false
	artifacts.append(item)
	Log.info("GameState", "黑市购买宝物：%s" % artifact.get("name", artifact.get("id", "")))
	return true


func remove_deck_card_at(index: int, price: int) -> bool:
	if index < 0 or index >= deck.size() or deck.size() <= 1:
		return false
	if not spend_spirit_stones(price):
		return false
	var removed := deck[index]
	deck.remove_at(index)
	shop_remove_service_uses += 1
	Log.info("GameState", "黑市删除卡牌：%s" % removed)
	return true


func upgrade_deck_card_at(index: int, price: int) -> bool:
	if index < 0 or index >= deck.size():
		return false
	var card_id := deck[index]
	if card_id.ends_with("+"):
		return false
	if not spend_spirit_stones(price):
		return false
	deck[index] = card_id + "+"
	Log.info("GameState", "黑市升级卡牌：%s+" % card_id)
	return true


func use_consumable(index: int, context: String = "map") -> Dictionary:
	if index < 0 or index >= consumables.size():
		return {"ok": false, "message": "物品不存在。"}
	var item: Dictionary = consumables[index]
	var category := str(item.get("category", ""))
	if category == "formation":
		active_formation_id = str(item.get("id", ""))
		return {"ok": true, "message": "已激活阵法：%s" % item.get("name", active_formation_id)}
	if category == "talisman":
		return {"ok": false, "message": "符箓将在战斗中开放使用。"}
	if category != "elixir" or context != "map":
		return {"ok": false, "message": "当前场景无法使用该物品。"}

	_apply_elixir_effect(item)
	consumables.remove_at(index)
	return {"ok": true, "message": "已使用：%s" % item.get("name", "丹药")}


func _apply_elixir_effect(item: Dictionary) -> void:
	var effect := str(item.get("effect", ""))
	var amount := int(item.get("amount", 0))
	match effect:
		"heal":
			apply_hp_change(amount)
		"max_hp":
			var hp_max := int(character.get("hp_max", 60)) + amount
			character["hp_max"] = hp_max
			current_hp = mini(current_hp + amount, hp_max)
		"hp_regen":
			character["hp_regen"] = int(character.get("hp_regen", 0)) + amount
		"ling_li_regen":
			ling_li_regen_bonus += amount
		"dual_regen":
			character["hp_regen"] = int(character.get("hp_regen", 0)) + amount
			ling_li_regen_bonus += amount
		_:
			apply_hp_change(0)

# --- 辅助方法 ---

func has_artifact(art_id: String) -> bool:
	for a in artifacts:
		if str(a.get("id", "")) == art_id:
			return true
	return false

func get_shop_discount_pct() -> float:
	if has_artifact("R-S03"):
		return 0.15
	return 0.0
