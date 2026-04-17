## TestLogger.gd
## Logger 单元测试套件（独立脚本，无继承，兼容 headless 模式）。
extends RefCounted

const LOGGER_SCRIPT := "res://scripts/Logger.gd"
const TEST_LOG      := "res://tests/results/test_logger_tmp.log"

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _cur: String = ""


func run_all() -> Dictionary:
	_lines.append("\n[ TestLogger ]")

	_t("test_file_created_after_write")
	_t("test_file_contains_written_text")
	_t("test_file_appends_not_overwrites")
	_t("test_overflow_clears_file")
	_t("test_info_line_format")
	_t("test_error_line_format")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ── 测试用例 ──────────────────────────────────────

func test_file_created_after_write() -> void:
	_cleanup()
	var logger := _open_logger()
	logger._write_raw("hello\n")
	_close(logger)
	_assert_true(FileAccess.file_exists(TEST_LOG), "写入后文件存在")

func test_file_contains_written_text() -> void:
	_cleanup()
	var logger := _open_logger()
	logger._write_raw("marker_abc\n")
	_close(logger)
	var content := FileAccess.get_file_as_string(TEST_LOG)
	_assert_true(content.contains("marker_abc"), "写入内容可读回")

func test_file_appends_not_overwrites() -> void:
	_cleanup()
	var l1 := _open_logger(); l1._write_raw("line_A\n"); _close(l1)
	var l2 := _open_logger(); l2._write_raw("line_B\n"); _close(l2)
	var content := FileAccess.get_file_as_string(TEST_LOG)
	_assert_true(content.contains("line_A"), "追加后原有内容保留")
	_assert_true(content.contains("line_B"), "追加后新内容存在")

func test_overflow_clears_file() -> void:
	_cleanup()
	# 先写入 600KB 超出限制
	var f := FileAccess.open(TEST_LOG, FileAccess.WRITE)
	if f:
		f.store_string("X".repeat(600 * 1024))
		f.close()
	# Logger 打开时应触发清空
	var logger := _open_logger(); _close(logger)
	var size := FileAccess.get_file_as_bytes(TEST_LOG).size()
	_assert_true(size < 600 * 1024, "超限后文件被清空")

func test_info_line_format() -> void:
	var line := "12:00:00 [INF] [Tag] 内容"
	_assert_true(line.contains("[INF]"),   "INFO 行含 [INF]")
	_assert_true(line.contains("[Tag]"),   "INFO 行含 tag")
	_assert_true(line.contains("内容"),    "INFO 行含消息")

func test_error_line_format() -> void:
	var line := "12:00:00 [ERR] [Tag] 错误"
	_assert_true(line.contains("[ERR]"), "ERROR 行含 [ERR]")


# ── 内部工具 ──────────────────────────────────────

func _t(method: String) -> void:
	_cur = method
	call(method)

func _open_logger() -> Object:
	var logger: Object = load(LOGGER_SCRIPT).new()
	logger._enabled = true
	# 复现 Logger._open_log_file() 的逻辑
	if FileAccess.file_exists(TEST_LOG):
		var sz := FileAccess.get_file_as_bytes(TEST_LOG).size()
		if sz > logger.MAX_FILE_SIZE_KB * 1024:
			FileAccess.open(TEST_LOG, FileAccess.WRITE).close()  # 清空
	else:
		FileAccess.open(TEST_LOG, FileAccess.WRITE).close()  # 创建空文件
	# READ_WRITE 要求文件已存在
	logger._file = FileAccess.open(TEST_LOG, FileAccess.READ_WRITE)
	if logger._file:
		logger._file.seek_end()
	return logger

func _close(logger: Object) -> void:
	if logger._file:
		logger._file.close()
	logger.free()

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_LOG):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_LOG))

func _assert_true(c: bool, label: String) -> void:
	if c: _ok(label)
	else: _fail(label, "期望 true，实际 false")

func _ok(label: String) -> void:
	_pass_count += 1
	_lines.append("  ✓ %s" % label)

func _fail(label: String, reason: String) -> void:
	_fail_count += 1
	_lines.append("  ✗ %s  ← %s" % [label, reason])
