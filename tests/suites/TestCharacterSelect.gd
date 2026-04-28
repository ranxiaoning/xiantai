## TestCharacterSelect.gd
## 验证 CharacterDatabase 的门派/角色查询接口。
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _objects_to_free: Array[Object] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestCharacterSelect ]")

	_t("test_get_all_sects_has_wanjianmen")
	_t("test_get_sect_data_has_bg_path")
	_t("test_get_sect_characters_wanjianmen")
	_t("test_chen_tian_feng_has_portrait_path")
	_t("test_chen_tian_feng_sect_is_wanjianmen")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])

	for o in _objects_to_free:
		if is_instance_valid(o):
			o.free()
	_objects_to_free.clear()

	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_get_all_sects_has_wanjianmen() -> void:
	var db := _load_char_db()
	var sects: Array = db.call("get_all_sects")
	_assert_true(sects.has("万剑门"), "get_all_sects() 包含万剑门")

func test_get_sect_data_has_bg_path() -> void:
	var db := _load_char_db()
	var data: Dictionary = db.call("get_sect_data", "万剑门")
	_assert_true(data.has("bg_path"), "万剑门 sect_data 有 bg_path 字段")
	_assert_true(not (data.get("bg_path", "") as String).is_empty(), "万剑门 bg_path 非空")

func test_get_sect_characters_wanjianmen() -> void:
	var db := _load_char_db()
	var chars: Array = db.call("get_sect_characters", "万剑门")
	_assert_true(chars.size() >= 1, "万剑门至少有 1 个角色")

func test_chen_tian_feng_has_portrait_path() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	_assert_true(c.has("portrait_path"), "程天锋有 portrait_path 字段")
	_assert_true(not (c.get("portrait_path", "") as String).is_empty(), "程天锋 portrait_path 非空")

func test_chen_tian_feng_sect_is_wanjianmen() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	_assert_eq(c.get("sect", ""), "万剑门", "程天锋 sect = 万剑门")


func _load_char_db() -> Object:
	var db: Object = load("res://scripts/data/CharacterDatabase.gd").new()
	db.call("_ready")
	_objects_to_free.append(db)
	return db


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
