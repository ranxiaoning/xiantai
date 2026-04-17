## OptionsMenu.gd
## 选项界面：分辨率、全屏、总音量、音乐音量、音效音量、语言。
extends Control

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

# 控件引用（通过 @onready 绑定场景节点）
@onready var resolution_option: OptionButton = $Content/Display/ResolutionRow/ResolutionOption
@onready var fullscreen_check:  CheckButton  = $Content/Display/FullscreenRow/FullscreenCheck
@onready var master_slider:     HSlider      = $Content/Audio/MasterRow/MasterSlider
@onready var master_label:      Label        = $Content/Audio/MasterRow/MasterLabel
@onready var music_slider:      HSlider      = $Content/Audio/MusicRow/MusicSlider
@onready var music_label:       Label        = $Content/Audio/MusicRow/MusicLabel
@onready var sfx_slider:        HSlider      = $Content/Audio/SFXRow/SFXSlider
@onready var sfx_label:         Label        = $Content/Audio/SFXRow/SFXLabel
@onready var language_option:   OptionButton = $Content/Locale/LanguageRow/LanguageOption


func _ready() -> void:
	_populate_resolution_options()
	_populate_language_options()
	_load_current_settings()
	$BtnBack.grab_focus()


# ── 初始化控件 ─────────────────────────────────

func _populate_resolution_options() -> void:
	resolution_option.clear()
	for res in GlobalSettings.RESOLUTIONS:
		resolution_option.add_item("%d × %d" % [res.x, res.y])


func _populate_language_options() -> void:
	language_option.clear()
	language_option.add_item("中文")   # index 0 → zh_CN
	language_option.add_item("English")  # index 1 → en


func _load_current_settings() -> void:
	# 显示
	resolution_option.selected = GlobalSettings.resolution_index
	fullscreen_check.button_pressed = GlobalSettings.fullscreen
	# 音量
	master_slider.value = GlobalSettings.master_volume
	music_slider.value  = GlobalSettings.music_volume
	sfx_slider.value    = GlobalSettings.sfx_volume
	_update_volume_labels()
	# 语言
	language_option.selected = 0 if GlobalSettings.language == "zh_CN" else 1


func _update_volume_labels() -> void:
	master_label.text = "%d%%" % roundi(master_slider.value * 100)
	music_label.text  = "%d%%" % roundi(music_slider.value  * 100)
	sfx_label.text    = "%d%%" % roundi(sfx_slider.value    * 100)


# ── 控件信号回调 ───────────────────────────────

func _on_resolution_option_item_selected(index: int) -> void:
	GlobalSettings.resolution_index = index


func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	GlobalSettings.fullscreen = toggled_on
	# 全屏时禁用分辨率选择
	resolution_option.disabled = toggled_on


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


# ── 按钮回调 ──────────────────────────────────

func _on_btn_apply_pressed() -> void:
	GlobalSettings.apply_display()
	GlobalSettings.save_settings()


func _on_btn_back_pressed() -> void:
	GlobalSettings.save_settings()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
