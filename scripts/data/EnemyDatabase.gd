## EnemyDatabase.gd  (Autoload: EnemyDatabase)
extends Node

## 意图类型
enum IntentType { ATTACK, DEFEND, BUFF, DEBUFF, UNKNOWN }

## M-101 疯修·残躯
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

var _all: Dictionary = {}

func _ready() -> void:
	_all[M101_FENG_XIU["id"]] = M101_FENG_XIU


func get_enemy(id: String) -> Dictionary:
	return _all.get(id, {}).duplicate(true)


func get_battle_node_enemy(_node_id: String) -> Dictionary:
	## 目前只有一种敌人，后续根据节点id分配
	return get_enemy("m101_feng_xiu")
