## ShopDatabase.gd  (Autoload: ShopDatabase)
## 黑市 V1 静态商品数据、价格表与库存生成。
extends Node

const CARD_PRICES := {"黄品": 50, "玄品": 80, "地品": 150, "天品": 300}
const UPGRADE_PRICES := {"黄品": 30, "玄品": 50, "地品": 80, "天品": 150}

const ITEMS := [
	{"id": "D-01", "name": "回春丹", "category": "elixir", "rarity": "yellow", "price": 30, "effect": "heal", "amount": 15, "min_floor": 1, "effect_desc": "地图使用：回复 15 点生命。"},
	{"id": "D-02", "name": "培元丹", "category": "elixir", "rarity": "yellow", "price": 45, "effect": "heal", "amount": 25, "min_floor": 1, "effect_desc": "地图使用：回复 25 点生命。"},
	{"id": "D-03", "name": "碎金丹", "category": "elixir", "rarity": "yellow", "price": 35, "effect": "heal", "amount": 18, "min_floor": 1, "effect_desc": "地图使用：回复 18 点生命。"},
	{"id": "D-04", "name": "静息丹", "category": "elixir", "rarity": "yellow", "price": 40, "effect": "hp_regen", "amount": 1, "min_floor": 1, "effect_desc": "地图使用：本局生命回复 +1。"},
	{"id": "D-05", "name": "小洗髓丹", "category": "elixir", "rarity": "yellow", "price": 55, "effect": "max_hp", "amount": 5, "min_floor": 1, "effect_desc": "地图使用：生命上限 +5，并回复 5 点生命。"},
	{"id": "D-06", "name": "醒神丹", "category": "elixir", "rarity": "yellow", "price": 45, "effect": "heal", "amount": 22, "min_floor": 1, "effect_desc": "地图使用：回复 22 点生命。"},
	{"id": "D-07", "name": "洗髓丹", "category": "elixir", "rarity": "mystique", "price": 80, "effect": "max_hp", "amount": 10, "min_floor": 6, "effect_desc": "地图使用：生命上限 +10，并回复 10 点生命。"},
	{"id": "D-08", "name": "悟道丹", "category": "elixir", "rarity": "mystique", "price": 70, "effect": "dao_xing", "amount": 1, "min_floor": 6, "effect_desc": "地图使用：后续战斗开局道行 +1。"},
	{"id": "D-09", "name": "凝元丹", "category": "elixir", "rarity": "mystique", "price": 75, "effect": "ling_li_regen", "amount": 1, "min_floor": 6, "effect_desc": "地图使用：本局灵力回复 +1。"},
	{"id": "D-10", "name": "护命丹", "category": "elixir", "rarity": "mystique", "price": 70, "effect": "heal", "amount": 35, "min_floor": 6, "effect_desc": "地图使用：回复 35 点生命。"},
	{"id": "D-11", "name": "玉骨丹", "category": "elixir", "rarity": "earth", "price": 120, "effect": "max_hp", "amount": 15, "min_floor": 11, "effect_desc": "地图使用：生命上限 +15，并回复 15 点生命。"},
	{"id": "D-12", "name": "逆元丹", "category": "elixir", "rarity": "earth", "price": 110, "effect": "ling_li_regen", "amount": 2, "min_floor": 11, "effect_desc": "地图使用：本局灵力回复 +2。"},
	{"id": "D-13", "name": "还魂丹", "category": "elixir", "rarity": "earth", "price": 130, "effect": "heal", "amount": 50, "min_floor": 11, "effect_desc": "地图使用：回复 50 点生命。"},
	{"id": "D-14", "name": "天道禁果", "category": "elixir", "rarity": "heaven", "price": 200, "effect": "max_hp", "amount": 20, "min_floor": 13, "effect_desc": "地图使用：生命上限 +20，并回复 20 点生命。"},
	{"id": "D-15", "name": "逆天仙露", "category": "elixir", "rarity": "heaven", "price": 250, "effect": "dual_regen", "amount": 1, "min_floor": 14, "effect_desc": "地图使用：生命回复 +1，灵力回复 +1。"},

	{"id": "T-01", "name": "火符·焚天", "category": "talisman", "rarity": "yellow", "price": 30, "effect": "battle_damage", "amount": 15, "min_floor": 1, "effect_desc": "战斗用：对单体造成 15 点伤害。"},
	{"id": "T-02", "name": "风符·逐云", "category": "talisman", "rarity": "yellow", "price": 35, "effect": "battle_draw", "amount": 2, "min_floor": 1, "effect_desc": "战斗用：抽 2 张牌。"},
	{"id": "T-03", "name": "雷符·震霆", "category": "talisman", "rarity": "yellow", "price": 40, "effect": "battle_aoe", "amount": 8, "min_floor": 1, "effect_desc": "战斗用：对所有敌人造成 8 点伤害。"},
	{"id": "T-04", "name": "镇符·定身", "category": "talisman", "rarity": "yellow", "price": 50, "effect": "battle_skip", "amount": 1, "min_floor": 1, "effect_desc": "战斗用：使敌人下次行动延后。"},
	{"id": "T-05", "name": "护符·金钟", "category": "talisman", "rarity": "yellow", "price": 45, "effect": "battle_block", "amount": 12, "min_floor": 1, "effect_desc": "战斗用：获得 12 点身形。"},
	{"id": "T-06", "name": "净符·涤秽", "category": "talisman", "rarity": "yellow", "price": 45, "effect": "battle_cleanse", "amount": 1, "min_floor": 1, "effect_desc": "战斗用：清除 1 个负面状态。"},
	{"id": "T-07", "name": "冰符·凝霜", "category": "talisman", "rarity": "mystique", "price": 75, "effect": "battle_debuff", "amount": 1, "min_floor": 6, "effect_desc": "战斗用：对敌人施加枯竭与震慑。"},
	{"id": "T-08", "name": "血符·回脉", "category": "talisman", "rarity": "mystique", "price": 80, "effect": "battle_lifesteal", "amount": 10, "min_floor": 6, "effect_desc": "战斗用：造成伤害并回复生命。"},
	{"id": "T-09", "name": "剑符·鸣锋", "category": "talisman", "rarity": "mystique", "price": 85, "effect": "battle_dao_xing", "amount": 2, "min_floor": 6, "effect_desc": "战斗用：获得 2 层道行。"},
	{"id": "T-10", "name": "遁符·无踪", "category": "talisman", "rarity": "mystique", "price": 90, "effect": "battle_evade", "amount": 1, "min_floor": 6, "effect_desc": "战斗用：免疫下一次伤害。"},
	{"id": "T-11", "name": "灭符·焚尽", "category": "talisman", "rarity": "earth", "price": 150, "effect": "battle_damage", "amount": 35, "min_floor": 11, "effect_desc": "战斗用：对单体造成 35 点伤害。"},
	{"id": "T-12", "name": "群雷符", "category": "talisman", "rarity": "earth", "price": 160, "effect": "battle_aoe", "amount": 18, "min_floor": 11, "effect_desc": "战斗用：对所有敌人造成 18 点伤害。"},
	{"id": "T-13", "name": "锁魂符", "category": "talisman", "rarity": "earth", "price": 170, "effect": "battle_skip", "amount": 2, "min_floor": 11, "effect_desc": "战斗用：封锁敌人行动。"},
	{"id": "T-14", "name": "天罚符", "category": "talisman", "rarity": "heaven", "price": 260, "effect": "battle_aoe", "amount": 30, "min_floor": 13, "effect_desc": "战斗用：对所有敌人造成 30 点伤害。"},
	{"id": "T-15", "name": "轮回符", "category": "talisman", "rarity": "heaven", "price": 280, "effect": "battle_save", "amount": 1, "min_floor": 14, "effect_desc": "战斗用：预置一次濒死保护。"},

	{"id": "F-01", "name": "聚气阵", "category": "formation", "rarity": "yellow", "price": 40, "effect": "battle_start_ling_li", "amount": 1, "min_floor": 1, "effect_desc": "激活：后续战斗第 1 回合额外获得 1 点灵力。"},
	{"id": "F-02", "name": "固本阵", "category": "formation", "rarity": "yellow", "price": 45, "effect": "battle_start_hu_ti", "amount": 4, "min_floor": 1, "effect_desc": "激活：后续战斗开始获得 4 点护体。"},
	{"id": "F-03", "name": "磨剑阵", "category": "formation", "rarity": "yellow", "price": 50, "effect": "battle_start_dao_xing", "amount": 1, "min_floor": 1, "effect_desc": "激活：后续战斗开始获得 1 层道行。"},
	{"id": "F-04", "name": "导灵阵", "category": "formation", "rarity": "yellow", "price": 55, "effect": "battle_draw", "amount": 1, "min_floor": 1, "effect_desc": "激活：后续战斗第 1 回合额外抽 1 张牌。"},
	{"id": "F-05", "name": "净心阵", "category": "formation", "rarity": "yellow", "price": 60, "effect": "battle_cleanse", "amount": 1, "min_floor": 1, "effect_desc": "激活：后续战斗开始净化 1 个负面状态。"},
	{"id": "F-06", "name": "回春阵", "category": "formation", "rarity": "mystique", "price": 80, "effect": "battle_regen", "amount": 3, "min_floor": 6, "effect_desc": "激活：每场战斗开始回复 3 点生命。"},
	{"id": "F-07", "name": "藏锋阵", "category": "formation", "rarity": "mystique", "price": 85, "effect": "battle_attack_bonus", "amount": 2, "min_floor": 6, "effect_desc": "激活：每场战斗第 1 张术法牌伤害 +2。"},
	{"id": "F-08", "name": "连环阵", "category": "formation", "rarity": "mystique", "price": 90, "effect": "battle_combo", "amount": 1, "min_floor": 6, "effect_desc": "激活：每场战斗第 3 张牌额外抽 1 张。"},
	{"id": "F-09", "name": "守一阵", "category": "formation", "rarity": "mystique", "price": 95, "effect": "battle_reduce", "amount": 3, "min_floor": 6, "effect_desc": "激活：每场战斗首次受伤 -3。"},
	{"id": "F-10", "name": "吞灵阵", "category": "formation", "rarity": "mystique", "price": 100, "effect": "battle_energy_bank", "amount": 1, "min_floor": 6, "effect_desc": "激活：战斗结束保留 1 点额外灵力。"},
	{"id": "F-11", "name": "万剑阵", "category": "formation", "rarity": "earth", "price": 140, "effect": "battle_start_dao_xing", "amount": 2, "min_floor": 11, "effect_desc": "激活：后续战斗开始获得 2 层道行。"},
	{"id": "F-12", "name": "玄龟阵", "category": "formation", "rarity": "earth", "price": 150, "effect": "battle_start_hu_ti", "amount": 10, "min_floor": 11, "effect_desc": "激活：后续战斗开始获得 10 点护体。"},
	{"id": "F-13", "name": "化血阵", "category": "formation", "rarity": "earth", "price": 160, "effect": "battle_lifesteal", "amount": 2, "min_floor": 11, "effect_desc": "激活：每场战斗首次击杀回复 2 点生命。"},
	{"id": "F-14", "name": "天门阵", "category": "formation", "rarity": "heaven", "price": 260, "effect": "battle_start_ling_li", "amount": 3, "min_floor": 13, "effect_desc": "激活：后续战斗第 1 回合额外获得 3 点灵力。"},
	{"id": "F-15", "name": "逆天阵", "category": "formation", "rarity": "heaven", "price": 300, "effect": "battle_start_dao_xing", "amount": 3, "min_floor": 14, "effect_desc": "激活：后续战斗开始获得 3 层道行。"},
]

const ARTIFACTS := [
	{"id": "R-01", "name": "残剑鞘", "rarity": "yellow", "type": "passive", "price": 60, "effect_desc": "每场战斗第 1 张术法牌后获得 2 点身形。", "flavor": "老旧剑鞘仍记得第一剑的锋芒。"},
	{"id": "R-02", "name": "铜甲残片", "rarity": "yellow", "type": "passive", "price": 65, "effect_desc": "每场战斗开始获得 5 点护体。", "flavor": "残缺的铜甲比许多人的尊严更坚硬。"},
	{"id": "R-03", "name": "聚灵珠", "rarity": "yellow", "type": "passive", "price": 70, "effect_desc": "每场战斗胜利后额外获得 8 灵石。", "flavor": "浑浊珠光会吸走战场上剩余的灵石残渣。"},
	{"id": "R-04", "name": "血玉环", "rarity": "yellow", "type": "passive", "price": 75, "effect_desc": "HP 低于 50% 时，术法牌伤害 +2。", "flavor": "危机越深，玉色越红。"},
	{"id": "R-05", "name": "寒铁护腕", "rarity": "yellow", "type": "passive", "price": 80, "effect_desc": "每回合首次受到伤害时，伤害 -3。", "flavor": "寒铁在受击瞬间凝出薄冰。"},
	{"id": "R-06", "name": "灵犀簪", "rarity": "yellow", "type": "passive", "price": 90, "effect_desc": "每场战斗初始手牌 +1。", "flavor": "灵识被簪尖轻轻挑开。"},
	{"id": "R-07", "name": "饮血剑穗", "rarity": "mystique", "type": "passive", "price": 110, "effect_desc": "术法牌造成伤害时，10% 概率回复 2 HP。", "flavor": "剑穗只在见血时安静。"},
	{"id": "R-08", "name": "九转金丹炉", "rarity": "mystique", "type": "passive", "price": 120, "effect_desc": "在黑市购买丹药时价格 -20%。", "flavor": "炉身已碎，余阵仍会偷一点药价。"},
	{"id": "R-09", "name": "真气蓄电石", "rarity": "mystique", "type": "active", "price": 130, "effect_desc": "每场战斗 1 次，将剩余灵力转化为身形。", "flavor": "多余的真气被石心慢慢压成护盾。"},
	{"id": "R-10", "name": "流光锁链", "rarity": "mystique", "type": "passive", "price": 140, "effect_desc": "每回合弃牌时，每弃 1 张获得 1 点身形。", "flavor": "锁链收走不再选择的路。"},
	{"id": "R-11", "name": "破界之眼", "rarity": "earth", "type": "passive", "price": 180, "effect_desc": "额外看见敌人的下 1 回合行动意图。", "flavor": "看得更远，也看得更冷。"},
	{"id": "R-12", "name": "不灭心灯", "rarity": "earth", "type": "passive", "price": 190, "effect_desc": "每场战斗结束后回复 5 HP。", "flavor": "灯火不亮，却从不肯灭。"},
	{"id": "R-13", "name": "万剑之魂", "rarity": "earth", "type": "passive", "price": 210, "effect_desc": "每打出第 3 张术法牌时，额外获得 2 点剑意。", "flavor": "旧日剑魂在连斩中醒来。"},
	{"id": "R-14", "name": "天道残页", "rarity": "heaven", "type": "passive", "price": 300, "effect_desc": "卡牌奖励至少出现 1 张玄品以上卡牌。", "flavor": "残页上写着不该被凡人读懂的字。"},
	{"id": "R-15", "name": "轮回心印", "rarity": "heaven", "type": "passive", "price": 360, "effect_desc": "本局首次死亡时，有概率以 20% HP 复活。", "flavor": "灵魂深处仍有一枚不肯散去的印。"},
]


func get_all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in ITEMS:
		result.append((item as Dictionary).duplicate(true))
	return result


func get_all_artifacts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for art in ARTIFACTS:
		result.append((art as Dictionary).duplicate(true))
	return result


func get_item_by_id(id: String) -> Dictionary:
	for item in ITEMS:
		if item["id"] == id:
			return (item as Dictionary).duplicate(true)
	return {}


func get_artifact_by_id(id: String) -> Dictionary:
	for art in ARTIFACTS:
		if art["id"] == id:
			return (art as Dictionary).duplicate(true)
	return {}


func generate_stock(floor: int, owned_artifact_ids: Array, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(seed)
	return {
		"cards": _pick_cards(floor, rng),
		"items": _pick_items(floor, rng),
		"artifacts": _pick_artifacts(floor, owned_artifact_ids, rng),
	}


func get_card_price(card) -> int:
	var rarity := ""
	if typeof(card) == TYPE_DICTIONARY:
		rarity = str(card.get("rarity", ""))
	else:
		var card_data := CardDatabase.get_card(card)
		rarity = str(card_data.get("rarity", ""))
	return int(CARD_PRICES.get(rarity, 50))


func get_upgrade_price(card_id) -> int:
	var card := CardDatabase.get_card(str(card_id).trim_suffix("+"))
	return int(UPGRADE_PRICES.get(card.get("rarity", "黄品"), 30))


func get_remove_price(remove_count: int) -> int:
	return 50 + maxi(0, remove_count) * 25


func get_category_label(category: String) -> String:
	match category:
		"elixir": return "丹药"
		"talisman": return "符箓"
		"formation": return "阵法"
		_: return "物品"


func get_rarity_label(rarity: String) -> String:
	match rarity:
		"yellow": return "黄品"
		"mystique": return "玄品"
		"earth": return "地品"
		"heaven": return "天品"
		_: return str(rarity)


func _pick_cards(floor: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var all_cards := CardDatabase.get_all_cards()
	var result: Array[Dictionary] = []
	var used := {}
	var rarities := _card_rarities_for_floor(floor)
	var attempts := 0
	while result.size() < 3 and attempts < 200:
		attempts += 1
		var rarity: String = rarities[rng.randi_range(0, rarities.size() - 1)]
		var pool := all_cards.filter(func(c: Dictionary) -> bool:
			return c.get("rarity", "") == rarity and not used.has(c.get("id", ""))
		)
		if pool.is_empty():
			pool = all_cards.filter(func(c: Dictionary) -> bool:
				return not used.has(c.get("id", ""))
			)
		if pool.is_empty():
			break
		var card: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		used[card["id"]] = true
		result.append(card.duplicate(true))
	return result


func _pick_items(floor: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var pool := []
	for item in ITEMS:
		if int(item.get("min_floor", 1)) <= floor:
			pool.append(item)
	return _pick_unique_dicts(pool, 4, rng)


func _pick_artifacts(floor: int, owned_artifact_ids: Array, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var pool := []
	for art in ARTIFACTS:
		if int(art.get("min_floor", 1)) <= floor and not owned_artifact_ids.has(str(art.get("id", ""))):
			pool.append(art)
	if pool.size() < 2:
		for art in ARTIFACTS:
			if not owned_artifact_ids.has(str(art.get("id", ""))) and not pool.has(art):
				pool.append(art)
	return _pick_unique_dicts(pool, 2, rng)


func _pick_unique_dicts(pool: Array, count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var available := pool.duplicate()
	var result: Array[Dictionary] = []
	while result.size() < count and not available.is_empty():
		var idx := rng.randi_range(0, available.size() - 1)
		var item: Dictionary = available[idx]
		available.remove_at(idx)
		result.append(item.duplicate(true))
	return result


func _card_rarities_for_floor(floor: int) -> Array[String]:
	if floor <= 5:
		return ["黄品", "黄品", "黄品", "玄品"]
	if floor <= 10:
		return ["黄品", "玄品", "玄品", "地品"]
	return ["玄品", "地品", "地品", "天品"]
