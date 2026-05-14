## TestCharacterSelect.gd
## Verifies CharacterDatabase and CharacterSelect scene contracts.
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
	_t("test_chen_tian_feng_cutout_resource_loads")
	_t("test_chen_tian_feng_sect_is_wanjianmen")
	_t("test_character_select_scene_loads")
	_t("test_character_select_scene_has_default_portrait")
	_t("test_character_select_required_nodes_exist")
	_t("test_start_button_is_inside_stats_card")
	_t("test_hero_stage_aligns_with_stats_card_top")
	_t("test_character_select_buttons_use_flat_styles")
	_t("test_portrait_uses_fit_layout")
	_t("test_chen_tian_feng_has_ui_required_fields")

	_lines.append("  -> %d passed  %d failed" % [_pass_count, _fail_count])

	for o in _objects_to_free:
		if is_instance_valid(o):
			o.free()
	_objects_to_free.clear()

	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_get_all_sects_has_wanjianmen() -> void:
	var db := _load_char_db()
	var sects: Array = db.call("get_all_sects")
	_assert_true(sects.has("万剑门"), "get_all_sects() includes 万剑门")


func test_get_sect_data_has_bg_path() -> void:
	var db := _load_char_db()
	var data: Dictionary = db.call("get_sect_data", "万剑门")
	_assert_true(data.has("bg_path"), "万剑门 sect_data has bg_path")
	_assert_true(not (data.get("bg_path", "") as String).is_empty(), "万剑门 bg_path is non-empty")


func test_get_sect_characters_wanjianmen() -> void:
	var db := _load_char_db()
	var chars: Array = db.call("get_sect_characters", "万剑门")
	_assert_true(chars.size() >= 1, "万剑门 has at least one character")


func test_chen_tian_feng_has_portrait_path() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	_assert_true(c.has("portrait_path"), "程天锋 has portrait_path")
	_assert_true(not (c.get("portrait_path", "") as String).is_empty(), "程天锋 portrait_path is non-empty")


func test_chen_tian_feng_portrait_resource_loads() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	var portrait_path := c.get("portrait_path", "") as String
	var texture := load(portrait_path) as Texture2D
	_assert_true(texture != null, "portrait_path loads as Texture2D")


func test_chen_tian_feng_cutout_resource_loads() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	var cutout_path := c.get("portrait_cutout_path", "") as String
	_assert_true(not cutout_path.is_empty(), "程天锋 has optional portrait_cutout_path")
	var texture := load(cutout_path) as Texture2D
	_assert_true(texture != null, "portrait_cutout_path loads as Texture2D")


func test_chen_tian_feng_sect_is_wanjianmen() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	_assert_eq(c.get("sect", ""), "万剑门", "程天锋 sect = 万剑门")


func test_character_select_scene_loads() -> void:
	var packed := load(CHARACTER_SELECT_SCENE) as PackedScene
	_assert_true(packed != null, "CharacterSelect.tscn loads as PackedScene")
	if packed:
		var inst := packed.instantiate()
		_objects_to_free.append(inst)
		_assert_true(inst != null, "CharacterSelect.tscn instantiates")


func test_character_select_scene_has_default_portrait() -> void:
	var inst := _load_scene_instance()
	if inst == null:
		_fail("CharacterSelect.tscn instance is null")
		return
	var portrait := inst.find_child("Portrait", true, false) as TextureRect
	_assert_true(portrait != null and portrait.texture != null, "CharacterSelect.tscn has default portrait")


func test_character_select_required_nodes_exist() -> void:
	var inst := _load_scene_instance()
	if inst == null:
		_fail("CharacterSelect.tscn instance is null")
		return
	for node_name in [
		"SectBar", "CharListBox", "CharName", "CharTitle", "PortraitStage", "Portrait", "Lore",
		"HPValue", "HPRegenValue", "LingLiValue", "LingLiRegenValue", "DaoHuiValue", "DmgValue",
		"TalentDesc", "SkillDesc", "StartBtn"
	]:
		_assert_true(inst.find_child(node_name, true, false) != null, "required node exists: %s" % node_name)

	var ling_li_label := inst.find_child("LingLiValue", true, false) as Label
	var ling_li_regen_label := inst.find_child("LingLiRegenValue", true, false) as Label
	_assert_eq(ling_li_label.text, "20", "灵力上限 displays separately")
	_assert_eq(ling_li_regen_label.text, "3", "灵力回复 value omits per-turn suffix")


func test_start_button_is_inside_stats_card() -> void:
	var inst := _load_scene_instance()
	if inst == null:
		_fail("CharacterSelect.tscn instance is null")
		return
	var stats_card := inst.find_child("StatsCard", true, false) as PanelContainer
	var start_btn := inst.find_child("StartBtn", true, false) as Button
	_assert_true(stats_card != null, "StatsCard node exists")
	_assert_true(start_btn != null, "StartBtn node exists")
	if stats_card == null or start_btn == null:
		return
	_assert_true(_is_descendant_of(start_btn, stats_card), "StartBtn is contained by StatsCard")


func test_hero_stage_aligns_with_stats_card_top() -> void:
	var inst := _load_scene_instance()
	if inst == null:
		_fail("CharacterSelect.tscn instance is null")
		return
	var hero_panel := inst.find_child("HeroPanel", true, false) as PanelContainer
	var stats_card := inst.find_child("StatsCard", true, false) as PanelContainer
	_assert_true(hero_panel != null, "HeroPanel node exists")
	_assert_true(stats_card != null, "StatsCard node exists")
	if hero_panel == null or stats_card == null:
		return
	_assert_eq(hero_panel.anchor_top, stats_card.anchor_top, "HeroPanel and StatsCard share top anchor")


func test_character_select_buttons_use_flat_styles() -> void:
	var style_script := load("res://scripts/ui/MenuUiStyle.gd")
	_assert_true(style_script.has_method("apply_character_select_button"), "MenuUiStyle has flat CharacterSelect button helper")
	if not style_script.has_method("apply_character_select_button"):
		return
	var secondary_btn := Button.new()
	var primary_btn := Button.new()
	_objects_to_free.append(secondary_btn)
	_objects_to_free.append(primary_btn)
	style_script.apply_character_select_button(secondary_btn, false, 15)
	style_script.apply_character_select_button(primary_btn, true, 18)
	for btn in [secondary_btn, primary_btn]:
		_assert_true(btn.get_theme_stylebox("normal") is StyleBoxFlat, "CharacterSelect button normal style is flat")
		_assert_true(btn.get_theme_stylebox("hover") is StyleBoxFlat, "CharacterSelect button hover style is flat")
		_assert_true(btn.get_theme_stylebox("pressed") is StyleBoxFlat, "CharacterSelect button pressed style is flat")
		_assert_true(btn.get_theme_stylebox("focus") is StyleBoxFlat, "CharacterSelect button focus style is flat")


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
	_assert_eq(portrait.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Portrait keeps aspect-centered image")
	_assert_true(frame == null or frame.clip_contents, "PortraitFrame clips overflow")
	_assert_true(frame == null or frame.custom_minimum_size.y > 0.0, "PortraitFrame has explicit visible height")
	_assert_true(frame == null or frame.size_flags_vertical == Control.SIZE_FILL, "PortraitFrame does not expand beyond visible height")


func test_chen_tian_feng_has_ui_required_fields() -> void:
	var db := _load_char_db()
	var c: Dictionary = db.get_character("chen_tian_feng")
	for key in [
		"name", "sect", "title", "lore", "portrait_path", "portrait_cutout_path",
		"hp_max", "hp_regen", "ling_li_max", "ling_li_regen",
		"dao_hui_max", "damage_mult", "talent_name", "talent_desc",
		"skill_name", "skill_desc"
	]:
		_assert_true(c.has(key), "程天锋 UI field exists: %s" % key)


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


func _is_descendant_of(node: Node, ancestor: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if current == ancestor:
			return true
		current = current.get_parent()
	return false


func _t(method: String) -> void:
	call(method)


func _assert_eq(a, b, label: String) -> void:
	if a == b:
		_pass_count += 1
		_lines.append("  OK %s" % label)
	else:
		_fail_count += 1
		_lines.append("  FAIL %s  -> expected %s, got %s" % [label, str(b), str(a)])


func _assert_true(cond: bool, label: String) -> void:
	if cond:
		_pass_count += 1
		_lines.append("  OK %s" % label)
	else:
		_fail_count += 1
		_lines.append("  FAIL %s  -> condition false" % label)


func _fail(label: String) -> void:
	_fail_count += 1
	_lines.append("  FAIL %s" % label)
