## Logger.gd
## 调试日志工具，将日志同时输出到控制台和项目目录下的 debug.log 文件。
##
## ⚠ 调用规范：
##   Logger 是 Autoload，GDScript 解析器无法在编译期验证其实例方法，
##   直接写 Logger.info(...) 会引发 Parse Error。
##   正确的调用方式（选一）：
##     1. 运行时调用：get_node("/root/Logger").info("Tag", "msg")
##     2. 简便封装：  Log.info("Tag", "msg")  ← 见 scripts/Log.gd
##     3. 直接用内置：print("[Tag] msg")（无文件持久化）
##
## 日志文件位置：<项目根目录>/debug.log（仅 DEBUG 模式下写入文件）
extends Node

enum Level { DEBUG, INFO, WARN, ERROR }

const LOG_PATH := "res://debug.log"   # 写到项目目录，方便 Claude Code 读取
const MAX_FILE_SIZE_KB := 512         # 超过此大小自动清空，防止日志爆炸

var _file: FileAccess = null
var _enabled: bool = true             # 发布版可设为 false


func _ready() -> void:
	if OS.is_debug_build():
		_open_log_file()


func _open_log_file() -> void:
	# 检查文件大小，超限则清空
	if FileAccess.file_exists(LOG_PATH):
		var size := FileAccess.get_file_as_bytes(LOG_PATH).size()
		if size > MAX_FILE_SIZE_KB * 1024:
			FileAccess.open(LOG_PATH, FileAccess.WRITE).close()  # 清空
	else:
		FileAccess.open(LOG_PATH, FileAccess.WRITE).close()  # 创建空文件

	# READ_WRITE 要求文件已存在，上面已确保
	_file = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if _file:
		_file.seek_end()
		_write_raw("\n=== 游戏启动 %s ===\n" % Time.get_datetime_string_from_system())


func debug(tag: String, msg: String) -> void:
	_log(Level.DEBUG, tag, msg)

func info(tag: String, msg: String) -> void:
	_log(Level.INFO, tag, msg)

func warn(tag: String, msg: String) -> void:
	_log(Level.WARN, tag, msg)

func error(tag: String, msg: String) -> void:
	_log(Level.ERROR, tag, msg)


const _LEVEL_PREFIX: Array[String] = ["[DBG]", "[INF]", "[WRN]", "[ERR]"]

func _log(level: Level, tag: String, msg: String) -> void:
	if not _enabled:
		return
	var prefix: String = _LEVEL_PREFIX[level]
	var time: String = Time.get_time_string_from_system()
	var line := "%s %s [%s] %s" % [time, prefix, tag, msg]

	# 始终输出到 Godot Output 面板
	if level == Level.ERROR:
		push_error(line)
	elif level == Level.WARN:
		push_warning(line)
	else:
		print(line)

	# DEBUG 模式下同时写文件
	if OS.is_debug_build() and _file:
		_write_raw(line + "\n")


func _write_raw(text: String) -> void:
	_file.store_string(text)
	_file.flush()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _file:
		_file.close()
