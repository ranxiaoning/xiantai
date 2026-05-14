## OptionsMenu.gd
## Display, audio, and language settings screen.
extends Control

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const MenuUiStyle = preload("res://scripts/ui/MenuUiStyle.gd")

@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var page_title: Label = %PageTitle
@onready var page_subtitle: Label = %PageSubTitle
@onready var display_mode_option: OptionButton = %DisplayModeOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var master_slider: HSlider = %MasterSlider
@onready var master_label: Label = %MasterLabel
@onready var music_slider: HSlider = %MusicSlider
@onready var music_label: Label = %MusicLabel
@onready var sfx_slider: HSlider = %SFXSlider
@onready var sfx_label: Label = %SFXLabel
@onready var language_option: OptionButton = %LanguageOption
@onready var apply_button: Button = %BtnApply
@onready var back_button: Button = %BtnBack


func _ready() -> void:
	theme = load("res://theme/main_theme.tres")
	_apply_static_styles()
	_populate_display_mode_options()
	_populate_resolution_options()
	_populate_language_options()
	_load_current_settings()
	_play_entrance_anim()
	back_button.grab_focus()


func _apply_static_styles() -> void:
	MenuUiStyle.apply_options_panel(settings_panel)
	MenuUiStyle.apply_heading(page_title, 35, Color(1.0, 0.93, 0.66, 1.0))
	MenuUiStyle.apply_body(page_subtitle, 14, Color(0.88, 0.95, 0.93, 0.96))
	MenuUiStyle.apply_options_option_button(display_mode_option)
	MenuUiStyle.apply_options_option_button(resolution_option)
	MenuUiStyle.apply_options_option_button(language_option)
	for slider in [master_slider, music_slider, sfx_slider]:
		MenuUiStyle.apply_options_slider(slider)
	for label in [master_label, music_label, sfx_label]:
		MenuUiStyle.apply_options_value_label(label)
	for label_name in ["SectionDisplay", "SectionAudio", "SectionLocale"]:
		var section_label := find_child(label_name, true, false) as Label
		if section_label:
			MenuUiStyle.apply_options_section_label(section_label)
	for label_name in [
		"DisplayModeRowLabel", "ResolutionRowLabel", "MasterRowLabel",
		"MusicRowLabel", "SFXRowLabel", "LanguageRowLabel"
	]:
		var row_label := find_child(label_name, true, false) as Label
		if row_label:
			MenuUiStyle.apply_options_row_label(row_label)
	MenuUiStyle.apply_options_action_button(apply_button, true)
	MenuUiStyle.apply_options_action_button(back_button, false)


func _populate_resolution_options() -> void:
	resolution_option.clear()
	for res in GlobalSettings.RESOLUTIONS:
		resolution_option.add_item("%d x %d" % [res.x, res.y])


func _populate_display_mode_options() -> void:
	display_mode_option.clear()
	display_mode_option.add_item("窗口化")
	display_mode_option.add_item("无边框窗口")
	display_mode_option.add_item("全屏")


func _populate_language_options() -> void:
	language_option.clear()
	language_option.add_item("中文")
	language_option.add_item("English")


func _load_current_settings() -> void:
	display_mode_option.selected = GlobalSettings.display_mode
	resolution_option.selected = GlobalSettings.resolution_index
	_update_resolution_enabled()
	master_slider.value = GlobalSettings.master_volume
	music_slider.value = GlobalSettings.music_volume
	sfx_slider.value = GlobalSettings.sfx_volume
	_update_volume_labels()
	language_option.selected = 0 if GlobalSettings.language == "zh_CN" else 1


func _update_volume_labels() -> void:
	master_label.text = "%d%%" % roundi(master_slider.value * 100)
	music_label.text = "%d%%" % roundi(music_slider.value * 100)
	sfx_label.text = "%d%%" % roundi(sfx_slider.value * 100)


func _play_entrance_anim() -> void:
	await get_tree().process_frame
	settings_panel.modulate.a = 0.0
	settings_panel.position.y += 10.0
	var t := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	t.tween_property(settings_panel, "modulate:a", 1.0, 0.30)
	t.tween_property(settings_panel, "position:y", settings_panel.position.y - 10.0, 0.30)


func _on_resolution_option_item_selected(index: int) -> void:
	GlobalSettings.resolution_index = index


func _on_display_mode_option_item_selected(index: int) -> void:
	GlobalSettings.set_display_mode(index)
	_update_resolution_enabled()


func _update_resolution_enabled() -> void:
	resolution_option.disabled = (
		GlobalSettings.display_mode == GlobalSettings.DISPLAY_MODE_FULLSCREEN
	)


func _on_master_slider_value_changed(value: float) -> void:
	GlobalSettings.master_volume = value
	GlobalSettings.apply_audio()
	master_label.text = "%d%%" % roundi(value * 100)


func _on_music_slider_value_changed(value: float) -> void:
	GlobalSettings.music_volume = value
	GlobalSettings.apply_audio()
	music_label.text = "%d%%" % roundi(value * 100)


func _on_sfx_slider_value_changed(value: float) -> void:
	GlobalSettings.sfx_volume = value
	GlobalSettings.apply_audio()
	sfx_label.text = "%d%%" % roundi(value * 100)


func _on_language_option_item_selected(index: int) -> void:
	GlobalSettings.language = "zh_CN" if index == 0 else "en"
	GlobalSettings.apply_language()


func _on_btn_apply_pressed() -> void:
	GlobalSettings.apply_display()
	GlobalSettings.save_settings()


func _on_btn_back_pressed() -> void:
	GlobalSettings.save_settings()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
