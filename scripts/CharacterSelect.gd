## CharacterSelect.gd
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"

var _selected_char_id: String = "chen_tian_feng"

@onready var char_name_label:    Label = $Content/Left/CharPanel/PadMargin/InnerBox/CharName
@onready var char_title_label:   Label = $Content/Left/CharPanel/PadMargin/InnerBox/CharTitle
@onready var lore_label:         Label = $Content/Left/CharPanel/PadMargin/InnerBox/Lore

@onready var hp_label:           Label = $Content/Right/Stats/HPRow/Value
@onready var hp_regen_label:     Label = $Content/Right/Stats/HPRegenRow/Value
@onready var ling_li_label:      Label = $Content/Right/Stats/LingLiRow/Value
@onready var ling_li_regen_label:Label = $Content/Right/Stats/LingLiRegenRow/Value
@onready var dao_hui_label:      Label = $Content/Right/Stats/DaoHuiRow/Value
@onready var damage_mult_label:  Label = $Content/Right/Stats/DmgRow/Value
@onready var talent_label:       Label = $Content/Right/Talent/TalentPad/TalentDesc
@onready var skill_label:        Label = $Content/Right/Skill/SkillPad/SkillDesc


func _ready() -> void:
	MusicManager.play("char_select")
	_refresh_display()


func _refresh_display() -> void:
	var c := CharacterDatabase.get_character(_selected_char_id)
	if c.is_empty():
		return
	char_name_label.text  = c["name"]
	char_title_label.text = c["sect"] + "  ·  " + c["title"]
	lore_label.text       = c["lore"]

	hp_label.text           = str(c["hp_max"])
	hp_regen_label.text     = str(c["hp_regen"])
	ling_li_label.text      = "%d（回复 %d/回合）" % [c["ling_li_max"], c["ling_li_regen"]]
	ling_li_regen_label.text= str(c["ling_li_regen"])
	dao_hui_label.text      = str(c["dao_hui_max"])
	damage_mult_label.text  = "×%.1f" % c["damage_mult"]
	talent_label.text = "【%s】%s" % [c["talent_name"], c["talent_desc"]]
	skill_label.text  = "【%s】%s" % [c["skill_name"], c["skill_desc"]]


func _on_btn_start_pressed() -> void:
	GameState.start_run(_selected_char_id)
	get_tree().change_scene_to_file(GAME_MAP_SCENE)
