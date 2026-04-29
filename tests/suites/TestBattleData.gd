## TestBattleData.gd
## 验证 CharacterDatabase / CardDatabase 中战斗数值的正确性。
extends RefCounted

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _cur: String = ""
var _objects_to_free: Array[Object] = []

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
	
	for o in _objects_to_free:
		if is_instance_valid(o):
			o.free()
	_objects_to_free.clear()
	
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

## 注：以下测试直接读取 all_card.json 文件内容进行验证。
## CardDatabase.get_card 在 headless 模式下因 res:// 路径限制无法正常工作，
## 因此改用 FileAccess 直接读取 JSON 来验证数据字段。

func _load_json_card(cid: int) -> Dictionary:
	## 直接通过 FileAccess 读取 JSON 中对应 id 的卡牌数据
	var path = ProjectSettings.globalize_path("res://") + "scripts/data/all_card.json"
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY or not data.has("cards"):
		return {}
	for c in data["cards"]:
		if c.get("id") == cid:
			return c
	return {}

func test_card_quick_sword_dao_hui() -> void:
	var c = _load_json_card(1)  # 点星剑法
	_assert_eq(c.get("cost_dao", -1), 3, "点星剑法(id=1) cost_dao = 3")

func test_card_ding_xin_zhou_dao_hui() -> void:
	var c = _load_json_card(20)  # 剑气护体
	_assert_eq(c.get("cost_dao", -1), 2, "剑气护体(id=20) cost_dao = 2")

func test_card_ling_jian_dian_xing_dao_hui() -> void:
	var c = _load_json_card(2)  # 枭首斩
	_assert_eq(c.get("cost_dao", -1), 2, "枭首斩(id=2) cost_dao = 2")

func test_card_ding_qi_ceng_dao_hui() -> void:
	var c = _load_json_card(21)  # 凝气层
	_assert_eq(c.get("cost_dao", -1), 4, "凝气层(id=21) cost_dao = 4")

func test_card_zhong_jian_beng_jia_dao_hui() -> void:
	var c = _load_json_card(8)  # 崩甲剑
	_assert_eq(c.get("cost_dao", -1), 4, "崩甲剑(id=8) cost_dao = 4")


# ── 内部工具 ──────────────────────────────────────

func _load_char_db() -> Object:
	var db: Object = load("res://scripts/data/CharacterDatabase.gd").new()
	db.call("_ready")
	_objects_to_free.append(db)
	return db

func _load_card_db() -> Object:
	var db: Object = load("res://scripts/data/CardDatabase.gd").new()
	db.call("_ready")
	_objects_to_free.append(db)
	return db

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
