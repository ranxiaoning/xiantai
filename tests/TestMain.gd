## TestMain.gd
## 自动化测试入口，通过 Godot headless 模式运行。
##
## 执行命令（在项目根目录）：
##   run_tests.bat
## 或手动：
##   Godot_v4.6.2-stable_win64.exe --headless --path . -s res://tests/TestMain.gd
##
## 结果写入 tests/results/latest.txt，退出码 0=全部通过，1=存在失败。
extends SceneTree

const RESULT_PATH := "res://tests/results/latest.txt"

var _total_pass := 0
var _total_fail := 0
var _all_lines: Array[String] = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://tests/results")
	)

	_header("《无尽仙台》自动化测试")
	_header(Time.get_datetime_string_from_system())

	# ── 注册测试套件 ──────────────────────────────
	# 白盒/完整性测试（优先运行，暴露解析错误）
	_run_suite(load("res://tests/suites/TestScriptIntegrity.gd").new())
	# 单元测试
	_run_suite(load("res://tests/suites/TestGlobalSettings.gd").new())
	_run_suite(load("res://tests/suites/TestLogger.gd").new())
	# 新增套件在此继续 _run_suite(...)

	# ── 汇总 ─────────────────────────────────────
	_separator()
	_line("总计：%d 通过  %d 失败" % [_total_pass, _total_fail])
	if _total_fail == 0:
		_line("✅ 全部通过")
	else:
		_line("❌ 存在失败，请检查上方详情")
	_separator()

	# 写入结果文件
	var f := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_all_lines) + "\n")
		f.close()

	# 同时打印到控制台（Godot Output 面板 / 命令行）
	print("\n".join(_all_lines))

	quit(0 if _total_fail == 0 else 1)


# ── 内部 ─────────────────────────────────────────

func _run_suite(suite: Object) -> void:
	var result: Dictionary = suite.run_all()
	_total_pass += result["pass"]
	_total_fail += result["fail"]
	for l in result["lines"]:
		_all_lines.append(l)


func _header(text: String) -> void:
	_separator()
	_line(text)
	_separator()


func _separator() -> void:
	_line("─".repeat(50))


func _line(text: String) -> void:
	_all_lines.append(text)
