## TestSpiritStones.gd
## 验证灵石系统的初始值与加减逻辑。
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestSpiritStones ]")
	_t("test_initial_spirit_stones")
	_t("test_add_spirit_stones")
	_t("test_get_all_cards_not_empty")
	_t("test_get_all_cards_have_rarity")
	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_initial_spirit_stones() -> void:
	GameState.start_run("chen_tian_feng")
	_assert_eq(GameState.spirit_stones, 100, "start_run 后初始灵石应为 100")

func test_add_spirit_stones() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.add_spirit_stones(30)
	_assert_eq(GameState.spirit_stones, 130, "加 30 后应为 130")
	GameState.add_spirit_stones(60)
	_assert_eq(GameState.spirit_stones, 190, "再加 60 后应为 190")

func test_get_all_cards_not_empty() -> void:
	var cards := CardDatabase.get_all_cards()
	_assert_true(cards.size() > 0, "get_all_cards 返回非空数组")

func test_get_all_cards_have_rarity() -> void:
	var cards := CardDatabase.get_all_cards()
	_assert_true(cards[0].has("rarity"), "卡牌字典含 rarity 字段")


# ── 断言工具 ──────────────────────────────────────────────────

func _t(method: String) -> void:
	call(method)

func _assert_eq(a, b, msg: String) -> void:
	if a == b:
		_pass_count += 1
		_lines.append("  ✅ " + msg)
	else:
		_fail_count += 1
		_lines.append("  ❌ " + msg + " （期望 %s，实际 %s）" % [str(b), str(a)])

func _assert_true(cond: bool, msg: String) -> void:
	if cond:
		_pass_count += 1
		_lines.append("  ✅ " + msg)
	else:
		_fail_count += 1
		_lines.append("  ❌ " + msg)
