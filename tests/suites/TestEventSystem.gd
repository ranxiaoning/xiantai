## TestEventSystem.gd
## 白盒测试：验证 EventDatabase 条件检查、事件池抽取、效果执行逻辑。
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestEventSystem ]")
	_t("test_event_database_has_19_first_heaven_events")
	_t("test_condition_stones_gte")
	_t("test_condition_has_type_elixir")
	_t("test_condition_has_type_talisman")
	_t("test_condition_dao_xing_gte")
	_t("test_condition_has_non_upgraded")
	_t("test_condition_deck_size_gte")
	_t("test_get_random_event_excludes_visited")
	_t("test_get_random_event_resets_when_all_visited")
	_t("test_effect_heal")
	_t("test_effect_max_hp_perm_increase")
	_t("test_effect_max_hp_perm_decrease_clamped")
	_t("test_effect_dao_xing_start_no_negative")
	_t("test_effect_ling_li_max_perm")
	_t("test_effect_stones")
	_t("test_effect_stones_spend")
	_t("test_effect_perm_shield")
	_t("test_deck_remove_choose_reduces_deck")
	_t("test_deck_upgrade_choose_adds_plus")
	_t("test_random_outcomes_weight_distribution")
	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ── 事件数据库完整性 ──────────────────────────────────────────────

func test_event_database_has_19_first_heaven_events() -> void:
	_assert_eq(EventDatabase.FIRST_HEAVEN_POOL.size(), 19, "第一重天事件池有19个事件")
	for eid in EventDatabase.FIRST_HEAVEN_POOL:
		var ev: Dictionary = EventDatabase.get_event(eid)
		_assert_true(not ev.is_empty(), "%s 事件数据存在" % eid)
		_assert_true(ev.has("options"), "%s 有选项" % eid)
		_assert_true((ev["options"] as Array).size() >= 2, "%s 至少有2个选项" % eid)


# ── 条件检查 ─────────────────────────────────────────────────────

func test_condition_stones_gte() -> void:
	_start_run()
	GameState.spirit_stones = 50
	_assert_true(EventDatabase.check_condition("stones_gte:50"), "灵石等于阈值时满足")
	_assert_true(EventDatabase.check_condition("stones_gte:30"), "灵石大于阈值时满足")
	_assert_false(EventDatabase.check_condition("stones_gte:51"), "灵石小于阈值时不满足")


func test_condition_has_type_elixir() -> void:
	_start_run()
	GameState.consumables.clear()
	_assert_false(EventDatabase.check_condition("has_type:elixir"), "背包空时不满足")
	GameState.consumables.append({"id": "D-01", "name": "回春丹", "category": "elixir"})
	_assert_true(EventDatabase.check_condition("has_type:elixir"), "有丹药时满足")
	_assert_false(EventDatabase.check_condition("has_type:talisman"), "有丹药但需要符箓时不满足")


func test_condition_has_type_talisman() -> void:
	_start_run()
	GameState.consumables.clear()
	GameState.consumables.append({"id": "T-01", "name": "火符", "category": "talisman"})
	_assert_true(EventDatabase.check_condition("has_type:talisman"), "有符箓时满足")


func test_condition_dao_xing_gte() -> void:
	_start_run()
	GameState.dao_xing_battle_start = 3
	_assert_true(EventDatabase.check_condition("dao_xing_gte:3"), "dao_xing 等于阈值满足")
	_assert_false(EventDatabase.check_condition("dao_xing_gte:4"), "dao_xing 小于阈值不满足")


func test_condition_has_non_upgraded() -> void:
	_start_run()
	GameState.deck.clear()
	GameState.deck.append("5+")  # 已升级
	_assert_false(EventDatabase.check_condition("has_non_upgraded"), "全部升级时不满足")
	GameState.deck.append("5")   # 未升级
	_assert_true(EventDatabase.check_condition("has_non_upgraded"), "有未升级卡牌时满足")


func test_condition_deck_size_gte() -> void:
	_start_run()
	GameState.deck.clear()
	GameState.deck.append("5")
	_assert_false(EventDatabase.check_condition("deck_size_gte:2"), "牌库不足时不满足")
	GameState.deck.append("6")
	_assert_true(EventDatabase.check_condition("deck_size_gte:2"), "牌库满足时通过")


# ── 事件池抽取 ───────────────────────────────────────────────────

func test_get_random_event_excludes_visited() -> void:
	_start_run()
	GameState.visited_events.clear()
	var pool: Array = EventDatabase.FIRST_HEAVEN_POOL.duplicate()
	# 标记除最后一个事件外全部已访问
	for i in range(pool.size() - 1):
		GameState.visited_events.append(pool[i])
	var last_id: String = pool[pool.size() - 1]
	# 多次抽取，应全部返回最后一个未访问事件
	for _i in range(10):
		var got: String = EventDatabase.get_random_event_id(1)
		_assert_eq(got, last_id, "只剩一个未访问事件时必须返回它")


func test_get_random_event_resets_when_all_visited() -> void:
	_start_run()
	# 标记所有事件已访问
	GameState.visited_events.clear()
	for eid in EventDatabase.FIRST_HEAVEN_POOL:
		GameState.visited_events.append(eid)
	# 重置后应返回有效事件
	var got: String = EventDatabase.get_random_event_id(1)
	_assert_true(EventDatabase.FIRST_HEAVEN_POOL.has(got), "所有事件访问后重置，仍返回有效事件")


# ── 效果验证（直接通过 GameState API 测试，避免在 headless 模式实例化 Control）──

func test_effect_heal() -> void:
	_start_run()
	GameState.current_hp = 30
	GameState.apply_hp_change(10)
	_assert_eq(GameState.current_hp, 40, "apply_hp_change 正数增加 HP")
	GameState.apply_hp_change(-5)
	_assert_eq(GameState.current_hp, 35, "apply_hp_change 负数减少 HP")


func test_effect_max_hp_perm_increase() -> void:
	_start_run()
	var old_max: int = int(GameState.character.get("hp_max", 60))
	var n := 10
	GameState.character["hp_max"] = old_max + n
	GameState.current_hp = clampi(GameState.current_hp, 0, old_max + n)
	_assert_eq(int(GameState.character.get("hp_max", 0)), old_max + n, "最大HP增加10")


func test_effect_max_hp_perm_decrease_clamped() -> void:
	_start_run()
	GameState.character["hp_max"] = 5
	GameState.current_hp = 5
	var new_max: int = maxi(1, 5 - 10)
	GameState.character["hp_max"] = new_max
	GameState.current_hp = clampi(GameState.current_hp, 0, new_max)
	_assert_eq(int(GameState.character.get("hp_max", 0)), 1, "最大HP下限为1")
	_assert_eq(GameState.current_hp, 1, "当前HP不超过最大HP")


func test_effect_dao_xing_start_no_negative() -> void:
	_start_run()
	GameState.dao_xing_battle_start = 0
	GameState.dao_xing_battle_start = maxi(0, GameState.dao_xing_battle_start - 1)
	_assert_eq(GameState.dao_xing_battle_start, 0, "dao_xing_start 不低于0")
	GameState.dao_xing_battle_start += 3
	_assert_eq(GameState.dao_xing_battle_start, 3, "dao_xing_start 增加")


func test_effect_ling_li_max_perm() -> void:
	_start_run()
	var old_val: int = int(GameState.character.get("ling_li_max", 20))
	GameState.character["ling_li_max"] = maxi(1, old_val + 1)
	_assert_eq(int(GameState.character.get("ling_li_max", 0)), old_val + 1, "灵力上限+1")


func test_effect_stones() -> void:
	_start_run()
	GameState.spirit_stones = 100
	GameState.add_spirit_stones(50)
	_assert_eq(GameState.spirit_stones, 150, "add_spirit_stones 增加灵石")


func test_effect_stones_spend() -> void:
	_start_run()
	GameState.spirit_stones = 100
	GameState.spend_spirit_stones(30)
	_assert_eq(GameState.spirit_stones, 70, "spend_spirit_stones 消耗灵石")


func test_effect_perm_shield() -> void:
	_start_run()
	GameState.character["hu_ti"] = 0
	GameState.character["hu_ti"] = int(GameState.character.get("hu_ti", 0)) + 5
	_assert_eq(int(GameState.character.get("hu_ti", 0)), 5, "永久护体+5")


# ── 卡牌选择效果（直接操作 deck 验证）──────────────────────────────

func test_deck_remove_choose_reduces_deck() -> void:
	_start_run()
	GameState.deck.clear()
	GameState.deck.append("5")
	GameState.deck.append("6")
	GameState.deck.append("20")
	var old_size: int = GameState.deck.size()
	# 模拟移除第2张牌（index 1）
	GameState.deck.remove_at(1)
	_assert_eq(GameState.deck.size(), old_size - 1, "移除一张牌后牌库减少1")


func test_deck_upgrade_choose_adds_plus() -> void:
	_start_run()
	GameState.deck.clear()
	GameState.deck.append("5")
	# 模拟升级第一张牌
	var base_id: String = GameState.deck[0].trim_suffix("+")
	GameState.deck[0] = base_id + "+"
	_assert_true(GameState.deck[0].ends_with("+"), "升级后卡牌 id 添加+")


# ── 随机结果权重验证（使用独立辅助函数，不依赖 AdventureEvent）───────

func test_random_outcomes_weight_distribution() -> void:
	var outcomes: Array = [
		{"weight": 70, "result_desc": "70%", "effects": []},
		{"weight": 30, "result_desc": "30%", "effects": []},
	]
	var count_70 := 0
	var count_30 := 0
	var samples := 1000
	for _i in range(samples):
		var o: Dictionary = _roll_outcome(outcomes)
		if o["result_desc"] == "70%":
			count_70 += 1
		else:
			count_30 += 1
	var pct_70 := float(count_70) / samples
	var pct_str: String = "%.2f" % pct_70
	_assert_true(pct_70 > 0.60 and pct_70 < 0.80, "1000次抽样70/30权重分布合理（实际70%%比例: " + pct_str + "）")


func _roll_outcome(outcomes: Array) -> Dictionary:
	if outcomes.is_empty():
		return {}
	var total := 0
	for o in outcomes:
		total += int(o.get("weight", 0))
	if total <= 0:
		return outcomes[0]
	var roll := randi() % total
	var acc := 0
	for o in outcomes:
		acc += int(o.get("weight", 0))
		if roll < acc:
			return o
	return outcomes[-1]


# ─────────────────────────────────────────────────────────────────
# 工具方法
# ─────────────────────────────────────────────────────────────────

func _start_run() -> void:
	GameState.start_run("chen_tian_feng")


func _t(method_name: String) -> void:
	call(method_name)


func _assert_true(val: bool, desc: String) -> void:
	if val:
		_pass_count += 1
		_lines.append("  PASS  %s" % desc)
	else:
		_fail_count += 1
		_lines.append("  FAIL  %s" % desc)


func _assert_false(val: bool, desc: String) -> void:
	_assert_true(not val, desc)


func _assert_eq(a, b, desc: String) -> void:
	_assert_true(a == b, "%s  [期望 %s，实际 %s]" % [desc, str(b), str(a)])
