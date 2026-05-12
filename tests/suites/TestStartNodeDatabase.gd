## TestStartNodeDatabase.gd
## 验证起始节点起源祝福池数据正确性。
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestStartNodeDatabase ]")
	_t("test_pool_size")
	_t("test_weight_sum")
	_t("test_required_fields")
	_t("test_roll_three_count")
	_t("test_roll_three_distinct")
	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_pool_size() -> void:
	_assert_eq(StartEventDatabase.START_POOL.size(), 8, "START_POOL 有 8 组祝福")


func test_weight_sum() -> void:
	var total := 0
	for b in StartEventDatabase.START_POOL:
		total += int(b.get("weight", 0))
	_assert_eq(total, 102, "权重总计 == 102")


func test_required_fields() -> void:
	for b in StartEventDatabase.START_POOL:
		var id: String = str(b.get("id", ""))
		_assert_true(b.has("name") and not str(b.get("name", "")).is_empty(), "%s 有 name 字段" % id)
		_assert_true(b.has("desc") and not str(b.get("desc", "")).is_empty(), "%s 有 desc 字段" % id)
		_assert_true(b.has("effects") and b["effects"] is Array, "%s 有 effects 字段" % id)


func test_roll_three_count() -> void:
	var result: Array = StartEventDatabase.roll_three(12345)
	_assert_eq(result.size(), 3, "roll_three 返回 3 个结果")


func test_roll_three_distinct() -> void:
	var result: Array = StartEventDatabase.roll_three(99999)
	var ids: Array[String] = []
	for b in result:
		ids.append(str(b.get("id", "")))
	var has_dup := false
	for id in ids:
		if ids.count(id) > 1:
			has_dup = true
			break
	_assert_true(not has_dup, "roll_three 结果无重复")


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
