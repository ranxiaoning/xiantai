## GlobalSettings.gd
## 全局设置单例（Autoload），负责持久化读写分辨率、音量、语言等配置。
extends Node

const SETTINGS_PATH := "user://settings.cfg"

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
var resolution_index: int = 0   # 对应 RESOLUTIONS 中的下标
var fullscreen: bool = false

# 语言
var language: String = "zh_CN"  # "zh_CN" | "en"

# ─────────────────────────────────────────────
var _config := ConfigFile.new()


func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	apply_all()


# ── 持久化 ────────────────────────────────────

func load_settings() -> void:
	if _config.load(SETTINGS_PATH) != OK:
		return  # 首次运行，使用默认值
	master_volume    = _config.get_value("audio",   "master_volume",   master_volume)
	music_volume     = _config.get_value("audio",   "music_volume",    music_volume)
	sfx_volume       = _config.get_value("audio",   "sfx_volume",      sfx_volume)
	resolution_index = _config.get_value("display", "resolution_index", resolution_index)
	fullscreen       = _config.get_value("display", "fullscreen",       fullscreen)
	language         = _config.get_value("locale",  "language",        language)
	# 边界保护
	resolution_index = clamp(resolution_index, 0, RESOLUTIONS.size() - 1)


func save_settings() -> void:
	_config.set_value("audio",   "master_volume",    master_volume)
	_config.set_value("audio",   "music_volume",     music_volume)
	_config.set_value("audio",   "sfx_volume",       sfx_volume)
	_config.set_value("display", "resolution_index", resolution_index)
	_config.set_value("display", "fullscreen",       fullscreen)
	_config.set_value("locale",  "language",         language)
	_config.save(SETTINGS_PATH)


# ── 应用设置 ───────────────────────────────────

func apply_all() -> void:
	apply_audio()
	apply_display()
	apply_language()


func apply_audio() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music",  music_volume)
	_set_bus_volume("SFX",    sfx_volume)


func apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var res := RESOLUTIONS[resolution_index]
		DisplayServer.window_set_size(res)
		# 窗口居中
		var screen_size := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - res) / 2)


func apply_language() -> void:
	TranslationServer.set_locale(language)


# ── 内部工具 ───────────────────────────────────

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.0)


func _ensure_audio_buses() -> void:
	# Godot 默认只有 Master，手动补充 Music / SFX 子总线
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
