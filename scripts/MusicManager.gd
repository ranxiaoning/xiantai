## MusicManager.gd
## 全局音乐管理器：场景切换时自动 2s 淡出/淡入，战斗随机选曲，循环播放。
extends Node

const FADE_TIME := 2.0

const TRACKS: Dictionary = {
	"menu":        "res://assets/audio/music/Ink_on_the_Mountain_Path.mp3",
	"char_select": "res://assets/audio/music/Ink_on_the_Mountain_Path.mp3",
	"map":         "res://assets/audio/music/Above_the_Sea_of_Clouds.mp3",
	"battle": [
		"res://assets/audio/music/Severing_the_Celestial_Gate.mp3",
		"res://assets/audio/music/The_Master_s_Silent_Vow.mp3",
	],
}

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _current_path: String = ""
var _tween: Tween


func _ready() -> void:
	_player_a = _make_player()
	_player_b = _make_player()
	_active = _player_a


func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = -80.0
	add_child(p)
	return p


func play(key: String) -> void:
	var entry = TRACKS.get(key)
	if entry == null:
		return

	var path: String
	if entry is Array:
		entry.shuffle()
		path = entry[0]
	else:
		path = entry

	# 同一文件正在播放，不打断
	if path == _current_path:
		return

	_current_path = path
	_crossfade(path)


func _crossfade(path: String) -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	var next: AudioStreamPlayer = _player_b if _active == _player_a else _player_a
	next.stream = stream
	next.volume_db = -80.0
	next.play()

	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	if _active.playing:
		_tween.tween_property(_active, "volume_db", -80.0, FADE_TIME)
	_tween.tween_property(next, "volume_db", 0.0, FADE_TIME)

	_active = next
