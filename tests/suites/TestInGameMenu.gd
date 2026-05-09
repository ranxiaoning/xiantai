## tests/suites/TestInGameMenu.gd
## 测试 GameState.reset_run() 的状态清除行为。
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestInGameMenu ]")
	_test_reset_clears_character()
	_test_reset_clears_deck()
	_test_reset_clears_map_state()
	_test_reset_clears_inventory()
	_test_reset_is_idempotent()
	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func _test_reset_clears_character() -> void:
	GameState.character = {"name": "程天锋", "hp_max": 60}
	GameState.current_hp = 45
	GameState.reset_run()
	_assert_true(GameState.character.is_empty(), "reset_run：character 清空")
	_assert_eq(GameState.current_hp, 0, "reset_run：current_hp 归零")


func _test_reset_clears_deck() -> void:
	GameState.deck = ["card_001", "card_002"]
	GameState.reset_run()
	_assert_true(GameState.deck.is_empty(), "reset_run：deck 清空")


func _test_reset_clears_map_state() -> void:
	GameState.map_started = true
	GameState.map_current_floor = 5
	GameState.map_last_node_id = "node_3_1"
	GameState.reset_run()
	_assert_eq(GameState.map_started, false, "reset_run：map_started 归 false")
	_assert_eq(GameState.map_current_floor, 0, "reset_run：map_current_floor 归零")
	_assert_eq(GameState.map_last_node_id, "", "reset_run：map_last_node_id 清空")


func _test_reset_clears_inventory() -> void:
	GameState.consumables = [{"id": "potion"}]
	GameState.artifacts = [{"id": "ring"}]
	GameState.spirit_stones = 250
	GameState.reset_run()
	_assert_true(GameState.consumables.is_empty(), "reset_run：consumables 清空")
	_assert_true(GameState.artifacts.is_empty(), "reset_run：artifacts 清空")
	_assert_eq(GameState.spirit_stones, 0, "reset_run：spirit_stones 归零")


func _test_reset_is_idempotent() -> void:
	GameState.reset_run()
	GameState.reset_run()
	_assert_true(GameState.character.is_empty(), "reset_run 幂等：double reset 后 character 仍为空")
	_assert_true(GameState.deck.is_empty(), "reset_run 幂等：double reset 后 deck 仍为空")


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
		_lines.append("  ✗ %s  ← 条件为 false" % label)
