## CardDatabase.gd  (Autoload: CardDatabase)
## 所有卡牌的静态数据定义。
## 字段说明：
##   id          唯一标识（snake_case）
##   name        显示名
##   rarity      稀有度 "黄"/"玄"/"地"/"天"
##   ling_li     灵力消耗
##   dao_hui     道慧消耗
##   card_type   "attack" / "skill" / "power"
##   keywords    Array[String]  e.g. ["exhaust","ethereal"]
##   desc        效果文字（未升级）
##   desc_up     效果文字（升级后）
extends Node

## ── 初始牌组 ──────────────────────────────────────────────────────

const QUICK_SWORD_PI_SHAN := {
	"id": "quick_sword_pi_shan", "name": "快剑·劈山",
	"rarity": "黄", "ling_li": 0, "dao_hui": 2,
	"card_type": "attack", "keywords": [],
	"base_damage": 6, "base_damage_up": 9,
	"desc": "造成 6 点伤害。", "desc_up": "造成 9 点伤害。",
}

const DING_XIN_ZHOU := {
	"id": "ding_xin_zhou", "name": "定心咒",
	"rarity": "黄", "ling_li": 1, "dao_hui": 2,
	"card_type": "skill", "keywords": [],
	"base_shield": 6, "base_shield_up": 10,
	"desc": "获得 6 点护体。", "desc_up": "获得 10 点护体。",
}

## ── 扩展池（可在奖励阶段抽取）────────────────────────────────────

const LING_JIAN_DIAN_XING := {
	"id": "ling_jian_dian_xing", "name": "灵剑·点星",
	"rarity": "黄", "ling_li": 2, "dao_hui": 2,
	"card_type": "attack", "keywords": [],
	"base_damage": 10, "base_damage_up": 14, "extra_draw": 1,
	"desc": "造成 10 点伤害，抽取 1 张牌。",
	"desc_up": "造成 14 点伤害，抽取 1 张牌。",
}

const DING_QI_CENG := {
	"id": "ding_qi_ceng", "name": "凝气层",
	"rarity": "黄", "ling_li": 0, "dao_hui": 3,
	"card_type": "skill", "keywords": [],
	"base_shield": 8, "base_shield_up": 12, "bonus_ling_li": 3,
	"desc": "获得 8 点护体，3 点灵力。",
	"desc_up": "获得 12 点护体，4 点灵力。",
}

const ZHONG_JIAN_BENG_JIA := {
	"id": "zhong_jian_beng_jia", "name": "重剑·崩甲",
	"rarity": "黄", "ling_li": 0, "dao_hui": 4,
	"card_type": "attack", "keywords": [],
	"base_damage": 15, "base_damage_up": 20, "bonus_vs_shield": 8,
	"desc": "造成 15 点伤害。若目标有护体，额外造成 8 点伤害。",
	"desc_up": "造成 20 点伤害。若目标有护体，额外造成 12 点伤害。",
}

## ── 索引 ──────────────────────────────────────────────────────────

var _all: Dictionary = {}

func _ready() -> void:
	for card in [
		QUICK_SWORD_PI_SHAN, DING_XIN_ZHOU,
		LING_JIAN_DIAN_XING, DING_QI_CENG, ZHONG_JIAN_BENG_JIA,
	]:
		_all[card["id"]] = card


func get_card(id: String) -> Dictionary:
	if _all.has(id):
		return _all[id].duplicate()
	push_error("CardDatabase: 未知卡牌 id = " + id)
	return {}


func get_starting_deck_ids() -> Array[String]:
	## 程天锋初始牌组：快剑·劈山×10 + 定心咒×10
	var deck: Array[String] = []
	for _i in range(10):
		deck.append("quick_sword_pi_shan")
	for _i in range(10):
		deck.append("ding_xin_zhou")
	return deck
