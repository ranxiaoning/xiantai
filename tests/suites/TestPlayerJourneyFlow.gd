## TestPlayerJourneyFlow.gd
## Headless 玩家旅程 smoke test：验证基础用户流程在场景/系统之间的状态承接。
extends RefCounted

const FlowHarnessScript := preload("res://tests/helpers/FlowHarness.gd")

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestPlayerJourneyFlow ]")

	_t("test_new_run_initializes_player_journey_state")
	_t("test_map_battle_reward_return_flow_preserves_state")
	_t("test_reward_pick_and_skip_paths_update_deck_correctly")
	_t("test_shop_journey_updates_currency_and_inventory")
	_t("test_event_and_safe_nodes_do_not_leak_battle_reward_state")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_new_run_initializes_player_journey_state() -> void:
	var h = FlowHarnessScript.new()
	h.start_new_run()

	_assert_eq(str(GameState.character.get("id", "")), "chen_tian_feng", "新局：选择程天锋写入 GameState")
	_assert_eq(GameState.current_hp, int(GameState.character.get("hp_max", 0)), "新局：当前 HP 等于生命上限")
	_assert_eq(GameState.deck.size(), 20, "新局：初始牌组 20 张")
	_assert_eq(GameState.spirit_stones, 100, "新局：初始灵石 100")
	_assert_eq(GameState.map_started, false, "新局：地图尚未从起始节点展开")
	_assert_eq(GameState.map_accessible_ids.size(), 0, "新局：第1层节点尚未解锁")
	h.assert_no_pending_leaks(self, "新局：无跨场景 pending 残留")


func test_map_battle_reward_return_flow_preserves_state() -> void:
	var h = FlowHarnessScript.new()
	h.start_new_run()
	h.unlock_first_floor()
	var node_id := h.visit_first_node_of_type("normal")
	_assert_true(not node_id.is_empty(), "旅程：找到并访问普通战斗节点")
	_assert_eq(GameState.pending_battle_node_type, "normal", "旅程：地图写入普通战斗 pending 类型")
	_assert_eq(GameState.pending_battle_node_floor, 1, "旅程：地图写入战斗节点层数")

	GameState.current_hp = 37
	var engine: Object = h.start_battle_for_pending_node()
	_assert_eq(engine.get("s")["player_hp"], 37, "旅程：战斗读取地图当前 HP")
	h.force_win_battle(engine)
	_assert_eq(engine.get("s")["battle_won"], true, "旅程：战斗可结算胜利")
	_assert_eq(GameState.current_hp, 42, "旅程：胜利后 HP 回写并结算节点回复")
	_assert_true(GameState.map_accessible_ids.size() > 0, "旅程：战斗节点访问后开放下一层路线")

	var reward := h.open_reward_screen()
	h.collect_stones_and_continue(reward)
	_assert_eq(GameState.spirit_stones, 130, "旅程：普通战斗奖励灵石进入 GameState")
	reward.free()
	h.assert_no_pending_leaks(self, "旅程：奖励页消费后无奖励 pending 残留")


func test_reward_pick_and_skip_paths_update_deck_correctly() -> void:
	var h = FlowHarnessScript.new()
	h.start_new_run()
	GameState.pending_battle_node_type = "normal"

	var pick_reward := h.open_reward_screen()
	var before_pick := GameState.deck.size()
	var picked_id := h.pick_first_reward_card(pick_reward)
	_assert_true(not picked_id.is_empty(), "奖励：能选取第一张奖励卡")
	_assert_eq(GameState.deck.size(), before_pick + 1, "奖励：确认选卡会加入牌组")
	_assert_eq(GameState.deck[GameState.deck.size() - 1], picked_id, "奖励：加入的是被选中的卡牌 id")
	pick_reward.free()

	GameState.pending_battle_node_type = "normal"
	var skip_reward := h.open_reward_screen()
	var before_skip := GameState.deck.size()
	h.skip_card_reward(skip_reward)
	_assert_eq(GameState.deck.size(), before_skip, "奖励：跳过卡牌不改变牌组")
	skip_reward.free()


func test_shop_journey_updates_currency_and_inventory() -> void:
	var h = FlowHarnessScript.new()
	h.start_new_run()
	h.prepare_single_node_map("shop_probe", "shop", 1)
	var node_id := h.visit_first_node_of_type("shop")
	_assert_eq(node_id, "shop_probe", "黑市：访问指定黑市节点")
	_assert_eq(GameState.pending_battle_node_type, "shop", "黑市：地图写入 shop pending 类型")

	_assert_eq(GameState.buy_shop_card("1", 25), true, "黑市：购买卡牌成功")
	_assert_eq(GameState.spirit_stones, 75, "黑市：购买卡牌扣除灵石")
	_assert_eq(GameState.deck[GameState.deck.size() - 1], "1", "黑市：购买卡牌加入牌组")

	var item := {"id": "D-01", "name": "回春丹", "category": "elixir", "map_use": {"type": "heal", "amount": 10}}
	_assert_eq(GameState.buy_shop_item(item, 25), true, "黑市：购买物品成功")
	_assert_eq(GameState.spirit_stones, 50, "黑市：购买物品继续扣除灵石")
	_assert_eq(GameState.consumables.size(), 1, "黑市：物品进入背包")

	var artifact := {"id": "R-JOURNEY", "name": "旅程测试宝物", "rarity": "yellow"}
	_assert_eq(GameState.buy_shop_artifact(artifact, 30), true, "黑市：购买宝物成功")
	_assert_eq(GameState.spirit_stones, 20, "黑市：购买宝物扣除灵石")
	_assert_eq(GameState.artifacts.size(), 1, "黑市：宝物进入宝物栏")


func test_event_and_safe_nodes_do_not_leak_battle_reward_state() -> void:
	var h = FlowHarnessScript.new()
	h.start_new_run()
	GameState.current_hp = 40

	h.prepare_single_node_map("event_probe", "event", 1)
	_assert_eq(h.visit_first_node_of_type("event"), "event_probe", "事件：访问指定事件节点")
	_assert_eq(GameState.current_hp, 45, "事件：非战斗节点只结算一次节点回复")
	_assert_eq(GameState.pending_battle_node_type, "event", "事件：pending 类型保持事件节点")
	_assert_eq(GameState.get("pending_reward_stones_bonus"), 0, "事件：不产生奖励灵石 pending")
	_assert_eq(str(GameState.get("pending_reward_min_rarity")), "", "事件：不产生奖励稀有度 pending")

	GameState.current_hp = 40
	h.prepare_single_node_map("bonfire_probe", "bonfire", 1)
	_assert_eq(h.visit_first_node_of_type("bonfire"), "bonfire_probe", "篝火：访问指定篝火节点")
	_assert_eq(GameState.current_hp, 45, "篝火：非战斗节点只结算一次节点回复")
	h.assert_no_battle_reward_pending(self, "事件/篝火：无战斗奖励 pending 泄漏")


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
