## MainMenu.gd
## Main entry screen: start run, options, quit.
extends Control

const OPTIONS_SCENE := "res://scenes/OptionsMenu.tscn"
const CHAR_SELECT_SCENE := "res://scenes/CharacterSelect.tscn"
const MenuUiStyle = preload("res://scripts/ui/MenuUiStyle.gd")

@onready var menu_panel: PanelContainer = %MenuPanel
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var flavor_frame: PanelContainer = %FlavorFrame
@onready var flavor_label: Label = %Flavor
@onready var buttons: VBoxContainer = %Buttons
@onready var start_button: Button = %BtnStart
@onready var options_button: Button = %BtnOptions
@onready var exit_button: Button = %BtnExit
@onready var version_label: Label = %VersionLabel
@onready var seal_ring: TextureRect = $SealRing


func _ready() -> void:
	theme = load("res://theme/main_theme.tres")
	Log.info("MainMenu", "Main menu loaded")
	MusicManager.play("menu")
	_apply_static_styles()
	_setup_visual_fx()
	_play_entrance_anim()
	start_button.grab_focus()


func _apply_static_styles() -> void:
	MenuUiStyle.apply_panel(menu_panel, "empty")
	MenuUiStyle.apply_result_panel(flavor_frame)
	MenuUiStyle.apply_heading(title_label, 78, Color(0.055, 0.040, 0.020, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.86, 0.48, 0.44))
	title_label.add_theme_constant_override("shadow_outline_size", 3)
	MenuUiStyle.apply_body(subtitle_label, 17, Color(0.045, 0.055, 0.050, 0.94))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.90, 0.62, 0.34))
	MenuUiStyle.apply_body(flavor_label, 15, Color(0.88, 0.94, 0.92, 0.94))
	MenuUiStyle.apply_body(version_label, 13, Color(0.76, 0.82, 0.82, 0.72))
	MenuUiStyle.apply_main_menu_button(start_button, 20)
	MenuUiStyle.apply_main_menu_button(options_button, 18)
	MenuUiStyle.apply_main_menu_button(exit_button, 18)


func _setup_visual_fx() -> void:
	var fx: Control = load("res://scripts/MenuParticles.gd").new()
	add_child(fx)
	move_child(fx, 1)


func _play_entrance_anim() -> void:
	await get_tree().process_frame
	menu_panel.modulate.a = 0.0
	menu_panel.position.y += 16.0
	seal_ring.modulate.a = 0.0
	seal_ring.scale = Vector2(0.96, 0.96)
	var panel_tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	panel_tween.tween_property(menu_panel, "modulate:a", 1.0, 0.42)
	panel_tween.tween_property(menu_panel, "position:y", menu_panel.position.y - 16.0, 0.42)
	panel_tween.tween_property(seal_ring, "modulate:a", 0.62, 0.50)
	panel_tween.tween_property(seal_ring, "scale", Vector2.ONE, 0.50)

	var btns: Array[Button] = [start_button, options_button, exit_button]
	for i in btns.size():
		var btn := btns[i]
		btn.modulate.a = 0.0
		btn.pivot_offset = btn.size * 0.5
		btn.scale = Vector2(0.96, 0.96)
		var t := create_tween()
		t.tween_interval(0.18 + i * 0.08)
		t.tween_property(btn, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(btn, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_btn_start_pressed() -> void:
	get_tree().change_scene_to_file(CHAR_SELECT_SCENE)


func _on_btn_options_pressed() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE)


func _on_btn_exit_pressed() -> void:
	get_tree().quit()
