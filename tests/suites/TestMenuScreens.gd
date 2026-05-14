## TestMenuScreens.gd
## Verifies the redesigned entry menu screens keep their required structure and art assets.
extends RefCounted

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const OPTIONS_MENU_SCENE := "res://scenes/OptionsMenu.tscn"
const CHARACTER_SELECT_SCENE := "res://scenes/CharacterSelect.tscn"
const MENU_STYLE_SCRIPT := "res://scripts/ui/MenuUiStyle.gd"
const FONT_SERIF := "res://assets/fonts/NotoSerifSC-Regular.otf"
const FONT_SANS := "res://assets/fonts/NotoSansSC-Regular.otf"
const FONT_LICENSE := "res://assets/fonts/OFL.txt"
const PORTRAIT_CUTOUT := "res://assets/portraits/chen_tianfeng_cutout.png"

const MENU_ASSETS := [
	"res://assets/ui/menu/panel_jade_9.png",
	"res://assets/ui/menu/panel_scroll_9.png",
	"res://assets/ui/menu/panel_stat_9.png",
	"res://assets/ui/menu/button_primary_normal_9.png",
	"res://assets/ui/menu/button_secondary_normal_9.png",
	"res://assets/ui/menu/cloud_divider.png",
	"res://assets/ui/menu/icon_hp.png",
	"res://assets/ui/menu/icon_lingli.png",
	"res://assets/ui/menu/icon_daohui.png",
	"res://assets/ui/menu/icon_damage.png",
]

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _objects_to_free: Array[Object] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestMenuScreens ]")

	_t("test_shared_menu_assets_exist")
	_t("test_main_menu_uses_central_altar_layout")
	_t("test_main_menu_buttons_use_flat_hover_gold")
	_t("test_character_select_uses_stage_and_stat_tiles")
	_t("test_options_menu_keeps_settings_controls")
	_t("test_project_defaults_to_standard_window")

	_lines.append("  -> %d passed  %d failed" % [_pass_count, _fail_count])
	for o in _objects_to_free:
		if is_instance_valid(o):
			o.free()
	_objects_to_free.clear()
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_shared_menu_assets_exist() -> void:
	_assert_loads(MENU_STYLE_SCRIPT, "MenuUiStyle helper loads")
	_assert_loads(FONT_SERIF, "Noto Serif SC font loads")
	_assert_loads(FONT_SANS, "Noto Sans SC font loads")
	_assert_true(FileAccess.file_exists(FONT_LICENSE), "font license file exists")
	_assert_loads(PORTRAIT_CUTOUT, "Chen Tianfeng cutout portrait loads")
	for path in MENU_ASSETS:
		_assert_loads(path, "menu art asset loads: %s" % path.get_file())


func test_main_menu_uses_central_altar_layout() -> void:
	var inst := _load_scene_instance(MAIN_MENU_SCENE)
	if inst == null:
		_fail("MainMenu scene instantiates")
		return
	_assert_texture_rect(inst, "BG", "MainMenu has image background")
	var panel := inst.find_child("MenuPanel", true, false) as PanelContainer
	_assert_true(panel != null, "MainMenu keeps MenuPanel")
	if panel:
		_assert_true(panel.anchor_left > 0.20 and panel.anchor_right < 0.80, "MenuPanel is centered rather than left-card")
	_assert_true(inst.find_child("SealRing", true, false) is TextureRect, "MainMenu has altar seal visual")
	_assert_true(inst.find_child("TitleRule", true, false) is TextureRect, "MainMenu has cloud divider art")
	_assert_true(inst.find_child("Title", true, false) is Label, "MainMenu keeps Title label")
	_assert_true(inst.find_child("Buttons", true, false) is VBoxContainer, "MainMenu keeps Buttons container")
	_assert_true(inst.find_child("BtnStart", true, false) is Button, "MainMenu keeps BtnStart as Button")
	_assert_true(inst.find_child("BtnOptions", true, false) is Button, "MainMenu keeps BtnOptions as Button")
	_assert_true(inst.find_child("BtnExit", true, false) is Button, "MainMenu keeps BtnExit as Button")
	_assert_true(inst.find_child("Kicker", true, false) == null, "MainMenu removes reincarnation kicker node")
	_assert_true(inst.find_child("Hint", true, false) == null, "MainMenu removes keyboard hint node")
	_assert_false(_has_text(inst, "第一轮回"), "MainMenu omits reincarnation text")
	_assert_false(_has_text(inst, "方向键选择"), "MainMenu omits direction-key hint text")
	_assert_false(_has_text(inst, "Enter 确认"), "MainMenu omits enter-confirm hint text")
	_assert_true(inst.find_child("LowerVignette", true, false) == null, "MainMenu removes hard lower divider")


func test_main_menu_buttons_use_flat_hover_gold() -> void:
	var style_script := load(MENU_STYLE_SCRIPT)
	var btn := Button.new()
	_objects_to_free.append(btn)
	style_script.apply_main_menu_button(btn, 18)
	var normal := btn.get_theme_stylebox("normal") as StyleBoxFlat
	var hover := btn.get_theme_stylebox("hover") as StyleBoxFlat
	var focus := btn.get_theme_stylebox("focus") as StyleBoxFlat
	_assert_true(normal != null, "main menu button normal style is flat")
	_assert_true(hover != null, "main menu button hover style is flat")
	_assert_true(focus != null, "main menu button focus style is a non-covering ring")
	if normal and hover and focus:
		_assert_true(normal.bg_color.g < 0.25, "main menu button normal is not gold")
		_assert_true(hover.bg_color.r > 0.90 and hover.bg_color.g > 0.70, "main menu button hover is gold")
		_assert_true(focus.bg_color.a <= 0.01, "main menu button focus fill is transparent")
		_assert_false(focus.draw_center, "main menu button focus does not cover hover fill")
		_assert_true(focus.border_color.r > 0.90 and focus.border_color.g > 0.70, "main menu button focus ring is gold")
	var normal_text := _theme_color(btn, "font_color")
	var focus_text := _theme_color(btn, "font_focus_color")
	_assert_true(normal_text.r > 0.80 and normal_text.g > 0.80 and normal_text.b > 0.70, "main menu button normal text is readable")
	_assert_true(focus_text.r > 0.80 and focus_text.g > 0.80 and focus_text.b > 0.70, "main menu button focus text remains readable")
	_assert_true(_theme_color(btn, "font_hover_color").g < 0.30, "main menu button hover text contrasts on gold")


func test_character_select_uses_stage_and_stat_tiles() -> void:
	var inst := _load_scene_instance(CHARACTER_SELECT_SCENE)
	if inst == null:
		_fail("CharacterSelect scene instantiates")
		return
	_assert_texture_rect(inst, "BG", "CharacterSelect has image background")
	_assert_true(inst.find_child("SectBar", true, false) is HBoxContainer, "CharacterSelect keeps SectBar")
	_assert_true(inst.find_child("CharListBox", true, false) is VBoxContainer, "CharacterSelect keeps CharListBox")
	_assert_true(inst.find_child("HeroPanel", true, false) is PanelContainer, "CharacterSelect keeps HeroPanel")
	_assert_true(inst.find_child("PortraitStage", true, false) is Control, "CharacterSelect keeps PortraitStage")
	var portrait := inst.find_child("Portrait", true, false) as TextureRect
	_assert_true(portrait != null and portrait.texture != null, "CharacterSelect has default portrait texture")
	_assert_true(inst.find_child("StatsCard", true, false) is PanelContainer, "CharacterSelect keeps StatsCard")
	for tile_name in ["HPTile", "HPRegenTile", "LingLiTile", "LingLiRegenTile", "DaoHuiTile", "DmgTile"]:
		_assert_true(inst.find_child(tile_name, true, false) is PanelContainer, "stat tile exists: %s" % tile_name)
	_assert_true(inst.find_child("TalentPanel", true, false) is PanelContainer, "TalentPanel is a jade slip panel")
	_assert_true(inst.find_child("SkillPanel", true, false) is PanelContainer, "SkillPanel is a jade slip panel")
	_assert_true(inst.find_child("StartBtn", true, false) is Button, "CharacterSelect keeps StartBtn")


func test_options_menu_keeps_settings_controls() -> void:
	var inst := _load_scene_instance(OPTIONS_MENU_SCENE)
	if inst == null:
		_fail("OptionsMenu scene instantiates")
		return
	_assert_texture_rect(inst, "BG", "OptionsMenu has image background")
	var settings_panel := inst.find_child("SettingsPanel", true, false) as PanelContainer
	_assert_true(settings_panel != null, "OptionsMenu keeps SettingsPanel")
	if settings_panel:
		_assert_true(settings_panel.anchor_right - settings_panel.anchor_left >= 0.58, "OptionsMenu uses wide settings panel")
		_assert_true(absf(settings_panel.anchor_left + settings_panel.anchor_right - 1.0) <= 0.02, "OptionsMenu panel remains centered")
	for node_name in [
		"DisplayModeOption", "ResolutionOption", "MasterSlider", "MusicSlider",
		"SFXSlider", "LanguageOption", "BtnApply", "BtnBack"
	]:
		_assert_true(inst.find_child(node_name, true, false) != null, "OptionsMenu keeps %s" % node_name)
	var section_locale := inst.find_child("SectionLocale", true, false) as Label
	var language_row_label := inst.find_child("LanguageRowLabel", true, false) as Label
	_assert_true(section_locale != null and section_locale.text == "语言 / Language", "OptionsMenu keeps bilingual language section title")
	_assert_true(language_row_label != null and language_row_label.text == "界面语言", "OptionsMenu removes duplicate language row label")
	for label_name in [
		"DisplayModeRowLabel", "ResolutionRowLabel", "MasterRowLabel",
		"MusicRowLabel", "SFXRowLabel", "LanguageRowLabel"
	]:
		var row_label := inst.find_child(label_name, true, false) as Label
		_assert_true(row_label != null and row_label.custom_minimum_size.x >= 130.0, "OptionsMenu aligns label column: %s" % label_name)


func test_project_defaults_to_standard_window() -> void:
	_assert_false(ProjectSettings.get_setting("display/window/size/borderless", false), "project defaults to standard window")


func _load_scene_instance(path: String) -> Node:
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var inst := packed.instantiate()
	_objects_to_free.append(inst)
	return inst


func _assert_loads(path: String, label: String) -> void:
	_assert_true(FileAccess.file_exists(path), "%s file exists" % label)
	_assert_true(load(path) != null, label)


func _assert_texture_rect(root: Node, node_name: String, label: String) -> void:
	var tex_rect := root.find_child(node_name, true, false) as TextureRect
	_assert_true(tex_rect != null and tex_rect.texture != null, label)


func _has_text(root: Node, needle: String) -> bool:
	if root is Label and needle in (root as Label).text:
		return true
	if root is Button and needle in (root as Button).text:
		return true
	for child in root.get_children():
		if child is Node and _has_text(child, needle):
			return true
	return false


func _theme_color(control: Control, name: String) -> Color:
	return control.get_theme_color(name, control.get_class())


func _t(method: String) -> void:
	call(method)


func _assert_true(cond: bool, label: String) -> void:
	if cond:
		_pass_count += 1
		_lines.append("  OK %s" % label)
	else:
		_fail(label)


func _assert_false(cond: bool, label: String) -> void:
	_assert_true(not cond, label)


func _fail(label: String) -> void:
	_fail_count += 1
	_lines.append("  FAIL %s" % label)
