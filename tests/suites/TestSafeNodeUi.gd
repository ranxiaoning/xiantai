## TestSafeNodeUi.gd
## UI structure checks for refined map safe-node, bonfire, and event screens.
extends RefCounted

const MENU_STYLE_SCRIPT := "res://scripts/ui/MenuUiStyle.gd"
const SAFE_NODE_STYLE_SCRIPT := "res://scripts/ui/SafeNodeUiStyle.gd"
const GAME_MAP_SCENE := preload("res://scenes/GameMap.tscn")
const BONFIRE_SCENE := preload("res://scenes/BonfireUpgrade.tscn")
const EVENT_SCENE := preload("res://scenes/AdventureEvent.tscn")

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _objects_to_free: Array[Object] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestSafeNodeUi ]")

	_t("test_shared_style_exposes_safe_node_helpers")
	_t("test_game_map_safe_node_popup_structure")
	_t("test_game_map_deck_entry_is_icon_button")
	_t("test_origin_overlay_uses_refined_choice_cards")
	_t("test_bonfire_upgrade_has_refined_panel_structure")
	_t("test_adventure_event_has_refined_panel_structure")
	_t("test_safe_node_screens_do_not_parse_depend_on_optional_style_helpers")
	_t("test_game_map_popup_show_helper_is_not_recursive")
	_t("test_safe_node_style_exposes_choice_state_helper")
	_t("test_origin_choice_cards_have_hover_handlers")
	_t("test_origin_choice_selection_survives_mouse_exit")
	_t("test_safe_node_card_pickers_use_light_hover_feedback")
	_t("test_event_option_buttons_signal_clickable_and_disabled_states")

	_lines.append("  -> %d passed  %d failed" % [_pass_count, _fail_count])
	for o in _objects_to_free:
		if is_instance_valid(o):
			o.free()
	_objects_to_free.clear()
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_shared_style_exposes_safe_node_helpers() -> void:
	var script := load(MENU_STYLE_SCRIPT) as Script
	_assert_true(script != null, "MenuUiStyle script loads")
	for method_name in [
		"apply_modal_panel",
		"apply_result_panel",
		"apply_choice_card",
		"apply_scrim",
		"apply_title_pill",
	]:
		_assert_true(_script_has_method(script, method_name), "MenuUiStyle has %s" % method_name)


func test_game_map_safe_node_popup_structure() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.map_intro_played = true
	var scene := _add_scene(GAME_MAP_SCENE.instantiate())
	_assert_node(scene, "PopupScrim", ColorRect, "GameMap has popup scrim")
	_assert_node(scene, "NodePopup", PanelContainer, "GameMap keeps NodePopup panel")
	_assert_node(scene, "PopupHeader", HBoxContainer, "NodePopup has title header")
	_assert_node(scene, "PopupBodyScroll", ScrollContainer, "NodePopup has scrollable body")
	_assert_node(scene, "PopupActions", HBoxContainer, "NodePopup has stable action row")


func test_game_map_deck_entry_is_icon_button() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.map_intro_played = true
	var scene := _add_scene(GAME_MAP_SCENE.instantiate())
	var deck_btn := scene.find_child("DeckBtn", true, false) as Button
	_assert_true(deck_btn != null, "GameMap keeps deck entry button")
	if deck_btn == null:
		return
	_assert_true(deck_btn.text == "", "deck entry uses icon instead of text label")
	_assert_true(deck_btn.icon != null, "deck entry has deck icon texture")
	_assert_true(deck_btn.tooltip_text == "查看卡组", "deck icon keeps viewer tooltip")
	_assert_true(deck_btn.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "deck icon signals clickability")
	_assert_true(deck_btn.offset_right <= -60.0, "deck icon leaves room for in-game menu button")
	var deck_overlay := scene.find_child("DeckOverlay", true, false) as Control
	_assert_true(deck_overlay != null and not deck_overlay.visible, "deck overlay starts hidden")
	_assert_true(deck_btn.is_connected("pressed", Callable(scene, "_on_deck_btn_pressed")), "deck icon remains connected to existing handler")


func test_origin_overlay_uses_refined_choice_cards() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.map_intro_played = true
	var scene := _add_scene(GAME_MAP_SCENE.instantiate())
	scene.call("_show_origin_overlay")
	_assert_node(scene, "OriginPanel", PanelContainer, "Origin overlay has main panel")
	_assert_node(scene, "OriginChoiceRow", HBoxContainer, "Origin overlay has choice row")
	_assert_node(scene, "OriginConfirmBtn", Button, "Origin overlay has named confirm button")
	_assert_true(_count_nodes_with_prefix(scene, "OriginChoiceCard") == 3, "Origin overlay shows three choice cards")


func test_bonfire_upgrade_has_refined_panel_structure() -> void:
	GameState.start_run("chen_tian_feng")
	var scene := _add_scene(BONFIRE_SCENE.instantiate())
	_assert_node(scene, "BonfirePanel", PanelContainer, "Bonfire screen has main panel")
	_assert_node(scene, "BonfireCardScroll", ScrollContainer, "Bonfire screen has card scroll")
	_assert_node(scene, "BonfireSkipBtn", Button, "Bonfire screen has named skip button")
	_assert_node(scene, "UpgradePreviewPanel", PanelContainer, "Bonfire upgrade overlay has preview panel")


func test_adventure_event_has_refined_panel_structure() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.pending_event_id = "Q-101"
	var scene := _add_scene(EVENT_SCENE.instantiate())
	_assert_node(scene, "EventPanel", PanelContainer, "Adventure event has main panel")
	_assert_node(scene, "EventTitleRow", HBoxContainer, "Adventure event has title row")
	_assert_node(scene, "EventOptionsBox", VBoxContainer, "Adventure event has option box")
	_assert_node(scene, "EventResultPanel", PanelContainer, "Adventure event has result panel")
	_assert_node(scene, "EventCardPickerPanel", PanelContainer, "Adventure card picker has panel")


func test_safe_node_screens_do_not_parse_depend_on_optional_style_helpers() -> void:
	var blocked_calls: Array[String] = [
		"MenuUiStyle.apply_modal_panel",
		"MenuUiStyle.apply_result_panel",
		"MenuUiStyle.apply_choice_card",
		"MenuUiStyle.apply_scrim",
		"MenuUiStyle.apply_title_pill",
	]
	for path in [
		"res://scripts/GameMap.gd",
		"res://scripts/BonfireUpgrade.gd",
		"res://scripts/AdventureEvent.gd",
	]:
		var src := FileAccess.get_file_as_string(path)
		for blocked in blocked_calls:
			_assert_true(not src.contains(blocked), "%s avoids direct %s parse dependency" % [path.get_file(), blocked])


func test_game_map_popup_show_helper_is_not_recursive() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/GameMap.gd").replace("\r\n", "\n").replace("\r", "\n")
	var start := src.find("func _show_node_popup()")
	var end := src.find("\n\n", start)
	if end == -1:
		end = src.length()
	var body := src.substr(start, end - start)
	_assert_true(body.contains("node_popup.show()"), "GameMap popup helper shows NodePopup directly")
	_assert_true(not body.replace("func _show_node_popup()", "").contains("_show_node_popup()"), "GameMap popup helper does not recurse into itself")


func test_safe_node_style_exposes_choice_state_helper() -> void:
	var script := load(SAFE_NODE_STYLE_SCRIPT) as Script
	_assert_true(script != null, "SafeNodeUiStyle script loads")
	for method_name in [
		"apply_choice_state",
		"animate_choice_hover",
	]:
		_assert_true(_script_has_method(script, method_name), "SafeNodeUiStyle has %s" % method_name)

	var disabled_panel := PanelContainer.new()
	var hover_panel := PanelContainer.new()
	_objects_to_free.append(disabled_panel)
	_objects_to_free.append(hover_panel)
	script.call("apply_choice_state", disabled_panel, false, true, true, false)
	script.call("apply_choice_state", hover_panel, false, true, false, false)
	_assert_true(disabled_panel.scale == Vector2.ONE, "disabled choice does not scale on hover")
	_assert_true(hover_panel.scale.x > 1.0 and hover_panel.modulate.a > disabled_panel.modulate.a, "hover choice gets active visual feedback")


func test_origin_choice_cards_have_hover_handlers() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.map_intro_played = true
	var scene := _add_scene(GAME_MAP_SCENE.instantiate())
	scene.call("_show_origin_overlay")
	var src := FileAccess.get_file_as_string("res://scripts/GameMap.gd")
	_assert_true(src.contains("_on_blessing_hover_entered"), "GameMap has origin blessing hover enter handler")
	_assert_true(src.contains("_on_blessing_hover_exited"), "GameMap has origin blessing hover exit handler")
	for i in range(3):
		var card := scene.find_child("OriginChoiceCard%d" % i, true, false) as PanelContainer
		_assert_true(card != null, "OriginChoiceCard%d exists for hover test" % i)
	_assert_true(src.contains("panel.mouse_entered.connect(_on_blessing_hover_entered.bind(idx))"), "origin choice cards connect mouse_entered")
	_assert_true(src.contains("panel.mouse_exited.connect(_on_blessing_hover_exited.bind(idx))"), "origin choice cards connect mouse_exited")


func test_origin_choice_selection_survives_mouse_exit() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.map_intro_played = true
	var scene := _add_scene(GAME_MAP_SCENE.instantiate())
	scene.call("_show_origin_overlay")
	scene.call("_select_blessing", 1)
	scene.call("_on_blessing_hover_exited", 1)
	var card := scene.find_child("OriginChoiceCard1", true, false) as PanelContainer
	_assert_true(card != null and bool(card.get_meta("safe_node_selected", false)), "origin selected card remains selected after mouse exit")


func test_safe_node_card_pickers_use_light_hover_feedback() -> void:
	var checks := {
		"GameMap.gd": FileAccess.get_file_as_string("res://scripts/GameMap.gd"),
		"BonfireUpgrade.gd": FileAccess.get_file_as_string("res://scripts/BonfireUpgrade.gd"),
		"AdventureEvent.gd": FileAccess.get_file_as_string("res://scripts/AdventureEvent.gd"),
	}
	for file_name in checks.keys():
		var src: String = checks[file_name]
		_assert_true(src.contains("SafeNodeUiStyle.animate_choice_hover"), "%s uses light hover feedback for picker cards" % file_name)
		_assert_true(src.contains("mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND"), "%s marks picker cards as clickable" % file_name)


func test_event_option_buttons_signal_clickable_and_disabled_states() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/AdventureEvent.gd")
	_assert_true(src.contains("btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND"), "event option buttons use pointer cursor when clickable")
	_assert_true(src.contains("btn.disabled = true") and src.contains("btn.mouse_default_cursor_shape = Control.CURSOR_ARROW"), "disabled event options do not signal clickability")


func _add_scene(scene: Node) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)
	if scene.get_child_count() == 0 and scene.has_method("_ready"):
		scene.call("_ready")
	_objects_to_free.append(scene)
	return scene


func _assert_node(root: Node, node_name: String, expected_type, label: String) -> void:
	var node := root.find_child(node_name, true, false)
	_assert_true(node != null and is_instance_of(node, expected_type), label)


func _script_has_method(script: Script, method_name: String) -> bool:
	for method_info in script.get_script_method_list():
		if str(method_info.get("name", "")) == method_name:
			return true
	return false


func _count_nodes_with_prefix(root: Node, prefix: String) -> int:
	var count := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.name.begins_with(prefix):
			count += 1
		for child in node.get_children():
			stack.append(child)
	return count


func _t(method: String) -> void:
	call(method)


func _assert_true(cond: bool, label: String) -> void:
	if cond:
		_pass_count += 1
		_lines.append("  OK %s" % label)
	else:
		_fail_count += 1
		_lines.append("  FAIL %s" % label)
