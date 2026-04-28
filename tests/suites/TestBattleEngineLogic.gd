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


# ── 工具 ──────────────────────────────────────────

func _make_engine(ling_li: int, dao_hui: int, phase: String) -> Object:
	var e: Object = BattleEngineScript.new()
	e.set("s", {"player_ling_li": ling_li, "player_dao_hui": dao_hui, "phase": phase})
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
