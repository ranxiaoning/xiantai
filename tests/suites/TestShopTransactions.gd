## TestShopTransactions.gd
## 验证 GameState 承接黑市购买、删牌、升级与地图物品使用。
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestShopTransactions ]")
	_t("test_spend_spirit_stones_requires_enough_currency")
	_t("test_buy_card_adds_to_deck_and_charges")
	_t("test_buy_item_respects_bag_capacity")
	_t("test_buy_artifact_does_not_use_bag_capacity")
	_t("test_buy_artifact_does_not_add_active_fields")
	_t("test_remove_card_charges_and_blocks_last_card")
	_t("test_upgrade_card_adds_plus_and_blocks_reupgrade")
	_t("test_use_map_elixir_heals_and_consumes")
	_t("test_use_battle_consumable_returns_effect_and_consumes")
	_t("test_use_map_item_queues_next_battle_effect")
	_t("test_use_map_item_sets_next_shop_bonus")
	_t("test_use_map_item_sets_next_reward_bonus")
	_t("test_use_wind_talisman_expands_current_next_floor_choices")
	_t("test_use_formation_consumes_and_queues_effect")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_spend_spirit_stones_requires_enough_currency() -> void:
	_start_run()
	_assert_true(GameState.has_method("spend_spirit_stones"), "GameState 有 spend_spirit_stones")
	if not GameState.has_method("spend_spirit_stones"):
		return
	_assert_eq(GameState.call("spend_spirit_stones", 30), true, "灵石足够时扣费成功")
	_assert_eq(GameState.spirit_stones, 70, "扣费后灵石减少")
	_assert_eq(GameState.call("spend_spirit_stones", 999), false, "灵石不足时扣费失败")
	_assert_eq(GameState.spirit_stones, 70, "失败扣费不改变灵石")


func test_buy_card_adds_to_deck_and_charges() -> void:
	_start_run()
	var old_size := GameState.deck.size()
	_assert_true(GameState.has_method("buy_shop_card"), "GameState 有 buy_shop_card")
	if not GameState.has_method("buy_shop_card"):
		return
	_assert_eq(GameState.call("buy_shop_card", "1", 50), true, "购买卡牌成功")
	_assert_eq(GameState.spirit_stones, 50, "购买卡牌扣除灵石")
	_assert_eq(GameState.deck.size(), old_size + 1, "购买卡牌加入牌组")
	_assert_eq(GameState.deck[GameState.deck.size() - 1], "1", "加入指定卡牌 id")


func test_buy_item_respects_bag_capacity() -> void:
	_start_run()
	_assert_true(GameState.has_method("buy_shop_item"), "GameState 有 buy_shop_item")
	if not GameState.has_method("buy_shop_item"):
		return
	var item := {"id": "D-01", "name": "回春丹", "category": "elixir", "effect": "heal", "amount": 15, "price": 30}
	for i in range(GameState.BAG_CAPACITY):
		GameState.consumables.append({"id": "T-%02d" % i, "name": "测试符箓", "category": "talisman"})
	GameState.spirit_stones = 100
	_assert_eq(GameState.call("buy_shop_item", item, 30), false, "背包满时不可购买物品")
	_assert_eq(GameState.spirit_stones, 100, "背包满购买失败不扣费")


func test_buy_artifact_does_not_use_bag_capacity() -> void:
	_start_run()
	_assert_true(GameState.has_method("buy_shop_artifact"), "GameState 有 buy_shop_artifact")
	if not GameState.has_method("buy_shop_artifact"):
		return
	for i in range(GameState.BAG_CAPACITY):
		GameState.consumables.append({"id": "T-%02d" % i, "name": "测试符箓", "category": "talisman"})
	var art := {"id": "R-01", "name": "残剑鞘", "rarity": "yellow", "price": 60}
	_assert_eq(GameState.call("buy_shop_artifact", art, 60), true, "背包满仍可购买宝物")
	_assert_eq(GameState.artifacts.size(), 1, "宝物加入独立栏")
	_assert_eq(GameState.consumables.size(), GameState.BAG_CAPACITY, "宝物不占背包格")


func test_buy_artifact_does_not_add_active_fields() -> void:
	_start_run()
	var art := {"id": "R-02", "name": "铜甲残片", "rarity": "yellow", "price": 65}
	_assert_eq(GameState.call("buy_shop_artifact", art, 65), true, "购买宝物成功")
	var owned: Dictionary = GameState.artifacts[0]
	_assert_true(not owned.has("type"), "购买后宝物不带 type 字段")
	_assert_true(not owned.has("active_used"), "购买后宝物不带 active_used 字段")


func test_remove_card_charges_and_blocks_last_card() -> void:
	_start_run()
	_assert_true(GameState.has_method("remove_deck_card_at"), "GameState 有 remove_deck_card_at")
	if not GameState.has_method("remove_deck_card_at"):
		return
	var old_size := GameState.deck.size()
	_assert_eq(GameState.call("remove_deck_card_at", 0, 50), true, "删牌服务成功")
	_assert_eq(GameState.deck.size(), old_size - 1, "删牌后牌组减少")
	_assert_eq(GameState.spirit_stones, 50, "删牌扣除灵石")
	_assert_eq(GameState.shop_remove_service_uses, 1, "删牌次数递增")
	GameState.deck = ["5"]
	GameState.spirit_stones = 999
	_assert_eq(GameState.call("remove_deck_card_at", 0, 75), false, "牌组只剩 1 张时不可删除")


func test_upgrade_card_adds_plus_and_blocks_reupgrade() -> void:
	_start_run()
	_assert_true(GameState.has_method("upgrade_deck_card_at"), "GameState 有 upgrade_deck_card_at")
	if not GameState.has_method("upgrade_deck_card_at"):
		return
	GameState.deck = ["5", "20+"]
	_assert_eq(GameState.call("upgrade_deck_card_at", 0, 30), true, "升级未升级卡牌成功")
	_assert_eq(GameState.deck[0], "5+", "升级后卡牌 id 追加 +")
	_assert_eq(GameState.spirit_stones, 70, "升级扣除灵石")
	_assert_eq(GameState.call("upgrade_deck_card_at", 1, 30), false, "已升级卡牌不可重复升级")


func test_use_map_elixir_heals_and_consumes() -> void:
	_start_run()
	_assert_true(GameState.has_method("use_consumable"), "GameState 有 use_consumable")
	if not GameState.has_method("use_consumable"):
		return
	GameState.current_hp = 40
	GameState.consumables = [{"id": "D-01", "name": "回春丹", "category": "elixir", "map_use": {"type": "heal", "amount": 18}}]
	var result: Dictionary = GameState.call("use_consumable", 0, "map")
	_assert_eq(result.get("ok", false), true, "地图使用回血丹成功")
	_assert_eq(GameState.current_hp, 58, "回血丹恢复生命")
	_assert_eq(GameState.consumables.size(), 0, "回血丹使用后消耗")


func test_use_battle_consumable_returns_effect_and_consumes() -> void:
	_start_run()
	_assert_true(GameState.has_method("use_consumable"), "GameState 有 use_consumable")
	if not GameState.has_method("use_consumable"):
		return
	GameState.consumables = [{
		"id": "D-01",
		"name": "回春丹",
		"category": "elixir",
		"battle_use": {"type": "heal", "amount": 10},
	}]
	var result: Dictionary = GameState.call("use_consumable", 0, "battle")
	_assert_eq(result.get("ok", false), true, "战斗使用物品成功")
	_assert_eq(str(result.get("message", "")), "已使用：回春丹", "战斗使用物品返回反馈")
	_assert_eq((result.get("battle_use", {}) as Dictionary).get("type", ""), "heal", "战斗使用返回 battle_use 效果")
	_assert_eq(GameState.consumables.size(), 0, "战斗使用后物品消耗")


func test_use_map_item_queues_next_battle_effect() -> void:
	_start_run()
	_assert_true(GameState.has_method("use_consumable"), "GameState 有 use_consumable")
	if not GameState.has_method("use_consumable"):
		return
	GameState.consumables = [{
		"id": "T-03",
		"name": "护符·金钟",
		"category": "talisman",
		"map_use": {"type": "next_battle", "effect": {"type": "hu_ti", "amount": 10}},
	}]
	var result: Dictionary = GameState.call("use_consumable", 0, "map")
	_assert_eq(result.get("ok", false), true, "地图使用下场战斗准备物品成功")
	var pending = GameState.get("pending_battle_consumable_effects")
	_assert_true(pending is Array, "GameState 记录待结算战斗物品效果")
	if pending is Array:
		_assert_eq((pending as Array).size(), 1, "下场战斗效果入队")
	_assert_eq(GameState.consumables.size(), 0, "下场战斗准备物品使用后消耗")


func test_use_map_item_sets_next_shop_bonus() -> void:
	_start_run()
	_assert_true(GameState.has_method("use_consumable"), "GameState 有 use_consumable")
	if not GameState.has_method("use_consumable"):
		return
	GameState.consumables = [{
		"id": "F-03",
		"name": "观星阵盘",
		"category": "formation",
		"map_use": {"type": "next_shop_extra_items", "amount": 1},
	}]
	var result: Dictionary = GameState.call("use_consumable", 0, "map")
	_assert_eq(result.get("ok", false), true, "地图使用下次黑市加货物品成功")
	_assert_eq(GameState.get("pending_shop_extra_items"), 1, "记录下次黑市物品 +1")
	_assert_eq(GameState.consumables.size(), 0, "黑市加货物品使用后消耗")


func test_use_map_item_sets_next_reward_bonus() -> void:
	_start_run()
	_assert_true(GameState.has_method("use_consumable"), "GameState 有 use_consumable")
	if not GameState.has_method("use_consumable"):
		return
	GameState.consumables = [
		{"id": "T-08", "name": "血符·回脉", "category": "talisman", "map_use": {"type": "next_reward_stones", "amount": 20}},
		{"id": "T-07", "name": "剑符·鸣锋", "category": "talisman", "map_use": {"type": "next_reward_min_rarity", "rarity": "玄品"}},
	]
	var stones_result: Dictionary = GameState.call("use_consumable", 0, "map")
	var rarity_result: Dictionary = GameState.call("use_consumable", 0, "map")
	_assert_eq(stones_result.get("ok", false), true, "地图使用下次奖励灵石加成物品成功")
	_assert_eq(rarity_result.get("ok", false), true, "地图使用下次奖励稀有度保障物品成功")
	_assert_eq(GameState.get("pending_reward_stones_bonus"), 20, "记录下次奖励灵石加成")
	_assert_eq(str(GameState.get("pending_reward_min_rarity")), "玄品", "记录下次卡牌奖励最低稀有度")


func test_use_wind_talisman_expands_current_next_floor_choices() -> void:
	_start_run()
	_assert_true(GameState.has_method("use_consumable"), "GameState 有 use_consumable")
	if not GameState.has_method("use_consumable"):
		return
	GameState.map_nodes = {
		"a": {"id": "a", "floor": 2, "type": "normal", "next_ids": []},
		"b": {"id": "b", "floor": 2, "type": "shop", "next_ids": []},
		"c": {"id": "c", "floor": 2, "type": "event", "next_ids": []},
	}
	GameState.map_floors = [[], ["a", "b", "c"]]
	GameState.map_accessible_ids = ["a"]
	GameState.consumables = [{
		"id": "T-02",
		"name": "风符·逐云",
		"category": "talisman",
		"map_use": {"type": "next_floor_any_node"},
	}]
	var result: Dictionary = GameState.call("use_consumable", 0, "map")
	_assert_eq(result.get("ok", false), true, "地图使用风符·逐云成功")
	_assert_eq(GameState.map_accessible_ids.size(), 3, "风符让本次选择可从下一层所有同层节点中选1个")
	_assert_true(GameState.map_accessible_ids.has("b"), "风符包含原路线外的下一层节点")
	_assert_eq(GameState.consumables.size(), 0, "风符使用后消耗")


func test_use_formation_consumes_and_queues_effect() -> void:
	_start_run()
	_assert_true(GameState.has_method("use_consumable"), "GameState 有 use_consumable")
	if not GameState.has_method("use_consumable"):
		return
	GameState.consumables = [{
		"id": "F-01",
		"name": "聚灵阵盘",
		"category": "formation",
		"map_use": {"type": "next_battle", "effect": {"type": "ling_li", "amount": 2}},
	}]
	var result: Dictionary = GameState.call("use_consumable", 0, "map")
	_assert_eq(result.get("ok", false), true, "地图使用阵盘成功")
	_assert_eq(GameState.active_formation_id, "", "阵盘不再记录为常驻阵法")
	_assert_eq(GameState.consumables.size(), 0, "阵盘使用后消耗")


func _start_run() -> void:
	GameState.start_run("chen_tian_feng")


func _t(method: String) -> void:
	call(method)


func _assert_eq(a, b, label: String) -> void:
	if a == b:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 期望 %s，实际 %s" % [label, str(b), str(a)])


func _assert_true(cond: bool, label: String) -> void:
	if cond:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 条件为假" % label)
