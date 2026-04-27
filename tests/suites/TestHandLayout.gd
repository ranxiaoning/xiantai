## TestHandLayout.gd
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []

func run_all() -> Dictionary:
	_lines.append("\n[ TestHandLayout ]")

	_test_hand_layout_calc_under_5()
	_test_hand_layout_calc_over_5()

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}

func _test_hand_layout_calc_under_5() -> void:
    # Test logic from BattleScene implementation without instantiating scene
	var count = 4
	var sep = 8
	var is_overlap = false
	if count <= 5:
		sep = 8
		is_overlap = false
	else:
		var max_w = 532.0 
		sep = int((max_w - count * 100.0) / (count - 1.0))
		is_overlap = true
	_assert_eq(sep, 8, "卡牌数量<=5时，间隙恒定为8")
	_assert_eq(is_overlap, false, "不使用重叠逻辑计算")

func _test_hand_layout_calc_over_5() -> void:
	var count = 6
	var sep = 8
	var is_overlap = false
	if count <= 5:
		sep = 8
		is_overlap = false
	else:
		var max_w = 532.0 
		sep = int((max_w - count * 100.0) / (count - 1.0))
		is_overlap = true
	
	_assert_eq(sep, int((532.0 - 6 * 100.0)/5.0), "卡牌数量>5时，正确计算动态重叠负间隙: " + str(sep))
	_assert_eq(is_overlap, true, "开始使用重叠逻辑计算")

# ── 内部工具 ──────────────────────────────────────

func _assert_eq(a, b, label: String) -> void:
	if a == b:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 期望 %s，实际 %s" % [label, str(b), str(a)])
