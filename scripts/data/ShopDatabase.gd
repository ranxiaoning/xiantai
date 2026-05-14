## ShopDatabase.gd  (Autoload: ShopDatabase)
## 黑市 V1 静态商品数据、价格表与库存生成。
extends Node

const CARD_PRICES := {"黄品": 50, "玄品": 80, "地品": 150, "天品": 300}
const UPGRADE_PRICES := {"黄品": 30, "玄品": 50, "地品": 80, "天品": 150}

const ITEMS := [
	{"id": "D-01", "name": "回春丹", "category": "elixir", "rarity": "yellow", "price": 35, "min_floor": 1,
		"map_use": {"type": "heal", "amount": 18},
		"battle_use": {"type": "compound", "effects": [{"type": "heal", "amount": 10}, {"type": "hu_ti", "amount": 6}]},
		"effect_desc": "地图：回复18 HP。战斗：回复10 HP，获得6护体。"},
	{"id": "D-02", "name": "培元丹", "category": "elixir", "rarity": "yellow", "price": 50, "min_floor": 1,
		"map_use": {"type": "max_hp", "amount": 4, "heal": 4},
		"battle_use": {"type": "compound", "effects": [{"type": "ling_li", "amount": 2}, {"type": "dao_hui", "amount": 2}]},
		"effect_desc": "地图：最大HP+4并回复4 HP。战斗：获得2灵力、2道慧。"},
	{"id": "D-03", "name": "碎金丹", "category": "elixir", "rarity": "yellow", "price": 45, "min_floor": 1,
		"map_use": {"type": "next_battle", "effect": {"type": "enemy_status", "key": "lie_shang", "stacks": 1}},
		"battle_use": {"type": "compound", "effects": [{"type": "damage", "amount": 10}, {"type": "enemy_status", "key": "lie_shang", "stacks": 1}]},
		"effect_desc": "地图：下场战斗敌方开局裂伤1。战斗：造成10伤害，裂伤1。"},
	{"id": "D-04", "name": "静息丹", "category": "elixir", "rarity": "yellow", "price": 50, "min_floor": 1,
		"map_use": {"type": "hp_regen", "amount": 1},
		"battle_use": {"type": "compound", "effects": [{"type": "cleanse", "amount": 1}, {"type": "player_status", "key": "bu_qin", "stacks": 1}]},
		"effect_desc": "地图：本局生命回复+1。战斗：清除1个负面，获得不侵1。"},
	{"id": "D-05", "name": "醒神丹", "category": "elixir", "rarity": "yellow", "price": 55, "min_floor": 1,
		"map_use": {"type": "next_battle", "effect": {"type": "start_draw", "amount": 1}},
		"battle_use": {"type": "compound", "effects": [{"type": "draw", "amount": 2}, {"type": "ling_li", "amount": 1}]},
		"effect_desc": "地图：下场战斗起手抽牌+1。战斗：抽2张牌，获得1灵力。"},
	{"id": "D-06", "name": "藏锋丹", "category": "elixir", "rarity": "mystique", "price": 80, "min_floor": 6,
		"map_use": {"type": "next_battle", "effect": {"type": "dao_xing", "amount": 1}},
		"battle_use": {"type": "compound", "effects": [{"type": "dao_xing", "amount": 1}, {"type": "next_attack_bonus", "amount": 4}]},
		"effect_desc": "地图：下场战斗开局道行+1。战斗：道行+1，下一张术法伤害+4。"},
	{"id": "D-07", "name": "凝元丹", "category": "elixir", "rarity": "mystique", "price": 90, "min_floor": 6,
		"map_use": {"type": "ling_li_regen", "amount": 1},
		"battle_use": {"type": "ling_li", "amount": 4},
		"effect_desc": "地图：本局灵力回复+1。战斗：获得4灵力。"},
	{"id": "D-08", "name": "玉骨丹", "category": "elixir", "rarity": "earth", "price": 150, "min_floor": 11,
		"map_use": {"type": "max_hp", "amount": 10, "heal": 10},
		"battle_use": {"type": "compound", "effects": [{"type": "hu_ti", "amount": 22}, {"type": "player_status", "key": "bu_qin", "stacks": 1}]},
		"effect_desc": "地图：最大HP+10并回复10 HP。战斗：获得22护体、不侵1。"},
	{"id": "D-09", "name": "逆天仙露", "category": "elixir", "rarity": "heaven", "price": 280, "min_floor": 14,
		"map_use": {"type": "dual_regen", "amount": 1},
		"battle_use": {"type": "compound", "effects": [{"type": "heal", "amount": 25}, {"type": "dao_xing", "amount": 2}, {"type": "player_status", "key": "bu_qin", "stacks": 1}]},
		"effect_desc": "地图：生命回复+1，灵力回复+1。战斗：回复25 HP，道行+2，不侵1。"},

	{"id": "T-01", "name": "火符·焚天", "category": "talisman", "rarity": "yellow", "price": 35, "min_floor": 1,
		"map_use": {"type": "next_battle", "effect": {"type": "damage", "amount": 8}},
		"battle_use": {"type": "damage", "amount": 16},
		"effect_desc": "地图：下场战斗开局造成8伤害。战斗：造成16伤害。"},
	{"id": "T-02", "name": "风符·逐云", "category": "talisman", "rarity": "yellow", "price": 40, "min_floor": 1,
		"map_use": {"type": "next_floor_any_node"},
		"battle_use": {"type": "draw", "amount": 3},
		"effect_desc": "地图：下一次选择地图节点时，可从下一层所有同层节点中选择 1 个。战斗：抽3张牌。"},
	{"id": "T-03", "name": "护符·金钟", "category": "talisman", "rarity": "yellow", "price": 45, "min_floor": 1,
		"map_use": {"type": "next_battle", "effect": {"type": "hu_ti", "amount": 10}},
		"battle_use": {"type": "hu_ti", "amount": 16},
		"effect_desc": "地图：下场战斗开局护体+10。战斗：获得16护体。"},
	{"id": "T-04", "name": "净符·涤秽", "category": "talisman", "rarity": "yellow", "price": 50, "min_floor": 1,
		"map_use": {"type": "next_battle", "effect": {"type": "debuff_ward", "amount": 1}},
		"battle_use": {"type": "cleanse", "amount": 2},
		"effect_desc": "地图：下场战斗免疫首次负面。战斗：清除2个负面。"},
	{"id": "T-05", "name": "雷符·震霆", "category": "talisman", "rarity": "mystique", "price": 80, "min_floor": 6,
		"map_use": {"type": "next_battle", "effects": [{"type": "enemy_status", "key": "lie_shang", "stacks": 1}, {"type": "enemy_status", "key": "ku_jie", "stacks": 1}]},
		"battle_use": {"type": "compound", "effects": [{"type": "damage", "amount": 10}, {"type": "enemy_status", "key": "lie_shang", "stacks": 2}]},
		"effect_desc": "地图：下场敌方裂伤1、枯竭1。战斗：造成10伤害，裂伤2。"},
	{"id": "T-06", "name": "镇符·定身", "category": "talisman", "rarity": "mystique", "price": 95, "min_floor": 6,
		"map_use": {"type": "next_battle", "effect": {"type": "delay_enemy_action", "amount": 1}},
		"battle_use": {"type": "delay_enemy_action", "amount": 1},
		"effect_desc": "地图：下场敌方首次行动延后。战斗：延后敌方下一次行动。"},
	{"id": "T-07", "name": "剑符·鸣锋", "category": "talisman", "rarity": "mystique", "price": 90, "min_floor": 6,
		"map_use": {"type": "next_reward_min_rarity", "rarity": "玄品"},
		"battle_use": {"type": "compound", "effects": [{"type": "dao_xing", "amount": 2}, {"type": "draw", "amount": 1}]},
		"effect_desc": "地图：下次卡牌奖励至少出现玄品。战斗：道行+2，抽1张牌。"},
	{"id": "T-08", "name": "血符·回脉", "category": "talisman", "rarity": "mystique", "price": 100, "min_floor": 6,
		"map_use": {"type": "next_reward_stones", "amount": 20},
		"battle_use": {"type": "lifesteal", "amount": 12},
		"effect_desc": "地图：下次战斗奖励灵石+20。战斗：造成12伤害，按生命伤害回复。"},
	{"id": "T-09", "name": "锁魂符", "category": "talisman", "rarity": "earth", "price": 160, "min_floor": 11,
		"map_use": {"type": "next_battle", "effect": {"type": "enemy_dao_xing", "amount": -2}},
		"battle_use": {"type": "compound", "effects": [{"type": "enemy_dao_xing", "amount": -2}, {"type": "enemy_status", "key": "ku_jie", "stacks": 2}]},
		"effect_desc": "地图：下场敌方开局道行-2。战斗：敌方道行-2，枯竭2。"},
	{"id": "T-10", "name": "劫雷符", "category": "talisman", "rarity": "earth", "price": 180, "min_floor": 11,
		"map_use": {"type": "next_battle", "effect": {"type": "damage", "amount": 20, "boss_half": true}},
		"battle_use": {"type": "compound", "effects": [{"type": "damage", "amount": 30}, {"type": "enemy_status", "key": "lie_shang", "stacks": 1}]},
		"effect_desc": "地图：下场开局20伤害，Boss减半。战斗：造成30伤害，裂伤1。"},

	{"id": "F-01", "name": "聚灵阵盘", "category": "formation", "rarity": "yellow", "price": 60, "min_floor": 1,
		"map_use": {"type": "next_battle", "effect": {"type": "ling_li", "amount": 2}},
		"battle_use": {"type": "compound", "effects": [{"type": "ling_li", "amount": 3}, {"type": "draw", "amount": 1}]},
		"effect_desc": "地图：下场首回合灵力+2。战斗：获得3灵力，抽1张牌。"},
	{"id": "F-02", "name": "固本阵盘", "category": "formation", "rarity": "mystique", "price": 100, "min_floor": 6,
		"map_use": {"type": "next_battle", "effect": {"type": "hu_ti", "amount": 16}},
		"battle_use": {"type": "hu_ti", "amount": 20},
		"effect_desc": "地图：下场战斗开局护体+16。战斗：获得20护体。"},
	{"id": "F-03", "name": "观星阵盘", "category": "formation", "rarity": "mystique", "price": 110, "min_floor": 6,
		"map_use": {"type": "next_shop_extra_items", "amount": 1},
		"battle_use": {"type": "compound", "effects": [{"type": "draw", "amount": 2}, {"type": "player_status", "key": "xin_liu", "stacks": 2}]},
		"effect_desc": "地图：下次黑市物品货架+1。战斗：抽2张牌，获得心流2。"},
	{"id": "F-04", "name": "万剑阵盘", "category": "formation", "rarity": "earth", "price": 170, "min_floor": 11,
		"map_use": {"type": "next_battle", "effects": [{"type": "dao_xing", "amount": 2}, {"type": "next_attack_bonus", "amount": 6}]},
		"battle_use": {"type": "compound", "effects": [{"type": "dao_xing", "amount": 2}, {"type": "next_attack_bonus", "amount": 8}]},
		"effect_desc": "地图：下场道行+2，首张术法+6伤害。战斗：道行+2，下一张术法+8伤害。"},
	{"id": "F-05", "name": "玄龟阵盘", "category": "formation", "rarity": "earth", "price": 180, "min_floor": 11,
		"map_use": {"type": "next_shop_discount", "pct": 0.2},
		"battle_use": {"type": "compound", "effects": [{"type": "hu_ti", "amount": 25}, {"type": "player_status", "key": "bu_qin", "stacks": 2}]},
		"effect_desc": "地图：下次黑市价格-20%。战斗：获得25护体、不侵2。"},
	{"id": "F-06", "name": "轮回阵盘", "category": "formation", "rarity": "heaven", "price": 320, "min_floor": 14,
		"map_use": {"type": "next_battle", "effect": {"type": "death_save", "amount": 1}},
		"battle_use": {"type": "compound", "effects": [{"type": "death_save", "amount": 1}, {"type": "heal", "amount": 10}]},
		"effect_desc": "地图：下场预置1次濒死保护。战斗：预置濒死保护，并回复10 HP。"},
]

const ARTIFACTS := [
	# ── 黄品（60~90 灵石）──────────────────────────────────────────────
	{"id": "R-01", "name": "残剑鞘", "rarity": "yellow", "price": 60,
		"effect_desc": "每回合开始时，获得 1 点护体。",
		"artifact_detail": "老旧的剑鞘上有不知名的符文，能将第一剑的气势化为防御。"},
	{"id": "R-02", "name": "铜甲残片", "rarity": "yellow", "price": 65,
		"effect_desc": "每场战斗开始时获得 5 点护体。",
		"artifact_detail": "虽已破损，但仍能抵御伤害。残缺的铜甲比许多人的尊严更坚硬。"},
	{"id": "R-03", "name": "聚灵珠", "rarity": "yellow", "price": 70,
		"effect_desc": "战斗开始时，获得 3 点灵力。",
		"artifact_detail": "珠中封存着一缕天地灵气，稳定地滋养着你的元神。"},
	{"id": "R-04", "name": "血玉环", "rarity": "yellow", "price": 75,
		"effect_desc": "HP 低于 50% 时，伤害倍率 +0.1。",
		"artifact_detail": "以鲜血淬炼的玉环，危机关头反而能激发本能的爆发力。"},
	{"id": "R-05", "name": "寒铁护腕", "rarity": "yellow", "price": 80,
		"effect_desc": "收到的所有即将失去生命的伤害 -1。",
		"artifact_detail": "由北域寒铁铸就，每次受击，寒意反而让思维更加清醒，防御更加严密。"},
	{"id": "R-06", "name": "灵犀簪", "rarity": "yellow", "price": 90,
		"effect_desc": "战斗开始时，抽 1 张牌。",
		"artifact_detail": "发簪上的灵纹感应天地道蕴，让你更快捕捉到残留的功法印记。"},

	# ── 玄品（100~160 灵石）────────────────────────────────────────────
	{"id": "R-07", "name": "饮血剑穗", "rarity": "mystique", "price": 100,
		"effect_desc": "生命恢复 +3，最大生命值 +5。",
		"artifact_detail": "剑穗上附着嗜血邪术，每一次出剑都有机会汲取敌人的生命力。"},
	{"id": "R-08", "name": "九转金丹炉（残）", "rarity": "mystique", "price": 120,
		"effect_desc": "在商店购买物品时，价格 -20%（向下取整）。",
		"artifact_detail": "丹炉已碎大半，但残余的炼丹法阵仍能小幅降低炼丹成本。"},
	{"id": "R-09", "name": "真气蓄电石", "rarity": "mystique", "price": 130,
		"effect_desc": "遭受致命伤害时，失去该宝物，阻止此次伤害，恢复 20 点生命。",
		"artifact_detail": "将多余的真气转化为防护，在不使用真气的回合也能充分利用资源。"},
	{"id": "R-10", "name": "流光锁链", "rarity": "mystique", "price": 130,
		"effect_desc": "每抽 1 张牌，获得 1 点护体。",
		"artifact_detail": "锁链在弃牌的瞬间吸收残余灵力，凝结成薄薄的护盾。"},
	{"id": "R-11", "name": "破界之眼", "rarity": "mystique", "price": 140,
		"effect_desc": "进入战斗时，敌方获得一层枯竭，一层裂伤。",
		"artifact_detail": "这只诡异的义眼让你能窥见更多的天机，却也让你看到了更多的绝望。"},
	{"id": "R-12", "name": "噬魂灯", "rarity": "mystique", "price": 150,
		"effect_desc": "战斗结束时，获得 1 点最大生命值。",
		"artifact_detail": "幽绿的灯火能捕获敌人临终前的最后一丝灵力，供你驱使。"},
	{"id": "R-13", "name": "剑意共鸣石", "rarity": "mystique", "price": 160,
		"effect_desc": "每当你获得 1 层道行，造成 10 点伤害。",
		"artifact_detail": "石中封印的剑灵会在你剑意充盈时自行出剑，与你并肩作战。"},

	# ── 地品（180~250 灵石）────────────────────────────────────────────
	{"id": "R-14", "name": "不灭心灯", "rarity": "earth", "price": 180,
		"effect_desc": "每场战斗结束后，回复 5 HP（不超过最大值）。",
		"artifact_detail": "微弱的灯火永不熄灭，如同你心中那束不甘就此泯灭的倔强之光。"},
	{"id": "R-15", "name": "万剑之魂", "rarity": "earth", "price": 200,
		"effect_desc": "每当你打出 4 张术法牌时，获得 1 点剑意。",
		"artifact_detail": "万剑门祖师的残魂附着其上，你的连续出剑会引起它的共鸣。"},
	{"id": "R-16", "name": "天蚕丝甲", "rarity": "earth", "price": 210,
		"effect_desc": "抵挡每场战斗第一次攻击。",
		"artifact_detail": "以天蚕神丝编织的内甲，能在致命打击降临时收紧纤维，分散冲击。"},
	{"id": "R-17", "name": "逆鳞珠", "rarity": "earth", "price": 220,
		"effect_desc": "灵力恢复 +1。",
		"artifact_detail": "龙族的逆鳞化成的珠子，触怒它只会让你的杀意更加凶猛。"},
	{"id": "R-18", "name": "道心明镜", "rarity": "earth", "price": 230,
		"effect_desc": "免疫第 1 次被施加的负面状态（每场战斗 1 次）。",
		"artifact_detail": "明镜不染尘埃，第一次来自天道的诅咒将被自动弹开。"},
	{"id": "R-19", "name": "混元真气瓶", "rarity": "earth", "price": 250,
		"effect_desc": "每回合灵力上限永久 +1。",
		"artifact_detail": "瓶中封存着某位大能的醇厚真气，你将其融入自身后，元力大幅提升。"},

	# ── 天品（300+ 灵石，仅精英/Boss掉落或第三重天商店）───────────────
	{"id": "R-20", "name": "天道残页", "rarity": "heaven", "price": 300,
		"effect_desc": "每场战斗的卡牌奖励中，必定出现至少 1 张玄品以上卡牌。",
		"artifact_detail": "天宫典籍的残页，上面记载的法则碎片能引导你找到更强的道蕴。"},
	{"id": "R-21", "name": "弑神之刃（碎片）", "rarity": "heaven", "price": 350,
		"effect_desc": "你的所有术法牌伤害 +2。击杀 Boss 时，额外获得 50 灵石。",
		"artifact_detail": "传说中唯一能伤到天宫之主的兵器碎片，仅仅是碎片，就蕴含可怕的力量。"},
	{"id": "R-22", "name": "轮回心印", "rarity": "heaven", "price": 380,
		"effect_desc": "生命恢复 +5，最大生命值 +20，法力恢复 +1。",
		"artifact_detail": "刻在灵魂深处的印记，是千万次轮回凝结的不甘与执念。"},

	# ── 起源宝物（不可购买，仅由起始节点赋予）─────────────────────────
	{"id": "R-S01", "name": "剑魂觉醒", "rarity": "origin", "price": 0,
		"effect_desc": "每场战斗开始时，你的初始道行 +5。",
		"artifact_detail": "前尘未散，剑意犹存。上一世的巅峰，仍在你指尖流转。"},
	{"id": "R-S02", "name": "赤诚护体", "rarity": "origin", "price": 0,
		"effect_desc": "每场战斗开始时，获得 8 点护体。",
		"artifact_detail": "铸体之功，功不唐捐。这一世的身躯，生来便如铜墙铁壁。"},
	{"id": "R-S03", "name": "贪欲之道", "rarity": "origin", "price": 0,
		"effect_desc": "黑市（商店）所有商品的价格降低 15%（向下取整）。",
		"artifact_detail": "财帛动人心，机关算尽亦风流。你总能以最合适的代价换取所需。"},
	{"id": "R-S06", "name": "灵力精进", "rarity": "origin", "price": 0,
		"effect_desc": "战斗内最大灵力上限 +2，且每回合开始额外回复 1 点灵力。",
		"artifact_detail": "心静则气聚，气聚则灵盈。你的经脉远比常人更宽广且活跃。"},
	{"id": "R-S08", "name": "记忆觉醒", "rarity": "origin", "price": 0,
		"effect_desc": "每场战斗开始时，你的初始道行 +2。",
		"artifact_detail": "轮回深处的一缕灵光，让你在战斗中总能占得先机。"},
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


func generate_stock(floor: int, owned_artifact_ids: Array, seed: int, extra_item_count: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(seed)
	return {
		"cards": _pick_cards(floor, rng),
		"items": _pick_items(floor, rng, extra_item_count),
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
		"formation": return "阵盘"
		_: return "物品"


func get_rarity_label(rarity: String) -> String:
	match rarity:
		"yellow": return "黄品"
		"mystique": return "玄品"
		"earth": return "地品"
		"heaven": return "天品"
		"origin": return "起源"
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


func _pick_items(floor: int, rng: RandomNumberGenerator, extra_item_count: int = 0) -> Array[Dictionary]:
	var pool := []
	for item in ITEMS:
		if int(item.get("min_floor", 1)) <= floor:
			pool.append(item)
	return _pick_unique_dicts(pool, 4 + maxi(0, extra_item_count), rng)


func _pick_artifacts(floor: int, owned_artifact_ids: Array, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var pool := []
	for art in ARTIFACTS:
		if int(art.get("price", 0)) > 0 and int(art.get("min_floor", 1)) <= floor and not owned_artifact_ids.has(str(art.get("id", ""))):
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
