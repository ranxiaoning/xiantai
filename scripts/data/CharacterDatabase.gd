## CharacterDatabase.gd  (Autoload: CharacterDatabase)
extends Node

## 门派注册表：控制显示顺序，未来可在此扩展锁定/解锁状态
const SECTS := {
	"万剑门": {
		"name": "万剑门",
		"bg_path": "res://assets/bg/wanjianmen.png",
	},
}

const SECT_ORDER: Array = ["万剑门"]

const CHEN_TIAN_FENG := {
	"id": "chen_tian_feng",
	"name": "程天锋",
	"sect": "万剑门",
	"title": "剑修·入境",
	"lore": "万剑门末代传人，一身剑道不曾磨灭。\n登上仙台，只为找回那被天宫夺走的一切。",
	"portrait_path": "res://assets/portraits/chen_tianfeng.png",

	# ── 战斗属性 ──
	"hp_max":         60,
	"hp_regen":        5,
	"ling_li_max":    20,
	"ling_li_regen":   3,
	"dao_hui_max":     6,
	"damage_mult":   1.1,

	# ── 天赋 ──
	"talent_name":    "剑道之基",
	"talent_desc":    "战斗开始时获得 1 层【道行】。",
	"talent_dao_xing": 1,

	# ── 英雄技能 ──
	"skill_name":     "剑意凝神",
	"skill_desc":     "消耗 6 点道慧，获得 1 层【道行】。",
	"skill_dao_hui_cost": 6,
	"skill_dao_xing_gain": 1,
}

var _all: Dictionary = {}

func _ready() -> void:
	_ensure_loaded()


func _ensure_loaded() -> void:
	if not _all.is_empty():
		return
	_all[CHEN_TIAN_FENG["id"]] = CHEN_TIAN_FENG


func get_character(id: String) -> Dictionary:
	_ensure_loaded()
	return _all.get(id, {}).duplicate()


func get_sect_characters(sect: String) -> Array:
	_ensure_loaded()
	var result := []
	for c in _all.values():
		if c["sect"] == sect:
			result.append(c.duplicate())
	return result


## 返回门派名称列表（按 SECT_ORDER 顺序）
func get_all_sects() -> Array:
	return SECT_ORDER.duplicate()


## 返回门派元数据（bg_path 等）
func get_sect_data(sect: String) -> Dictionary:
	return SECTS.get(sect, {}).duplicate()
