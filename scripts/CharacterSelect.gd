## CharacterSelect.gd
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"

var _selected_sect: String = "万剑门"
var _selected_char_id: String = "chen_tian_feng"

var _sect_group := ButtonGroup.new()
var _char_group := ButtonGroup.new()

@onready var bg_rect: TextureRect = $BG
@onready var sect_bar: HBoxContainer = %SectBar
@onready var char_list_box: VBoxContainer = %CharListBox
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


func _ready() -> void:
	MusicManager.play("char_select")
	_build_sect_bar()


func _build_sect_bar() -> void:
	for child in sect_bar.get_children():
		child.queue_free()
	var sects := CharacterDatabase.get_all_sects()
	for sect in sects:
		var btn := Button.new()
		btn.text = sect
		btn.toggle_mode = true
		btn.button_group = _sect_group
		btn.custom_minimum_size = Vector2(120, 40)
		btn.pressed.connect(_select_sect.bind(sect))
		sect_bar.add_child(btn)
	if not sects.is_empty():
		(sect_bar.get_child(0) as Button).button_pressed = true
		_select_sect(sects[0])


func _select_sect(sect: String) -> void:
	_selected_sect = sect
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
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
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


func _on_btn_start_pressed() -> void:
	GameState.start_run(_selected_char_id)
	get_tree().change_scene_to_file(GAME_MAP_SCENE)
