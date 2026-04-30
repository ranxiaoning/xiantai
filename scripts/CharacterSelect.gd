## CharacterSelect.gd
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"
const GOLD := Color(0.82, 0.68, 0.39, 1.0)
const GOLD_DIM := Color(0.48, 0.39, 0.23, 1.0)
const INK := Color(0.035, 0.052, 0.065, 0.86)
const INK_DARK := Color(0.018, 0.027, 0.036, 0.93)
const INK_SOFT := Color(0.08, 0.11, 0.13, 0.72)

var _selected_sect: String = "万剑门"
var _selected_char_id: String = "chen_tian_feng"

var _sect_group := ButtonGroup.new()
var _char_group := ButtonGroup.new()
var _display_tween: Tween = null

@onready var bg_rect: TextureRect = $BG
@onready var sect_bar: HBoxContainer = %SectBar
@onready var char_list_box: VBoxContainer = %CharListBox
@onready var char_list_title: Label = $MainContent/SidebarPanel/SidebarPad/CharListPanel/CharListTitle
@onready var char_name_label: Label = %CharName
@onready var char_title_label: Label = %CharTitle
@onready var portrait: TextureRect = %Portrait
@onready var lore_label: Label = %Lore
@onready var hp_label: Label = %HPValue
@onready var hp_regen_label: Label = %HPRegenValue
@onready var ling_li_label: Label = %LingLiValue
@onready var dao_hui_label: Label = %DaoHuiValue
@onready var damage_mult_label: Label = %DmgValue
@onready var talent_label: Label = %TalentDesc
@onready var skill_label: Label = %SkillDesc
@onready var sidebar_panel: PanelContainer = $MainContent/SidebarPanel
@onready var hero_panel: PanelContainer = $MainContent/HeroPanel
@onready var portrait_frame: PanelContainer = $MainContent/HeroPanel/HeroPad/CharDetailPanel/PortraitFrame
@onready var portrait_stage: Control = $MainContent/HeroPanel/HeroPad/CharDetailPanel/PortraitFrame/PortraitMargin/PortraitStage
@onready var stats_card: PanelContainer = $MainContent/StatsCard
@onready var talent_panel: PanelContainer = $MainContent/StatsCard/StatsPad/StatsPanel/TalentPanel
@onready var skill_panel: PanelContainer = $MainContent/StatsCard/StatsPad/StatsPanel/SkillPanel
@onready var start_btn: Button = %StartBtn
@onready var main_content: HBoxContainer = %MainContent


func _ready() -> void:
	MusicManager.play("char_select")
	_configure_portrait_layout()
	_apply_static_styles()
	_build_sect_bar()
	start_btn.button_down.connect(_on_start_button_down)
	start_btn.button_up.connect(_on_start_button_up)
	call_deferred("_animate_scene_in")


func _configure_portrait_layout() -> void:
	var viewport_h := get_viewport_rect().size.y
	portrait_frame.clip_contents = true
	portrait_frame.custom_minimum_size = Vector2(0.0, clampf(viewport_h * 0.445, 300.0, 500.0))
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
	_apply_panel(sidebar_panel, INK, GOLD_DIM, 0.55)
	_apply_panel(hero_panel, Color(0.03, 0.045, 0.055, 0.72), GOLD_DIM, 0.52)
	_apply_panel(portrait_frame, Color(0.02, 0.027, 0.032, 0.82), GOLD, 0.72)
	_apply_panel(stats_card, INK_DARK, GOLD_DIM, 0.58)
	_apply_panel(talent_panel, INK_SOFT, GOLD_DIM, 0.40)
	_apply_panel(skill_panel, INK_SOFT, GOLD_DIM, 0.40)
	_style_start_button()


func _apply_panel(panel: PanelContainer, bg: Color, border: Color, border_alpha: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	var b := border
	b.a = border_alpha
	style.border_color = b
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0, 0, 0, 0.36)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)


func _button_style(bg: Color, border: Color, font: Color) -> Dictionary:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return {"style": style, "font": font}


func _apply_button_theme(btn: Button, compact: bool = false) -> void:
	var normal_data := _button_style(Color(0.045, 0.062, 0.074, 0.86), Color(0.36, 0.32, 0.24, 0.75), Color(0.80, 0.86, 0.90))
	var normal: StyleBoxFlat = normal_data["style"]
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.075, 0.098, 0.11, 0.92)
	hover.border_color = Color(0.70, 0.58, 0.33, 0.88)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.58, 0.45, 0.20, 0.92)
	pressed.border_color = Color(0.92, 0.76, 0.40, 1.0)
	var focus := hover.duplicate() as StyleBoxFlat
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_color_override("font_color", normal_data["font"])
	btn.add_theme_color_override("font_hover_color", Color(0.92, 0.90, 0.78))
	btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.07, 0.04))
	btn.add_theme_font_size_override("font_size", 14 if compact else 15)
	btn.focus_mode = Control.FOCUS_NONE


func _style_start_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.68, 0.50, 0.20, 0.94)
	normal.border_color = Color(0.94, 0.77, 0.38, 0.95)
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.78, 0.60, 0.27, 0.98)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.48, 0.35, 0.15, 0.98)
	start_btn.add_theme_stylebox_override("normal", normal)
	start_btn.add_theme_stylebox_override("hover", hover)
	start_btn.add_theme_stylebox_override("pressed", pressed)
	start_btn.add_theme_color_override("font_color", Color(0.08, 0.06, 0.035))
	start_btn.add_theme_color_override("font_hover_color", Color(0.05, 0.04, 0.02))
	start_btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.88, 0.67))
	start_btn.pivot_offset = start_btn.size * 0.5


func _build_sect_bar() -> void:
	for child in sect_bar.get_children():
		child.queue_free()
	var sects := CharacterDatabase.get_all_sects()
	for sect in sects:
		var btn := Button.new()
		btn.text = sect
		btn.toggle_mode = true
		btn.button_group = _sect_group
		btn.custom_minimum_size = Vector2(126, 38)
		_apply_button_theme(btn, true)
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
		btn.custom_minimum_size = Vector2(0, 42)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_button_theme(btn)
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
	char_title_label.text = c["sect"] + "  ·  " + c["title"]
	lore_label.text = c["lore"]
	if c.has("portrait_path") and not (c["portrait_path"] as String).is_empty():
		portrait.texture = load(c["portrait_path"])
	else:
		portrait.texture = null
	hp_label.text = str(c["hp_max"])
	hp_regen_label.text = str(c["hp_regen"])
	ling_li_label.text = "%d（回复 %d/回合）" % [c["ling_li_max"], c["ling_li_regen"]]
	dao_hui_label.text = str(c["dao_hui_max"])
	damage_mult_label.text = "×%.1f" % c["damage_mult"]
	talent_label.text = "【%s】%s" % [c["talent_name"], c["talent_desc"]]
	skill_label.text = "【%s】%s" % [c["skill_name"], c["skill_desc"]]
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
