## GlobalSettings.gd
## 全局设置单例（Autoload），负责持久化读写分辨率、音量、语言等配置。
extends Node

const SETTINGS_PATH := "user://settings.cfg"

const DISPLAY_MODE_WINDOWED := 0
const DISPLAY_MODE_BORDERLESS := 1
const DISPLAY_MODE_FULLSCREEN := 2
const DISPLAY_MODE_COUNT := 3

# 可选分辨率列表
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

# 音量（0.0 ~ 1.0 线性值）
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8

# 显示
var resolution_index: int = 0
var display_mode: int = DISPLAY_MODE_WINDOWED
var fullscreen: bool = false
var borderless_window: bool = false

# 语言
var language: String = "zh_CN"

var _config := ConfigFile.new()


func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	apply_all()


func load_settings() -> void:
	if _config.load(SETTINGS_PATH) != OK:
		return
	master_volume = _config.get_value("audio", "master_volume", master_volume)
	music_volume = _config.get_value("audio", "music_volume", music_volume)
	sfx_volume = _config.get_value("audio", "sfx_volume", sfx_volume)
	resolution_index = _config.get_value("display", "resolution_index", resolution_index)
	if _config.has_section_key("display", "display_mode"):
		display_mode = _config.get_value("display", "display_mode", display_mode)
	else:
		fullscreen = _config.get_value("display", "fullscreen", fullscreen)
		borderless_window = _config.get_value("display", "borderless_window", borderless_window)
		display_mode = _display_mode_from_legacy_flags()
	language = _config.get_value("locale", "language", language)
	resolution_index = clampi(resolution_index, 0, RESOLUTIONS.size() - 1)
	display_mode = clampi(display_mode, DISPLAY_MODE_WINDOWED, DISPLAY_MODE_COUNT - 1)
	_sync_legacy_display_flags()


func save_settings() -> void:
	display_mode = clampi(display_mode, DISPLAY_MODE_WINDOWED, DISPLAY_MODE_COUNT - 1)
	_sync_legacy_display_flags()
	_config.set_value("audio", "master_volume", master_volume)
	_config.set_value("audio", "music_volume", music_volume)
	_config.set_value("audio", "sfx_volume", sfx_volume)
	_config.set_value("display", "resolution_index", resolution_index)
	_config.set_value("display", "display_mode", display_mode)
	_config.set_value("display", "fullscreen", fullscreen)
	_config.set_value("display", "borderless_window", borderless_window)
	_config.set_value("locale", "language", language)
	_config.save(SETTINGS_PATH)


func apply_all() -> void:
	apply_audio()
	apply_display()
	apply_language()


func apply_audio() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)


func set_display_mode(mode: int) -> void:
	display_mode = clampi(mode, DISPLAY_MODE_WINDOWED, DISPLAY_MODE_COUNT - 1)
	_sync_legacy_display_flags()


func apply_display() -> void:
	display_mode = clampi(display_mode, DISPLAY_MODE_WINDOWED, DISPLAY_MODE_COUNT - 1)
	_sync_legacy_display_flags()
	if display_mode == DISPLAY_MODE_FULLSCREEN:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(
			DisplayServer.WINDOW_FLAG_BORDERLESS,
			display_mode == DISPLAY_MODE_BORDERLESS
		)
		var res := RESOLUTIONS[resolution_index]
		DisplayServer.window_set_size(res)
		var screen_size := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - res) / 2)


func apply_language() -> void:
	TranslationServer.set_locale(language)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.0)


func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")


func _display_mode_from_legacy_flags() -> int:
	if fullscreen:
		return DISPLAY_MODE_FULLSCREEN
	return DISPLAY_MODE_WINDOWED


func _sync_legacy_display_flags() -> void:
	fullscreen = display_mode == DISPLAY_MODE_FULLSCREEN
	borderless_window = display_mode == DISPLAY_MODE_BORDERLESS
