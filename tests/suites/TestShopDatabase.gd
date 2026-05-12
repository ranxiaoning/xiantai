## TestShopDatabase.gd
## 验证黑市静态数据、价格表与库存生成规则。
extends RefCounted

const SHOP_DB_PATH := "res://scripts/data/ShopDatabase.gd"

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _objects_to_free: Array[Object] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestShopDatabase ]")
	_t("test_shop_database_script_exists")
	_t("test_item_and_artifact_totals")
	_t("test_items_include_three_categories")
	_t("test_generate_stock_counts")
	_t("test_card_upgrade_and_remove_prices")
	_t("test_owned_artifacts_do_not_appear_in_stock")

	for o in _objects_to_free:
		if is_instance_valid(o):
			o.free()
	_objects_to_free.clear()

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_shop_database_script_exists() -> void:
	_assert_true(FileAccess.file_exists(SHOP_DB_PATH), "ShopDatabase.gd 存在")


func test_item_and_artifact_totals() -> void:
	var db := _load_shop_db()
	if db == null:
		return
	_assert_eq(db.call("get_all_items").size(), 45, "黑市物品总数为 45")
	_assert_eq(db.call("get_all_artifacts").size(), 15, "黑市宝物总数为 15")


func test_items_include_three_categories() -> void:
	var db := _load_shop_db()
	if db == null:
		return
	var cats := {}
	for item in db.call("get_all_items"):
		cats[item.get("category", "")] = true
	_assert_true(cats.has("elixir"), "物品包含丹药")
	_assert_true(cats.has("talisman"), "物品包含符箓")
	_assert_true(cats.has("formation"), "物品包含阵法")


func test_generate_stock_counts() -> void:
	var db := _load_shop_db()
	if db == null:
		return
	var stock: Dictionary = db.call("generate_stock", 4, [], 12345)
	_assert_eq((stock.get("cards", []) as Array).size(), 3, "每次黑市生成 3 张卡牌")
	_assert_eq((stock.get("items", []) as Array).size(), 4, "每次黑市生成 4 个物品")
	_assert_eq((stock.get("artifacts", []) as Array).size(), 2, "每次黑市生成 2 件宝物")


func test_card_upgrade_and_remove_prices() -> void:
	var db := _load_shop_db()
	if db == null:
		return
	_assert_eq(db.call("get_card_price", {"rarity": "黄品"}), 50, "黄品卡牌价格 50")
	_assert_eq(db.call("get_card_price", {"rarity": "玄品"}), 80, "玄品卡牌价格 80")
	_assert_eq(db.call("get_card_price", {"rarity": "地品"}), 150, "地品卡牌价格 150")
	_assert_eq(db.call("get_card_price", {"rarity": "天品"}), 300, "天品卡牌价格 300")
	_assert_eq(db.call("get_upgrade_price", "5"), 30, "黄品升级价格 30")
	_assert_eq(db.call("get_remove_price", 0), 50, "首次删牌价格 50")
	_assert_eq(db.call("get_remove_price", 3), 125, "第 4 次删牌价格 125")


func test_owned_artifacts_do_not_appear_in_stock() -> void:
	var db := _load_shop_db()
	if db == null:
		return
	var first_artifact: Dictionary = db.call("get_all_artifacts")[0]
	var stock: Dictionary = db.call("generate_stock", 4, [first_artifact["id"]], 12345)
	for art in stock.get("artifacts", []):
		_assert_true(art.get("id", "") != first_artifact["id"], "已拥有宝物不再出现在货架")


func _load_shop_db() -> Object:
	var script := load(SHOP_DB_PATH)
	if script == null:
		_fail("ShopDatabase.gd 可加载")
		return null
	var db: Object = script.new()
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


func _fail(label: String) -> void:
	_fail_count += 1
	_lines.append("  ✗ %s" % label)
