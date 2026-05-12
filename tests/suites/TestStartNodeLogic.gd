## TestStartNodeLogic.gd
## 验证起始节点起源祝福效果的真实可用性。
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestStartNodeLogic ]")
	_t("test_s01_sword_soul")
	_t("test_s02_devotion")
	_t("test_s03_greed")
	_t("test_s06_ling_li")
	_t("test_s08_memory")
	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func _setup_clean_run() -> void:
	GameState.start_run("chen_tian_feng")
	# 清空默认灵石和属性以便精确测试
	GameState.spirit_stones = 0
	GameState.artifacts.clear()
	GameState.dao_xing_battle_start = 0


func test_s01_sword_soul() -> void:
	_setup_clean_run()
	var base_dao_xing = GameState.character.get("talent_dao_xing", 0)
	var s01 = _get_start_node("S-01")
	StartEventDatabase.apply_instant_effects(s01["effects"])
	
	_assert_true(GameState.has_artifact("R-S01"), "S-01 赋予了 R-S01 宝物")
	
	# 验证战斗内效果
	var engine = _create_battle_engine()
	_assert_eq(engine.s["player_dao_xing"], base_dao_xing + 5, "R-S01 战斗开局道行增加 5 层")


func test_s02_devotion() -> void:
	_setup_clean_run()
	var old_hp_max = GameState.character["hp_max"]
	var s02 = _get_start_node("S-02")
	StartEventDatabase.apply_instant_effects(s02["effects"])
	
	_assert_eq(GameState.character["hp_max"], old_hp_max + 20, "S-02 生命上限 +20")
	_assert_true(GameState.has_artifact("R-S02"), "S-02 赋予了 R-S02 宝物")
	
	# 验证战斗内效果
	var engine = _create_battle_engine()
	_assert_eq(engine.s["player_shield"], 8, "R-S02 战斗开局获得 8 点护体(护盾)")


func test_s03_greed() -> void:
	_setup_clean_run()
	var s03 = _get_start_node("S-03")
	StartEventDatabase.apply_instant_effects(s03["effects"])
	
	_assert_eq(GameState.spirit_stones, 150, "S-03 获得 150 灵石")
	_assert_true(GameState.has_artifact("R-S03"), "S-03 赋予了 R-S03 宝物")
	
	# 验证商店折扣
	_assert_eq(GameState.get_shop_discount_pct(), 0.15, "R-S03 提供 15% 商店折扣")


func test_s06_ling_li() -> void:
	_setup_clean_run()
	var s06 = _get_start_node("S-06")
	StartEventDatabase.apply_instant_effects(s06["effects"])
	
	_assert_true(GameState.has_artifact("R-S06"), "S-06 赋予了 R-S06 宝物")
	
	# 验证战斗内效果
	var engine = _create_battle_engine()
	_assert_eq(engine.s["player_ling_li_max"], 22, "R-S06 灵力上限 +2 (20->22)")
	
	# 验证每回合回复
	engine.start_battle() # 回合1
	_assert_eq(engine.s["player_ling_li"], 3, "第1回合初始灵力为3")
	
	engine.end_turn() # 结束玩家回合，进入敌人回合，然后回玩家回合
	# 注意：BattleEngine 的 _enemy_turn 会自动调用 _start_player_turn
	_assert_eq(engine.s["player_ling_li"], 7, "第2回合灵力应为 3 + (3+1) = 7")


func test_s08_memory() -> void:
	_setup_clean_run()
	var base_dao_xing = GameState.character.get("talent_dao_xing", 0)
	var s08 = _get_start_node("S-08")
	StartEventDatabase.apply_instant_effects(s08["effects"])
	
	_assert_true(GameState.has_artifact("R-S08"), "S-08 赋予了 R-S08 宝物")
	
	# 验证战斗内效果
	var engine = _create_battle_engine()
	_assert_eq(engine.s["player_dao_xing"], base_dao_xing + 2, "R-S08 战斗开局道行增加 2 层")


func _get_start_node(id: String) -> Dictionary:
	for b in StartEventDatabase.START_POOL:
		if str(b.get("id", "")) == id:
			return b
	return {}


func _create_battle_engine() -> Object:
	var engine_script = load("res://scripts/BattleEngine.gd")
	var engine = engine_script.new()
	var enemy = {"id": "test", "name": "测试敌人", "hp": 100, "actions": []}
	engine.init(GameState.character, [], enemy)
	return engine


func _t(method: String) -> void:
	call(method)


func _assert_eq(a: Variant, b: Variant, label: String) -> void:
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
