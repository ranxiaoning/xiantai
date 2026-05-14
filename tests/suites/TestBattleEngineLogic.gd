## TestBattleEngineLogic.gd
## 验证 BattleEngine 纯逻辑方法（直接设置 s 字典，不走 init() 避免 Autoload 依赖）。
extends RefCounted

const BattleEngineScript = preload("res://scripts/BattleEngine.gd")

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestBattleEngineLogic ]")

	_t("test_block_reason_ling_li_short")
	_t("test_block_reason_dao_hui_short")
	_t("test_block_reason_both_short")
	_t("test_block_reason_sufficient")
	_t("test_block_reason_not_player_turn")
	_t("test_can_play_card_true")
	_t("test_can_play_card_false_ling_li")
	_t("test_can_play_card_false_dao_hui")
	_t("test_unplayable_curse_cannot_be_played")
	_t("test_lan_sui_dan_is_playable_curse_and_exhausts")
	_t("test_lan_sui_dan_inserted_curse_has_art_asset")
	_t("test_lan_sui_dan_end_turn_hp_loss_ignores_hu_ti_and_stays_in_hand")
	_t("test_consumable_effect_handles_player_resources")
	_t("test_consumable_effect_handles_enemy_and_control")
	_t("test_apply_battle_consumable_effect_checks_battle_end")
	_t("test_battle_init_applies_and_consumes_pending_map_effects")
	_t("test_battle_init_no_legacy_player_shield_field")
	_t("test_draw_cards_reshuffles_discard_without_recycling_hand")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ── 测试用例 ──────────────────────────────────────

func test_block_reason_ling_li_short() -> void:
	var e := _make_engine(1, 5, "player")
	var card := {"ling_li": 2, "dao_hui": 2}
	_assert_eq(e.call("get_play_block_reason", card), "灵力不足", "仅灵力不足 → 灵力不足")

func test_block_reason_dao_hui_short() -> void:
	var e := _make_engine(5, 1, "player")
	var card := {"ling_li": 2, "dao_hui": 2}
	_assert_eq(e.call("get_play_block_reason", card), "道慧不足", "仅道慧不足 → 道慧不足")

func test_block_reason_both_short() -> void:
	var e := _make_engine(0, 0, "player")
	var card := {"ling_li": 2, "dao_hui": 2}
	_assert_eq(e.call("get_play_block_reason", card), "灵力不足 · 道慧不足", "双不足 → 灵力不足 · 道慧不足")

func test_block_reason_sufficient() -> void:
	var e := _make_engine(5, 5, "player")
	var card := {"ling_li": 2, "dao_hui": 2}
	_assert_eq(e.call("get_play_block_reason", card), "", "资源充足 → 空字符串")

func test_block_reason_not_player_turn() -> void:
	var e := _make_engine(0, 0, "enemy")
	var card := {"ling_li": 2, "dao_hui": 2}
	_assert_eq(e.call("get_play_block_reason", card), "", "非玩家回合 → 空字符串")

func test_can_play_card_true() -> void:
	var e := _make_engine(3, 3, "player")
	var card := {"ling_li": 2, "dao_hui": 2}
	_assert_true(e.call("can_play_card", card), "资源充足时 can_play_card = true")

func test_can_play_card_false_ling_li() -> void:
	var e := _make_engine(1, 5, "player")
	var card := {"ling_li": 2, "dao_hui": 2}
	_assert_true(not e.call("can_play_card", card), "灵力不足时 can_play_card = false")

func test_can_play_card_false_dao_hui() -> void:
	var e := _make_engine(5, 1, "player")
	var card := {"ling_li": 2, "dao_hui": 2}
	_assert_true(not e.call("can_play_card", card), "道慧不足时 can_play_card = false")


func test_unplayable_curse_cannot_be_played() -> void:
	var e := _make_engine(5, 5, "player")
	var card := {"id": "an_shang", "name": "暗伤", "card_type": "curse", "ling_li": 0, "dao_hui": 0, "keywords": ["unplayable"]}
	_assert_true(not e.call("can_play_card", card), "禁锢污染牌不可打出")
	_assert_eq(e.call("get_play_block_reason", card), "禁锢", "禁锢污染牌阻塞原因为禁锢")


func test_lan_sui_dan_is_playable_curse_and_exhausts() -> void:
	var e := _make_consumable_engine()
	var st: Dictionary = e.get("s")
	st["player_ling_li"] = 2
	st["player_dao_hui"] = 0
	var card := {
		"id": "lan_sui_dan",
		"name": "烂髓丹",
		"card_type": "curse",
		"ling_li": 2,
		"dao_hui": 0,
		"keywords": ["exhaust"],
		"playable_curse": true,
		"is_curse": true,
	}
	st["hand"] = [card]
	e.set("s", st)
	_assert_true(e.call("can_play_card", card), "烂髓丹资源足够时可打出")
	e.call("play_card", card)
	st = e.get("s")
	_assert_eq(st["player_ling_li"], 0, "烂髓丹打出消耗2点灵力")
	_assert_eq((st["hand"] as Array).size(), 0, "烂髓丹打出后离开手牌")
	_assert_eq((st["discard_pile"] as Array).size(), 0, "烂髓丹带耗尽，不进入弃牌堆")


func test_lan_sui_dan_inserted_curse_has_art_asset() -> void:
	var e := _make_consumable_engine()
	e.call("_insert_curse_card", {"card_id": "lan_sui_dan", "target": "hand"})
	var st: Dictionary = e.get("s")
	_assert_eq((st["hand"] as Array).size(), 1, "烂髓丹可被塞入手牌")
	var card: Dictionary = (st["hand"] as Array)[0]
	var art_path := str(card.get("art_path", ""))
	_assert_eq(art_path, "res://assets/card/art/lan_sui_dan.png", "烂髓丹带专属立绘路径")
	_assert_true(FileAccess.file_exists(art_path), "烂髓丹专属立绘资源存在")


func test_lan_sui_dan_end_turn_hp_loss_ignores_hu_ti_and_stays_in_hand() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.current_hp = 40
	var e := _make_consumable_engine()
	var st: Dictionary = e.get("s")
	st["player_hp"] = 40
	st["player_hu_ti"] = 99
	st["player_ling_li"] = 0
	st["player_ling_li_regen"] = 0
	st["player_ling_li_base_regen"] = 0
	st["player_dao_hui"] = 4
	st["player_dao_hui_max"] = 4
	st["hand"] = [
		{"id": "lan_sui_dan", "name": "烂髓丹", "card_type": "curse", "is_curse": true, "playable_curse": true, "end_turn_hp_loss": 5, "keywords": ["exhaust"]},
		{"id": "safe", "name": "留手牌", "card_type": "skill", "keywords": []},
	]
	st["draw_pile"] = []
	st["discard_pile"] = []
	st["enemy_data"] = {"id": "test_enemy", "name": "测试敌人", "actions": [], "action_cycle": []}
	e.set("s", st)
	e.call("end_turn")
	st = e.get("s")
	_assert_eq(st["player_hp"], 35, "烂髓丹留手无视护体直接损失5HP")
	_assert_eq(st["player_hu_ti"], 99, "烂髓丹留手损血不消耗护体")
	_assert_eq(GameState.current_hp, 35, "烂髓丹留手损血同步 GameState.current_hp")
	_assert_eq((st["hand"] as Array).size(), 2, "烂髓丹留手反噬后仍留在手牌")
	_assert_eq((st["hand"] as Array)[0].get("id", ""), "lan_sui_dan", "烂髓丹未打出不会自动耗尽")
	_assert_eq((st["hand"] as Array)[1].get("id", ""), "safe", "非污染留手牌仍保留")


func test_consumable_effect_handles_player_resources() -> void:
	var e := _make_consumable_engine()
	_assert_true(e.has_method("apply_consumable_effect"), "BattleEngine 有 apply_consumable_effect 钩子")
	if not e.has_method("apply_consumable_effect"):
		return
	e.call("apply_consumable_effect", {"type": "compound", "effects": [
		{"type": "heal", "amount": 10},
		{"type": "hu_ti", "amount": 6},
		{"type": "ling_li", "amount": 3},
		{"type": "dao_hui", "amount": 2},
		{"type": "dao_xing", "amount": 1},
		{"type": "draw", "amount": 2},
	]})
	var st: Dictionary = e.get("s")
	_assert_eq(st["player_hp"], 50, "战斗物品：回复生命")
	_assert_eq(st["player_hu_ti"], 6, "战斗物品：获得护体")
	_assert_eq(st["player_ling_li"], 3, "战斗物品：获得灵力")
	_assert_eq(st["player_dao_hui"], 2, "战斗物品：获得道慧")
	_assert_eq(st["player_dao_xing"], 1, "战斗物品：获得道行")
	_assert_eq((st["hand"] as Array).size(), 2, "战斗物品：抽牌")


func test_consumable_effect_handles_enemy_and_control() -> void:
	var e := _make_consumable_engine()
	_assert_true(e.has_method("apply_consumable_effect"), "BattleEngine 有 apply_consumable_effect 钩子")
	if not e.has_method("apply_consumable_effect"):
		return
	var st: Dictionary = e.get("s")
	st["player_statuses"] = {"ku_jie": 2, "lie_shang": 1}
	st["enemy_dao_xing"] = 3
	e.set("s", st)
	e.call("apply_consumable_effect", {"type": "compound", "effects": [
		{"type": "damage", "amount": 10},
		{"type": "enemy_status", "key": "lie_shang", "stacks": 1},
		{"type": "cleanse", "amount": 1},
		{"type": "delay_enemy_action", "amount": 1},
		{"type": "enemy_dao_xing", "amount": -2},
		{"type": "death_save", "amount": 1},
	]})
	st = e.get("s")
	_assert_eq(st["enemy_hp"], 40, "战斗物品：造成伤害")
	_assert_eq(st["enemy_statuses"].get("lie_shang", 0), 1, "战斗物品：施加敌方状态")
	_assert_eq((st["player_statuses"] as Dictionary).size(), 1, "战斗物品：清除负面状态")
	_assert_eq(st.get("enemy_action_delay", 0), 1, "战斗物品：延后敌方行动")
	_assert_eq(st.get("enemy_dao_xing", 0), 1, "战斗物品：降低敌方道行")
	_assert_eq(st.get("death_save_charges", 0), 1, "战斗物品：预置濒死保护")


func test_apply_battle_consumable_effect_checks_battle_end() -> void:
	var e := _make_consumable_engine()
	_assert_true(e.has_method("apply_battle_consumable_effect"), "BattleEngine 有战斗物品公开结算入口")
	if not e.has_method("apply_battle_consumable_effect"):
		return
	e.call("apply_battle_consumable_effect", {"type": "damage", "amount": 99})
	var st: Dictionary = e.get("s")
	_assert_eq(st.get("phase", ""), "over", "战斗物品击杀敌人后进入结束阶段")
	_assert_eq(st.get("battle_won", false), true, "战斗物品击杀敌人后判定胜利")


func test_battle_init_applies_and_consumes_pending_map_effects() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.set("pending_battle_consumable_effects", [
		{"type": "hu_ti", "amount": 9},
		{"type": "dao_xing", "amount": 1},
	])
	var e: Object = BattleEngineScript.new()
	var enemy := {
		"id": "test_enemy",
		"name": "测试敌人",
		"hp": 30,
		"actions": [],
		"action_cycle": [],
	}
	e.call("init", CharacterDatabase.get_character("chen_tian_feng"), ["1", "2", "20"], enemy)
	var st: Dictionary = e.get("s")
	var pending = GameState.get("pending_battle_consumable_effects")
	_assert_eq(st.get("player_hu_ti", 0), int(CharacterDatabase.get_character("chen_tian_feng").get("hu_ti", 0)) + 9, "BattleEngine.init 应用地图登记的护体")
	_assert_eq(st.get("player_dao_xing", 0), int(CharacterDatabase.get_character("chen_tian_feng").get("talent_dao_xing", 0)) + 1, "BattleEngine.init 应用地图登记的道行")
	_assert_true(pending is Array and (pending as Array).is_empty(), "BattleEngine.init 读取并清空待结算战斗物品")


func test_battle_init_no_legacy_player_shield_field() -> void:
	GameState.start_run("chen_tian_feng")
	var e: Object = BattleEngineScript.new()
	e.call("init", CharacterDatabase.get_character("chen_tian_feng"), [], {
		"id": "test_enemy",
		"name": "测试敌人",
		"hp": 30,
		"actions": [],
		"action_cycle": [],
	})
	var st: Dictionary = e.get("s")
	_assert_true(not st.has("player_shield"), "BattleEngine 状态不再暴露 player_shield 旧字段")


func test_draw_cards_reshuffles_discard_without_recycling_hand() -> void:
	var e := _make_consumable_engine()
	var st: Dictionary = e.get("s")
	st["draw_pile"] = []
	st["hand"] = [{"id": "held", "name": "已有手牌"}]
	st["discard_pile"] = [{"id": "curse", "name": "暗伤", "is_curse": true}]
	st["hand_size"] = 3
	e.set("s", st)
	e.call("_draw_cards", 1)
	st = e.get("s")
	_assert_eq((st["hand"] as Array).size(), 2, "抽牌堆空时只洗弃牌堆，不回收当前手牌")
	_assert_eq((st["discard_pile"] as Array).size(), 0, "洗牌后弃牌堆清空")


# ── 工具 ──────────────────────────────────────────

func _make_engine(ling_li: int, dao_hui: int, phase: String) -> Object:
	var e: Object = BattleEngineScript.new()
	e.set("s", {"player_ling_li": ling_li, "player_dao_hui": dao_hui, "phase": phase})
	return e


func _make_consumable_engine() -> Object:
	var e: Object = BattleEngineScript.new()
	e.set("s", {
		"player_hp": 40,
		"player_hp_max": 60,
		"player_hu_ti": 0,
		"player_ling_li": 0,
		"player_ling_li_max": 20,
		"player_dao_hui": 0,
		"player_dao_hui_max": 10,
		"player_dao_xing": 0,
		"player_damage_mult": 1.0,
		"player_statuses": {},
		"draw_pile": [
			{"id": "test_1", "name": "测试牌1"},
			{"id": "test_2", "name": "测试牌2"},
		],
		"hand": [],
		"discard_pile": [],
		"hand_size": 3,
		"next_attack_bonus": 0,
		"enemy_hp": 50,
		"enemy_hp_max": 50,
		"enemy_hu_ti": 0,
		"enemy_statuses": {},
		"enemy_data": {"id": "enemy", "name": "测试敌人", "actions": []},
		"enemy_action_idx": 0,
		"enemy_action_delay": 0,
		"enemy_dao_xing": 0,
		"death_save_charges": 0,
		"phase": "player",
		"battle_won": false,
	})
	return e


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
