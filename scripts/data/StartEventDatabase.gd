## StartEventDatabase.gd  (Autoload: StartEventDatabase)
## 起始节点起源祝福池：数据定义 + 效果执行。
extends Node

const START_POOL: Array[Dictionary] = [
	{
		"id": "S-01", "name": "剑魂觉醒", "weight": 16,
		"desc": "前尘未散，剑意犹存。\n\n获得起源宝物【剑魂觉醒】；牌库中随机 2 张牌升级。",
		"effects": [
			{"type": "artifact_specific", "id": "R-S01"},
			{"type": "card_upgrade_random", "count": 2},
		],
	},
	{
		"id": "S-02", "name": "赤诚护体", "weight": 16,
		"desc": "铸体之功，功不唐捐。\n\n生命上限 +20；获得起源宝物【赤诚护体】。",
		"effects": [
			{"type": "max_hp_perm", "amount": 20},
			{"type": "artifact_specific", "id": "R-S02"},
		],
	},
	{
		"id": "S-03", "name": "贪欲之道", "weight": 16,
		"desc": "财帛动人心，机关算尽亦风流。\n\n初始灵石 +150；获得起源宝物【贪欲之道】。",
		"effects": [
			{"type": "stones", "amount": 150},
			{"type": "artifact_specific", "id": "R-S03"},
		],
	},
	{
		"id": "S-04", "name": "轮回遗物", "weight": 16,
		"desc": "上一世的执念，化作此世的臂助。\n\n获得 1 件随机地品宝物。",
		"effects": [
			{"type": "artifact_random", "rarity": "earth"},
		],
	},
	{
		"id": "S-05", "name": "功法传承", "weight": 16,
		"desc": "先辈遗留的三卷秘典，各有其道。\n\n从 3 张随机地品功法中三选一加入牌库。",
		"effects": [
			{"type": "card_pick_by_rarity", "rarity": "地品", "count": 3},
		],
	},
	{
		"id": "S-06", "name": "灵力精进", "weight": 16,
		"desc": "心静则气聚，气聚则灵盈。\n\n获得起源宝物【灵力精进】。",
		"effects": [
			{"type": "artifact_specific", "id": "R-S06"},
		],
	},
	{
		"id": "S-07", "name": "天命指引", "weight": 2,
		"desc": "天道垂青，万中无一。\n\n获得 1 件随机天品宝物。",
		"effects": [
			{"type": "artifact_random", "rarity": "heaven"},
		],
	},
	{
		"id": "S-08", "name": "记忆觉醒", "weight": 4,
		"desc": "轮回深处，一页天书破壁而来。\n\n获得 1 张随机天品功法；获得起源宝物【记忆觉醒】。",
		"effects": [
			{"type": "card_random", "rarity": "天品"},
			{"type": "artifact_specific", "id": "R-S08"},
		],
	},
]


func roll_three(seed_val: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var pool := START_POOL.duplicate()
	var result: Array = []
	for _i in range(3):
		if pool.is_empty():
			break
		var total_weight := 0
		for b in pool:
			total_weight += int(b.get("weight", 1))
		var roll := rng.randi_range(0, total_weight - 1)
		var acc := 0
		for j in range(pool.size()):
			acc += int(pool[j].get("weight", 1))
			if roll < acc:
				result.append(pool[j])
				pool.remove_at(j)
				break
	return result


## 执行非交互式效果，返回结果文本（每行一条）。
## card_pick_by_rarity 需要 UI，调用方需单独处理。
func apply_instant_effects(effects: Array) -> String:
	var msgs: PackedStringArray = []
	for e in effects:
		var t: String = str(e.get("type", ""))
		match t:
			"stones":
				var n := int(e.get("amount", 0))
				GameState.add_spirit_stones(n)
				msgs.append("获得 %d 灵石" % n)
			"max_hp_perm":
				var n := int(e.get("amount", 0))
				GameState.character["hp_max"] = maxi(1, int(GameState.character.get("hp_max", 60)) + n)
				GameState.current_hp = clampi(GameState.current_hp, 0, int(GameState.character["hp_max"]))
				msgs.append("生命上限永久 +%d" % n)
			"perm_shield":
				var n := int(e.get("amount", 0))
				GameState.character["hu_ti"] = int(GameState.character.get("hu_ti", 0)) + n
				msgs.append("永久护体 +%d" % n)
			"artifact_specific":
				var art_id := str(e.get("id", ""))
				var art := ShopDatabase.get_artifact_by_id(art_id)
				if not art.is_empty():
					GameState.add_artifact(art)
					msgs.append("获得起源宝物：%s" % art.get("name", ""))
			"artifact_random":
				var rarity := str(e.get("rarity", "yellow"))
				var art := _random_artifact(rarity)
				if not art.is_empty():
					GameState.add_artifact(art)
					msgs.append("获得宝物：%s" % art.get("name", ""))
				else:
					msgs.append("（宝物已全部持有）")
			"card_random":
				var rarity := str(e.get("rarity", "黄品"))
				var card_id := _random_card(rarity)
				if not card_id.is_empty():
					GameState.deck.append(card_id)
					var cd := CardDatabase.get_card(card_id)
					msgs.append("获得功法：%s" % cd.get("name", card_id))
			"card_upgrade_random":
				var count := int(e.get("count", 2))
				var upgraded := _upgrade_random_cards(count)
				msgs.append("升级了 %d 张功法" % upgraded)
	return "\n".join(msgs)


func _random_artifact(rarity: String) -> Dictionary:
	var all_arts: Array = ShopDatabase.get_all_artifacts()
	var owned: Array[String] = []
	for a in GameState.artifacts:
		owned.append(str(a.get("id", "")))
	var pool: Array = all_arts.filter(func(a): return a.get("rarity", "") == rarity and not owned.has(str(a.get("id", ""))))
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]


func _random_card(rarity: String) -> String:
	var all_cards: Array = CardDatabase.get_all_cards()
	var pool: Array[String] = []
	for c in all_cards:
		if c.get("rarity", "") == rarity and not str(c.get("id", "")).ends_with("+"):
			pool.append(str(c.get("id", "")))
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]


func get_three_earth_cards() -> Array[String]:
	var all_cards: Array = CardDatabase.get_all_cards()
	var pool: Array[String] = []
	for c in all_cards:
		if c.get("rarity", "") == "地品" and not str(c.get("id", "")).ends_with("+"):
			pool.append(str(c.get("id", "")))
	pool.shuffle()
	return pool.slice(0, mini(3, pool.size()))


func _upgrade_random_cards(count: int) -> int:
	var eligible: Array[int] = []
	for i in range(GameState.deck.size()):
		if not str(GameState.deck[i]).ends_with("+"):
			eligible.append(i)
	eligible.shuffle()
	var upgraded := 0
	for i in range(mini(count, eligible.size())):
		var idx: int = eligible[i]
		var base_id := str(GameState.deck[idx]).trim_suffix("+")
		GameState.deck[idx] = base_id + "+"
		upgraded += 1
	return upgraded
