## UiCapture.gd
## Local visual diagnostics: open a known UI scene, wait for rendering, then
## save a screenshot plus a compact node tree summary.
extends SceneTree

const OUTPUT_ROOT := "res://tests/results/ui-captures"
const DEFAULT_CHARACTER_ID := "chen_tian_feng"
const DEFAULT_EVENT_ID := "Q-101"
const DEFAULT_SIZE := Vector2i(1280, 720)
const DEFAULT_WAIT_FRAMES := 60
const OFFSCREEN_POSITION := Vector2i(-32000, -32000)

const PRESET_ORDER: Array[String] = [
	"main_menu",
	"options",
	"character_select",
	"game_map",
	"battle",
	"reward",
	"shop",
	"bonfire",
	"event",
]

const SCENE_BY_PRESET := {
	"main_menu": "res://scenes/MainMenu.tscn",
	"options": "res://scenes/OptionsMenu.tscn",
	"character_select": "res://scenes/CharacterSelect.tscn",
	"game_map": "res://scenes/GameMap.tscn",
	"battle": "res://scenes/Battle.tscn",
	"reward": "res://scenes/RewardScreen.tscn",
	"shop": "res://scenes/Shop.tscn",
	"bonfire": "res://scenes/BonfireUpgrade.tscn",
	"event": "res://scenes/AdventureEvent.tscn",
}

var _capture_size := DEFAULT_SIZE
var _wait_frames := DEFAULT_WAIT_FRAMES
var _output_root := OUTPUT_ROOT
var _visible_window := false
var _active_scene: Node = null


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var parsed := _parse_args(OS.get_cmdline_user_args())
	if not parsed.get("ok", false):
		printerr(parsed.get("error", "Invalid arguments."))
		_print_usage()
		_quit_with_code(1)
		return
	if parsed.get("help", false):
		_print_usage()
		_quit_with_code(0)
		return
	if parsed.get("list", false):
		_print_presets()
		_quit_with_code(0)
		return

	_capture_size = parsed["size"]
	_wait_frames = int(parsed["wait_frames"])
	_output_root = str(parsed["output_root"])
	_visible_window = bool(parsed["visible"])

	_prepare_window()

	var presets: Array = parsed["presets"]
	var run_id := _make_run_id(str(parsed["command"]))
	var output_dir := "%s/%s" % [_output_root, run_id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))

	var captures: Array[Dictionary] = []
	var node_sections: Array[String] = []
	var exit_code := 0

	for preset in presets:
		var capture: Dictionary = await _capture_preset(str(preset), output_dir)
		captures.append(capture)
		node_sections.append(str(capture.get("nodes", "")))
		if not bool(capture.get("ok", false)):
			exit_code = 1

	var manifest_captures: Array[Dictionary] = []
	for c in captures:
		var clean := c.duplicate()
		clean.erase("nodes")
		manifest_captures.append(clean)

	var manifest := {
		"ok": exit_code == 0,
		"created_at": Time.get_datetime_string_from_system(),
		"command": parsed["command"],
		"window_mode": "visible" if _visible_window else "background",
		"size": {"width": _capture_size.x, "height": _capture_size.y},
		"wait_frames": _wait_frames,
		"output_dir": output_dir,
		"captures": manifest_captures,
	}

	_write_text("%s/manifest.json" % output_dir, JSON.stringify(manifest, "\t"))
	_write_text("%s/nodes.txt" % output_dir, "\n\n".join(node_sections) + "\n")

	print("UI capture output: %s" % ProjectSettings.globalize_path(output_dir))
	_clear_active_scene()
	_quit_with_code(exit_code)


func _quit_with_code(code: int) -> void:
	quit(code)


func _parse_args(args) -> Dictionary:
	var command := ""
	var size := DEFAULT_SIZE
	var wait_frames := DEFAULT_WAIT_FRAMES
	var output_root := OUTPUT_ROOT
	var show_list := false
	var show_help := false
	var visible_window := false

	var i := 0
	while i < args.size():
		var arg: String = str(args[i])
		if arg == "--list":
			show_list = true
		elif arg == "--help" or arg == "-h":
			show_help = true
		elif arg == "--visible":
			visible_window = true
		elif arg == "--background":
			visible_window = false
		elif arg == "--size":
			if i + 1 >= args.size():
				return _arg_error("--size requires WIDTHxHEIGHT.")
			size = _parse_size(args[i + 1])
			if size.x <= 0:
				return _arg_error("Invalid --size value: %s" % args[i + 1])
			i += 1
		elif arg.begins_with("--size="):
			var raw_size: String = arg.substr("--size=".length())
			size = _parse_size(raw_size)
			if size.x <= 0:
				return _arg_error("Invalid --size value: %s" % raw_size)
		elif arg == "--wait":
			if i + 1 >= args.size():
				return _arg_error("--wait requires a frame count.")
			wait_frames = int(args[i + 1])
			i += 1
		elif arg.begins_with("--wait="):
			wait_frames = int(arg.substr("--wait=".length()))
		elif arg == "--out":
			if i + 1 >= args.size():
				return _arg_error("--out requires a res:// output directory.")
			output_root = args[i + 1]
			i += 1
		elif arg.begins_with("--out="):
			output_root = arg.substr("--out=".length())
		elif arg.begins_with("--"):
			return _arg_error("Unknown option: %s" % arg)
		elif command.is_empty():
			command = arg
		else:
			return _arg_error("Unexpected argument: %s" % arg)
		i += 1

	if show_list or show_help:
		return {
			"ok": true,
			"list": show_list,
			"help": show_help,
			"command": command,
			"presets": [],
			"size": size,
			"wait_frames": wait_frames,
			"output_root": output_root,
			"visible": visible_window,
		}

	if command.is_empty():
		return _arg_error("Missing preset name. Use --list to see presets.")

	var presets: Array[String] = []
	if command == "all":
		presets = PRESET_ORDER.duplicate()
	elif SCENE_BY_PRESET.has(command):
		presets = [command]
	else:
		return _arg_error("Unknown preset: %s" % command)

	return {
		"ok": true,
		"list": false,
		"help": false,
		"command": command,
		"presets": presets,
		"size": size,
		"wait_frames": maxi(1, wait_frames),
		"output_root": output_root,
		"visible": visible_window,
	}


func _arg_error(message: String) -> Dictionary:
	return {"ok": false, "error": message}


func _parse_size(raw: String) -> Vector2i:
	var parts := raw.to_lower().split("x", false, 2)
	if parts.size() != 2:
		return Vector2i.ZERO
	var w := int(parts[0])
	var h := int(parts[1])
	if w <= 0 or h <= 0:
		return Vector2i.ZERO
	return Vector2i(w, h)


func _print_usage() -> void:
	print("Usage:")
	print("  capture_ui.bat <preset> [--size WIDTHxHEIGHT] [--wait FRAMES] [--visible|--background]")
	print("  capture_ui.bat all [--size WIDTHxHEIGHT] [--wait FRAMES] [--visible|--background]")
	print("  capture_ui.bat --list")
	print("")
	print("Examples:")
	print("  capture_ui.bat main_menu")
	print("  capture_ui.bat battle --size 1920x1080 --wait 90")
	print("  capture_ui.bat main_menu --visible")
	print("")
	print("Window mode:")
	print("  default/--background: offscreen real-render capture")
	print("  --visible: center the Godot window on the desktop")


func _print_presets() -> void:
	print("Available UI capture presets:")
	for preset in PRESET_ORDER:
		print("  %s -> %s" % [preset, SCENE_BY_PRESET[preset]])
	print("  all -> every preset above")


func _prepare_window() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(_capture_size)
	if not _visible_window:
		DisplayServer.window_set_position(OFFSCREEN_POSITION)
		return
	var screen_size := DisplayServer.screen_get_size()
	if screen_size.x > 0 and screen_size.y > 0:
		DisplayServer.window_set_position((screen_size - _capture_size) / 2)


func _capture_preset(preset: String, output_dir: String) -> Dictionary:
	_clear_active_scene()
	_prepare_window()
	_prepare_state_for_preset(preset)

	var scene_path := str(SCENE_BY_PRESET[preset])
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return {
			"ok": false,
			"preset": preset,
			"scene": scene_path,
			"error": "Failed to load scene.",
			"nodes": "[%s]\nFailed to load %s" % [preset, scene_path],
		}

	_active_scene = packed.instantiate()
	root.add_child(_active_scene)
	await process_frame
	_prepare_window()
	_apply_post_open_state(preset, _active_scene)
	for _frame in range(_wait_frames):
		await process_frame

	var png_path := "%s/%s_%dx%d.png" % [output_dir, preset, _capture_size.x, _capture_size.y]
	var node_lines: Array[String] = []
	node_lines.append("[%s]" % preset)
	node_lines.append("scene=%s" % scene_path)
	node_lines.append("png=%s" % png_path)
	_append_node_tree(_active_scene, node_lines)

	var image: Image = null
	var texture := root.get_texture()
	if texture != null:
		image = texture.get_image()

	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		var image_error := _empty_image_error()
		node_lines.append("error=%s" % image_error)
		return {
			"ok": false,
			"preset": preset,
			"scene": scene_path,
			"png": png_path,
			"png_abs": ProjectSettings.globalize_path(png_path),
			"error": image_error,
			"nodes": "\n".join(node_lines),
		}

	var save_error := image.save_png(png_path)
	return {
		"ok": save_error == OK,
		"preset": preset,
		"scene": scene_path,
		"png": png_path,
		"png_abs": ProjectSettings.globalize_path(png_path),
		"error": "" if save_error == OK else "Image.save_png failed with code %d." % save_error,
		"nodes": "\n".join(node_lines),
	}


func _empty_image_error() -> String:
	if _visible_window:
		return "Viewport image is empty; no rendered frame was available for this capture."
	return "Viewport image is empty in background mode; retry explicitly with --visible if a manual visible capture is acceptable."


func _prepare_state_for_preset(preset: String) -> void:
	var game_state = _autoload("GameState")
	if game_state == null:
		return
	seed(20260513)
	if preset in ["main_menu", "options", "character_select"]:
		game_state.call("reset_run")
		_prepare_capture_settings()
		return

	game_state.call("start_run", DEFAULT_CHARACTER_ID)
	game_state.set("current_hp", 48)
	game_state.set("spirit_stones", 260)
	game_state.set("map_intro_played", true)
	_add_demo_consumables()
	_add_demo_artifacts()

	match preset:
		"game_map":
			game_state.call("start_map")
			game_state.set("map_intro_played", true)
		"battle":
			game_state.set("pending_battle_node_type", "normal")
			game_state.set("pending_battle_node_floor", 1)
		"reward":
			game_state.set("pending_battle_node_type", "elite")
			game_state.set("pending_battle_node_floor", 3)
			game_state.set("pending_reward_stones_bonus", 20)
			game_state.set("pending_reward_min_rarity", "玄品")
		"shop":
			game_state.set("map_current_floor", 4)
			game_state.set("pending_battle_node_floor", 4)
			game_state.set("pending_shop_discount_pct", 0.15)
			game_state.set("pending_shop_extra_items", 1)
		"bonfire":
			var deck: Array = game_state.get("deck")
			deck.append_array(["5", "12", "18", "24+", "36"])
			game_state.set("deck", deck)
		"event":
			game_state.set("pending_event_id", DEFAULT_EVENT_ID)

	_prepare_capture_settings()


func _prepare_capture_settings() -> void:
	var settings = _autoload("GlobalSettings")
	if settings == null:
		return
	settings.set("fullscreen", false)
	settings.set("resolution_index", 0)
	settings.set("language", "zh_CN")
	settings.set("master_volume", 0.0)
	settings.set("music_volume", 0.0)
	settings.set("sfx_volume", 0.0)
	settings.call("apply_audio")
	settings.call("apply_language")


func _add_demo_consumables() -> void:
	var game_state = _autoload("GameState")
	var shop_db = _autoload("ShopDatabase")
	if game_state == null or shop_db == null:
		return
	for item_id in ["D-01", "D-03", "T-02", "F-01", "T-07"]:
		var item: Dictionary = shop_db.call("get_item_by_id", item_id)
		if not item.is_empty():
			game_state.call("add_consumable", item)


func _add_demo_artifacts() -> void:
	var game_state = _autoload("GameState")
	var shop_db = _autoload("ShopDatabase")
	if game_state == null or shop_db == null:
		return
	for art_id in ["R-01", "R-03", "R-07", "R-14", "R-S01"]:
		var artifact: Dictionary = shop_db.call("get_artifact_by_id", art_id)
		if not artifact.is_empty():
			game_state.call("add_artifact", artifact)
	game_state.set("last_acquired_artifact_id", "")


func _apply_post_open_state(preset: String, scene: Node) -> void:
	if preset == "reward" and scene.has_method("_on_card_reward_btn_pressed"):
		scene.call("_on_card_reward_btn_pressed")


func _append_node_tree(node: Node, lines: Array[String], depth: int = 0, counter: Array = [0]) -> void:
	if depth == 0:
		counter[0] = 0
	if counter[0] >= 900:
		if counter[0] == 900:
			lines.append("  ... node dump truncated ...")
			counter[0] += 1
		return
	counter[0] += 1

	var parts: Array[String] = []
	parts.append("%s%s" % ["  ".repeat(depth), node.name])
	parts.append("class=%s" % node.get_class())
	if node is Control:
		var control := node as Control
		parts.append("visible=%s" % str(control.visible))
		parts.append("pos=%s" % _format_vec2(control.global_position))
		parts.append("size=%s" % _format_vec2(control.size))
	elif node is CanvasItem:
		var item := node as CanvasItem
		parts.append("visible=%s" % str(item.visible))

	var text := _node_text(node)
	if not text.is_empty():
		parts.append("text=\"%s\"" % _shorten(text))

	lines.append(" | ".join(parts))
	for child in node.get_children():
		_append_node_tree(child, lines, depth + 1, counter)


func _node_text(node: Node) -> String:
	if node is Button:
		return (node as Button).text
	if node is Label:
		return (node as Label).text
	if node is LineEdit:
		return (node as LineEdit).text
	return ""


func _shorten(text: String, max_len: int = 80) -> String:
	var compact := text.replace("\r", " ").replace("\n", " ").strip_edges()
	if compact.length() <= max_len:
		return compact
	return compact.substr(0, max_len - 3) + "..."


func _format_vec2(value: Vector2) -> String:
	return "(%.1f,%.1f)" % [value.x, value.y]


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("Failed to write %s" % path)
		return
	file.store_string(content)
	file.close()


func _autoload(name: String):
	var node := root.get_node_or_null("/root/%s" % name)
	if node == null:
		printerr("Missing autoload: %s" % name)
	return node


func _clear_active_scene() -> void:
	if _active_scene != null and is_instance_valid(_active_scene):
		_active_scene.queue_free()
	_active_scene = null


func _make_run_id(command: String) -> String:
	var dt := Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d_%s_%dx%d" % [
		int(dt["year"]),
		int(dt["month"]),
		int(dt["day"]),
		int(dt["hour"]),
		int(dt["minute"]),
		int(dt["second"]),
		command,
		_capture_size.x,
		_capture_size.y,
	]
