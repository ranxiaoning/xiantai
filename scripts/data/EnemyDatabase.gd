## EnemyDatabase.gd  (Autoload: EnemyDatabase)
extends Node

## 意图类型
enum IntentType { ATTACK, DEFEND, BUFF, DEBUFF, UNKNOWN }

## M-101 疯修·残躯（普通敌人）
const M101_FENG_XIU := {
	"id": "m101_feng_xiu",
	"name": "疯修·残躯",
	"lore": "被剥夺修为后精神崩溃的低阶修士",
	"hp": 28,
	"hu_ti": 0,
	"actions": [
		{
			"name": "撕咬",
			"intent_type": IntentType.ATTACK,
			"intent_text": "撕咬 · 5伤害",
			"type": "attack",
			"damage": 5,
		},
		{
			"name": "疯扑",
			"intent_type": IntentType.ATTACK,
			"intent_text": "疯扑 · 8伤害",
			"type": "attack",
			"damage": 8,
		},
	],
	"action_cycle": [0, 1],  # 按索引循环
}

## M-201 镇境修罗（精英敌人）
const M201_ZHEN_JING := {
	"id": "m201_zhen_jing",
	"name": "镇境修罗",
	"lore": "守护登仙台中层的精英战灵，身着玄铁战甲",
	"hp": 45,
	"hu_ti": 0,
	"actions": [
		{
			"name": "震地斩",
			"intent_type": IntentType.ATTACK,
			"intent_text": "震地斩 · 10伤害",
			"type": "attack",
			"damage": 10,
		},
		{
			"name": "铁甲强化",
			"intent_type": IntentType.DEFEND,
			"intent_text": "铁甲强化 · 格挡8",
			"type": "defend",
			"shield": 8,
		},
		{
			"name": "裂地重击",
			"intent_type": IntentType.ATTACK,
			"intent_text": "裂地重击 · 14伤害",
			"type": "attack",
			"damage": 14,
		},
	],
	"action_cycle": [0, 1, 2, 0],
}

## Boss 剥皮仙君（第16层Boss）
const BOSS_BO_PI := {
	"id": "boss_bo_pi",
	"name": "剥皮仙君",
	"lore": "登仙台第一重天的守门者，将无数修士的修为剥夺殆尽",
	"hp": 80,
	"hu_ti": 0,
	"actions": [
		{
			"name": "蓄力",
			"intent_type": IntentType.BUFF,
			"intent_text": "蓄力 · 准备重击",
			"type": "buff",
			"damage": 0,
		},
		{
			"name": "天罚重击",
			"intent_type": IntentType.ATTACK,
			"intent_text": "天罚重击 · 18伤害",
			"type": "attack",
			"damage": 18,
		},
		{
			"name": "剥魂术",
			"intent_type": IntentType.DEBUFF,
			"intent_text": "剥魂术 · 干扰10伤害",
			"type": "attack",
			"damage": 10,
		},
		{
			"name": "神域护盾",
			"intent_type": IntentType.DEFEND,
			"intent_text": "神域护盾 · 格挡15",
			"type": "defend",
			"shield": 15,
		},
	],
	"action_cycle": [0, 1, 2, 3],  # 蓄力→重击→干扰→防御 循环
}

var _all: Dictionary = {}

func _ready() -> void:
	_all[M101_FENG_XIU["id"]] = M101_FENG_XIU
	_all[M201_ZHEN_JING["id"]] = M201_ZHEN_JING
	_all[BOSS_BO_PI["id"]] = BOSS_BO_PI


func get_enemy(id: String) -> Dictionary:
	return _all.get(id, {}).duplicate(true)


## 根据节点类型和层数返回敌人数据
func get_enemy_for_node(node_type: String, floor: int) -> Dictionary:
	if node_type == "boss":
		return get_enemy("boss_bo_pi")
	if node_type == "elite":
		return get_enemy("m201_zhen_jing")
	# 普通战斗，后续可根据floor选不同敌人
	return get_enemy("m101_feng_xiu")


## 兼容旧接口（BattleScene.gd 使用）
func get_battle_node_enemy(_node_id: String) -> Dictionary:
	var ntype: String = GameState.pending_battle_node_type
	var nfloor: int   = GameState.pending_battle_node_floor
	if ntype.is_empty():
		ntype = "normal"
	return get_enemy_for_node(ntype, nfloor)
