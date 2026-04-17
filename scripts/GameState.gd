## GameState.gd  (Autoload: GameState)
## 保存整局 run 的状态，在场景切换间持久存在。
extends Node

# ── 角色 ──────────────────────────────────────────────────────────
var character: Dictionary = {}

# ── 当前生命值 ────────────────────────────────────────────────────
var current_hp: int = 0

# ── 牌组（卡牌 id 列表，反映当前构筑）────────────────────────────
var deck: Array[String] = []

# ── 跨战斗的永久增益 ──────────────────────────────────────────────
var ling_li_regen_bonus: int = 0   # 引灵归元叠加
var dao_xing_battle_start: int = 0 # 威名远播等跨战斗道行加成

# ── 地图进度 ──────────────────────────────────────────────────────
var spawn_node_visited: bool = false
var pending_battle_node: String = ""  # 即将进入的战斗节点 id


func start_run(char_id: String) -> void:
	character = CharacterDatabase.get_character(char_id)
	current_hp = character["hp_max"]
	deck = CardDatabase.get_starting_deck_ids()
	ling_li_regen_bonus = 0
	dao_xing_battle_start = character.get("talent_dao_xing", 0)
	spawn_node_visited = false
	pending_battle_node = ""
	Log.info("GameState", "新局开始：%s  HP=%d" % [character["name"], current_hp])


func get_ling_li_regen() -> int:
	return character.get("ling_li_regen", 3) + ling_li_regen_bonus


func on_battle_won() -> void:
	Log.info("GameState", "战斗胜利，HP剩余 %d" % current_hp)


func apply_hp_change(delta: int) -> void:
	current_hp = clampi(current_hp + delta, 0, character.get("hp_max", 60))
