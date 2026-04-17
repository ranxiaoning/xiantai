## TestBattleData.gd
## 验证 CharacterDatabase / CardDatabase 中战斗数值的正确性。
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _cur: String = ""


func run_all() -> Dictionary:
	_lines.append("\n[ TestBattleData ]")

	_t("test_chen_tian_feng_dao_hui_max")
	_t("test_chen_tian_feng_skill_dao_hui_cost")
	_t("test_card_quick_sword_dao_hui")
	_t("test_card_ding_xin_zhou_dao_hui")
	_t("test_card_ling_jian_dian_xing_dao_hui")
	_t("test_card_ding_qi_ceng_dao_hui")
	_t("test_card_zhong_jian_beng_jia_dao_hui")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ── 测试用例 ──────────────────────────────────────

func test_chen_tian_feng_dao_hui_max() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	_assert_eq(c.get("dao_hui_max", -1), 6, "程天锋 dao_hui_max = 6")

func test_chen_tian_feng_skill_dao_hui_cost() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	_assert_eq(c.get("skill_dao_hui_cost", -1), 6, "程天锋 skill_dao_hui_cost = 6")

func test_card_quick_sword_dao_hui() -> void:
	var db := _load_card_db()
	var card: Dictionary = db.get_card("quick_sword_pi_shan")
	_assert_eq(card.get("dao_hui", -1), 2, "快剑·劈山 dao_hui = 2")

func test_card_ding_xin_zhou_dao_hui() -> void:
	var db := _load_card_db()
	var card: Dictionary = db.get_card("ding_xin_zhou")
	_assert_eq(card.get("dao_hui", -1), 2, "定心咒 dao_hui = 2")

func test_card_ling_jian_dian_xing_dao_hui() -> void:
	var db := _load_card_db()
	var card: Dictionary = db.get_card("ling_jian_dian_xing")
	_assert_eq(card.get("dao_hui", -1), 2, "灵剑·点星 dao_hui = 2")

func test_card_ding_qi_ceng_dao_hui() -> void:
	var db := _load_card_db()
	var card: Dictionary = db.get_card("ding_qi_ceng")
	_assert_eq(card.get("dao_hui", -1), 3, "凝气层 dao_hui = 3")

func test_card_zhong_jian_beng_jia_dao_hui() -> void:
	var db := _load_card_db()
	var card: Dictionary = db.get_card("zhong_jian_beng_jia")
	_assert_eq(card.get("dao_hui", -1), 4, "重剑·崩甲 dao_hui = 4")


# ── 内部工具 ──────────────────────────────────────

func _load_char_db() -> Object:
	return load("res://scripts/data/CharacterDatabase.gd").new()

func _load_card_db() -> Object:
	return load("res://scripts/data/CardDatabase.gd").new()

func _t(method: String) -> void:
	_cur = method
	call(method)

func _assert_eq(a, b, label: String) -> void:
	if a == b:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 期望 %s，实际 %s" % [label, str(b), str(a)])
