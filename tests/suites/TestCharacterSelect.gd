## TestCharacterSelect.gd
## 验证 CharacterDatabase 的门派/角色查询接口。
extends RefCounted

const CHARACTER_SELECT_SCENE := "res://scenes/CharacterSelect.tscn"

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
	_t("test_chen_tian_feng_portrait_resource_loads")
	_t("test_chen_tian_feng_sect_is_wanjianmen")
	_t("test_character_select_scene_loads")
	_t("test_character_select_scene_has_default_portrait")
	_t("test_character_select_required_nodes_exist")
	_t("test_portrait_uses_fit_layout")
	_t("test_chen_tian_feng_has_ui_required_fields")

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


func test_chen_tian_feng_portrait_resource_loads() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	var portrait_path := c.get("portrait_path", "") as String
	var texture := load(portrait_path) as Texture2D
	_assert_true(texture != null, "程天锋 portrait_path 可加载为 Texture2D")


func test_chen_tian_feng_sect_is_wanjianmen() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	_assert_eq(c.get("sect", ""), "万剑门", "程天锋 sect = 万剑门")


func test_character_select_scene_loads() -> void:
	var packed := load(CHARACTER_SELECT_SCENE) as PackedScene
	_assert_true(packed != null, "CharacterSelect.tscn 可加载为 PackedScene")
	if packed:
		var inst := packed.instantiate()
		_objects_to_free.append(inst)
		_assert_true(inst != null, "CharacterSelect.tscn 可实例化")


func test_character_select_scene_has_default_portrait() -> void:
	var inst := _load_scene_instance()
	if inst == null:
		_fail("CharacterSelect.tscn 实例为空")
		return
	var portrait := inst.find_child("Portrait", true, false) as TextureRect
	_assert_true(portrait != null and portrait.texture != null, "CharacterSelect.tscn 默认带程天锋立绘")


func test_character_select_required_nodes_exist() -> void:
	var inst := _load_scene_instance()
	if inst == null:
		_fail("CharacterSelect.tscn 实例为空")
		return
	for node_name in [
		"SectBar", "CharListBox", "CharName", "CharTitle", "PortraitStage", "Portrait", "Lore",
		"HPValue", "HPRegenValue", "LingLiValue", "LingLiRegenValue", "DaoHuiValue", "DmgValue",
		"TalentDesc", "SkillDesc", "StartBtn"
	]:
		_assert_true(inst.find_child(node_name, true, false) != null, "关键节点存在: %s" % node_name)

	var ling_li_label := inst.find_child("LingLiValue", true, false) as Label
	var ling_li_regen_label := inst.find_child("LingLiRegenValue", true, false) as Label
	_assert_eq(ling_li_label.text, "20", "灵力上限独立显示，不带括号回复")
	_assert_eq(ling_li_regen_label.text, "3/回合", "灵力回复独立显示")


func test_portrait_uses_fit_layout() -> void:
	var inst := _load_scene_instance()
	if inst == null:
		_fail("CharacterSelect.tscn instance is null")
		return
	var portrait := inst.find_child("Portrait", true, false) as TextureRect
	var stage := inst.find_child("PortraitStage", true, false) as Control
	var frame := inst.find_child("PortraitFrame", true, false) as PanelContainer
	_assert_true(portrait != null, "Portrait node exists")
	_assert_true(stage != null, "PortraitStage node exists")
	if portrait == null:
		return
	_assert_true(stage != null and portrait.get_parent() == stage, "Portrait is anchored inside PortraitStage")
	_assert_eq(portrait.anchor_left, 0.0, "Portrait left anchor is full-rect")
	_assert_eq(portrait.anchor_top, 0.0, "Portrait top anchor is full-rect")
	_assert_eq(portrait.anchor_right, 1.0, "Portrait right anchor is full-rect")
	_assert_eq(portrait.anchor_bottom, 1.0, "Portrait bottom anchor is full-rect")
	_assert_eq(portrait.offset_left, 0.0, "Portrait left offset is zero")
	_assert_eq(portrait.offset_top, 0.0, "Portrait top offset is zero")
	_assert_eq(portrait.offset_right, 0.0, "Portrait right offset is zero")
	_assert_eq(portrait.offset_bottom, 0.0, "Portrait bottom offset is zero")
	_assert_eq(portrait.custom_minimum_size, Vector2.ZERO, "Portrait has no fixed minimum size")
	_assert_eq(portrait.expand_mode, TextureRect.EXPAND_IGNORE_SIZE, "Portrait ignores texture size for layout")
	_assert_eq(portrait.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Portrait keeps full aspect-centered image")
	_assert_true(frame == null or frame.clip_contents, "PortraitFrame clips overflow")
	_assert_true(frame == null or frame.custom_minimum_size.y > 0.0, "PortraitFrame has an explicit visible height")
	_assert_true(frame == null or frame.size_flags_vertical == Control.SIZE_FILL, "PortraitFrame does not expand beyond visible height")


func test_chen_tian_feng_has_ui_required_fields() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	for key in [
		"name", "sect", "title", "lore", "portrait_path",
		"hp_max", "hp_regen", "ling_li_max", "ling_li_regen",
		"dao_hui_max", "damage_mult", "talent_name", "talent_desc",
		"skill_name", "skill_desc"
	]:
		_assert_true(c.has(key), "程天锋 UI 字段存在: %s" % key)


func _load_char_db() -> Object:
	var db: Object = load("res://scripts/data/CharacterDatabase.gd").new()
	db.call("_ready")
	_objects_to_free.append(db)
	return db


func _load_scene_instance() -> Node:
	var packed := load(CHARACTER_SELECT_SCENE) as PackedScene
	if packed == null:
		return null
	var inst := packed.instantiate()
	_objects_to_free.append(inst)
	return inst


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
