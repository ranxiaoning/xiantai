## CharacterSelect.gd
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"
const IN_GAME_MENU_SCRIPT: Script = preload("res://scripts/InGameMenu.gd")
const MenuUiStyle = preload("res://scripts/ui/MenuUiStyle.gd")

var _selected_sect: String = "万剑门"
var _selected_char_id: String = "chen_tian_feng"

var _sect_group := ButtonGroup.new()
var _char_group := ButtonGroup.new()
var _display_tween: Tween = null

@onready var bg_rect: TextureRect = $BG
@onready var page_title: Label = %PageTitle
@onready var page_subtitle: Label = %PageSubTitle
@onready var sect_bar: HBoxContainer = %SectBar
@onready var char_list_box: VBoxContainer = %CharListBox
@onready var char_list_title: Label = $MainContent/SidebarPanel/SidebarPad/CharListPanel/CharListTitle
@onready var char_list_hint: Label = $MainContent/SidebarPanel/SidebarPad/CharListPanel/CharListHint
@onready var char_name_label: Label = %CharName
@onready var char_title_label: Label = %CharTitle
@onready var portrait: TextureRect = %Portrait
@onready var lore_label: Label = %Lore
@onready var hp_label: Label = %HPValue
@onready var hp_regen_label: Label = %HPRegenValue
@onready var ling_li_label: Label = %LingLiValue
@onready var ling_li_regen_label: Label = %LingLiRegenValue
@onready var dao_hui_label: Label = %DaoHuiValue
@onready var damage_mult_label: Label = %DmgValue
@onready var talent_label: Label = %TalentDesc
@onready var skill_label: Label = %SkillDesc
@onready var sidebar_panel: PanelContainer = $MainContent/SidebarPanel
@onready var hero_panel: PanelContainer = $MainContent/HeroPanel
@onready var portrait_frame: PanelContainer = $MainContent/HeroPanel/HeroPad/CharDetailPanel/PortraitFrame
@onready var portrait_stage: Control = $MainContent/HeroPanel/HeroPad/CharDetailPanel/PortraitFrame/PortraitMargin/PortraitStage
@onready var char_title_pill: PanelContainer = $MainContent/HeroPanel/HeroPad/CharDetailPanel/PortraitFrame/PortraitMargin/PortraitStage/CharTitlePill
@onready var stats_card: PanelContainer = $MainContent/StatsCard
@onready var stats_title: Label = $MainContent/StatsCard/StatsPad/StatsPanel/StatsTitle
@onready var talent_title: Label = $MainContent/StatsCard/StatsPad/StatsPanel/TalentTitle
@onready var skill_title: Label = $MainContent/StatsCard/StatsPad/StatsPanel/SkillTitle
@onready var talent_panel: PanelContainer = $MainContent/StatsCard/StatsPad/StatsPanel/TalentPanel
@onready var skill_panel: PanelContainer = $MainContent/StatsCard/StatsPad/StatsPanel/SkillPanel
@onready var start_btn: Button = %StartBtn
@onready var main_content: Control = %MainContent


func _ready() -> void:
	theme = load("res://theme/main_theme.tres")
	MusicManager.play("char_select")
	_configure_portrait_layout()
	_apply_static_styles()
	_build_sect_bar()
	start_btn.button_down.connect(_on_start_button_down)
	start_btn.button_up.connect(_on_start_button_up)
	call_deferred("_animate_scene_in")
	_add_in_game_menu()


func _add_in_game_menu() -> void:
	var in_game_menu: Node = IN_GAME_MENU_SCRIPT.new()
	add_child(in_game_menu)
	in_game_menu.connect("abandon_confirmed", _on_menu_abandon_confirmed)
	in_game_menu.connect("return_to_menu_confirmed", _on_menu_return_confirmed)


func _configure_portrait_layout() -> void:
	var viewport_h := get_viewport_rect().size.y
	portrait_frame.clip_contents = true
	portrait_frame.custom_minimum_size = Vector2(0.0, clampf(viewport_h * 0.54, 380.0, 560.0))
	portrait_frame.size_flags_vertical = Control.SIZE_FILL
	portrait_stage.clip_contents = true
	portrait_stage.custom_minimum_size = Vector2.ZERO
	portrait_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.offset_left = 0.0
	portrait.offset_top = 0.0
	portrait.offset_right = 0.0
	portrait.offset_bottom = 0.0
	portrait.custom_minimum_size = Vector2.ZERO
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _apply_static_styles() -> void:
	MenuUiStyle.apply_heading(page_title, 34, Color(1.0, 0.94, 0.72, 1.0))
	MenuUiStyle.apply_body(page_subtitle, 14, Color(0.78, 0.88, 0.92, 0.90))
	MenuUiStyle.apply_panel(sidebar_panel, "jade")
	MenuUiStyle.apply_panel(hero_panel, "empty")
	MenuUiStyle.apply_panel(portrait_frame, "stage")
	MenuUiStyle.apply_title_pill(char_title_pill, "blue")
	MenuUiStyle.apply_panel(stats_card, "jade")
	MenuUiStyle.apply_panel(talent_panel, "scroll")
	MenuUiStyle.apply_panel(skill_panel, "scroll")
	MenuUiStyle.apply_body(char_list_title, 15, Color(0.92, 0.76, 0.40, 1.0))
	MenuUiStyle.apply_body(char_list_hint, 12, Color(0.58, 0.70, 0.74, 0.90))
	MenuUiStyle.apply_body(char_title_label, 14, Color(0.90, 0.78, 0.48, 1.0))
	MenuUiStyle.apply_heading(char_name_label, 42, Color(1.0, 0.96, 0.80, 1.0))
	MenuUiStyle.apply_body(lore_label, 15, Color(0.80, 0.90, 0.92, 0.94))
	MenuUiStyle.apply_body(stats_title, 16, Color(0.36, 0.30, 0.16, 1.0))
	MenuUiStyle.apply_body(talent_title, 15, Color(0.90, 0.72, 0.34, 1.0))
	MenuUiStyle.apply_body(skill_title, 15, Color(0.90, 0.72, 0.34, 1.0))
	MenuUiStyle.apply_body(talent_label, 14, Color(0.16, 0.24, 0.24, 0.98))
	MenuUiStyle.apply_body(skill_label, 14, Color(0.16, 0.24, 0.24, 0.98))
	MenuUiStyle.apply_character_select_button(start_btn, true, 18)
	for tile_name in ["HPTile", "HPRegenTile", "LingLiTile", "LingLiRegenTile", "DaoHuiTile", "DmgTile"]:
		var tile := find_child(tile_name, true, false) as PanelContainer
		if tile:
			MenuUiStyle.apply_panel(tile, "stat")
	for key_name in ["HPKey", "HPRegenKey", "LingLiKey", "LingLiRegenKey", "DaoHuiKey", "DmgKey"]:
		var key_label := find_child(key_name, true, false) as Label
		if key_label:
			MenuUiStyle.apply_body(key_label, 12, Color(0.70, 0.86, 0.84, 0.92))
	for label in [
		hp_label, hp_regen_label, ling_li_label, ling_li_regen_label, dao_hui_label, damage_mult_label
	]:
		MenuUiStyle.apply_body(label, 18, Color(1.0, 0.96, 0.78, 1.0))


func _build_sect_bar() -> void:
	for child in sect_bar.get_children():
		child.queue_free()
	var sects := CharacterDatabase.get_all_sects()
	for sect in sects:
		var btn := Button.new()
		btn.text = sect
		btn.toggle_mode = true
		btn.button_group = _sect_group
		btn.custom_minimum_size = Vector2(150, 42)
		MenuUiStyle.apply_character_select_button(btn, false, 15)
		btn.pressed.connect(_select_sect.bind(sect))
		sect_bar.add_child(btn)
	if not sects.is_empty():
		(sect_bar.get_child(0) as Button).button_pressed = true
		_select_sect(sects[0])


func _select_sect(sect: String) -> void:
	_selected_sect = sect
	char_list_title.text = "%s弟子" % sect
	var sect_data := CharacterDatabase.get_sect_data(sect)
	if sect_data.has("bg_path") and not (sect_data["bg_path"] as String).is_empty():
		var tex: Texture2D = load(sect_data["bg_path"])
		if tex:
			bg_rect.texture = tex
	_build_char_list()


func _build_char_list() -> void:
	for child in char_list_box.get_children():
		child.queue_free()
	_char_group = ButtonGroup.new()
	var chars := CharacterDatabase.get_sect_characters(_selected_sect)
	if chars.is_empty():
		return
	var ids: Array = chars.map(func(c): return c["id"])
	if not ids.has(_selected_char_id):
		_selected_char_id = ids[0]
	for c in chars:
		var btn := Button.new()
		btn.text = c["name"]
		btn.toggle_mode = true
		btn.button_group = _char_group
		btn.pressed.connect(_select_char.bind(c["id"]))
		btn.size_flags_horizontal = Control.SIZE_FILL
		btn.custom_minimum_size = Vector2(0, 50)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		MenuUiStyle.apply_character_select_button(btn, false, 15)
		char_list_box.add_child(btn)
		if c["id"] == _selected_char_id:
			btn.button_pressed = true
	_refresh_display()


func _select_char(char_id: String) -> void:
	_selected_char_id = char_id
	_refresh_display()


func _refresh_display() -> void:
	var c := CharacterDatabase.get_character(_selected_char_id)
	if c.is_empty():
		return
	char_name_label.text = c["name"]
	char_title_label.text = "%s · %s" % [c["sect"], c["title"]]
	lore_label.text = c["lore"]
	var portrait_path := c.get("portrait_cutout_path", c.get("portrait_path", "")) as String
	if not portrait_path.is_empty():
		portrait.texture = load(portrait_path)
	else:
		portrait.texture = null
	hp_label.text = str(c["hp_max"])
	hp_regen_label.text = str(c["hp_regen"])
	ling_li_label.text = str(c["ling_li_max"])
	ling_li_regen_label.text = str(int(c["ling_li_regen"]))
	dao_hui_label.text = str(c["dao_hui_max"])
	damage_mult_label.text = "x%.1f" % c["damage_mult"]
	talent_label.text = "【%s】\n%s" % [c["talent_name"], c["talent_desc"]]
	skill_label.text = "【%s】\n%s" % [c["skill_name"], c["skill_desc"]]
	_animate_selection()


func _animate_scene_in() -> void:
	start_btn.pivot_offset = start_btn.size * 0.5
	main_content.modulate.a = 0.0
	main_content.position.y += 12.0
	start_btn.modulate.a = 0.0
	var t := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	t.tween_property(main_content, "modulate:a", 1.0, 0.34)
	t.tween_property(main_content, "position:y", main_content.position.y - 12.0, 0.34)
	t.tween_property(start_btn, "modulate:a", 1.0, 0.30).set_delay(0.10)


func _animate_selection() -> void:
	if _display_tween and _display_tween.is_valid():
		_display_tween.kill()
	portrait.pivot_offset = portrait.size * 0.5
	portrait.modulate.a = 0.0
	portrait.scale = Vector2(0.985, 0.985)
	stats_card.modulate.a = 0.88
	_display_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_display_tween.tween_property(portrait, "modulate:a", 1.0, 0.22)
	_display_tween.tween_property(portrait, "scale", Vector2.ONE, 0.26)
	_display_tween.tween_property(stats_card, "modulate:a", 1.0, 0.20)


func _on_start_button_down() -> void:
	start_btn.pivot_offset = start_btn.size * 0.5
	start_btn.scale = Vector2(0.985, 0.985)


func _on_start_button_up() -> void:
	start_btn.scale = Vector2.ONE


func _on_btn_start_pressed() -> void:
	GameState.start_run(_selected_char_id)
	get_tree().change_scene_to_file(GAME_MAP_SCENE)


func _on_menu_abandon_confirmed() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_menu_return_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
