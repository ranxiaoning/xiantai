## TestMain.gd
## 自动化测试入口，通过 Godot headless 模式运行。
##
## 执行命令（在项目根目录）：
##   run_tests.bat                          # 全量回归
##   run_suite.bat TestBattleEngineLogic    # 只跑单个 suite
##   run_tests.bat --suite TestMapGenerator # 指定 suite
##
## 结果写入 tests/results/latest.txt，退出码 0=全部通过，1=存在失败。
extends SceneTree

const RESULT_PATH := "res://tests/results/latest.txt"

var _total_pass := 0
var _total_fail := 0
var _all_lines: Array[String] = []
var _suite_filter: Array[String] = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://tests/results")
	)

	# 解析 --suite 参数（Godot 用户参数通过 -- 分隔传入）
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--suite" and i + 1 < args.size():
			_suite_filter.append(args[i + 1])

	var header := "《无尽仙台》自动化测试"
	if not _suite_filter.is_empty():
		header += "  [仅运行: %s]" % ", ".join(_suite_filter)
	_header(header)
	_header(Time.get_datetime_string_from_system())

	# ── 注册测试套件 ──────────────────────────────────────────────
	# 白盒/完整性测试（优先运行，暴露解析错误）
	_maybe_run("TestScriptIntegrity",  func(): return load("res://tests/suites/TestScriptIntegrity.gd").new())
	# 单元测试
	_maybe_run("TestGlobalSettings",   func(): return load("res://tests/suites/TestGlobalSettings.gd").new())
	_maybe_run("TestLogger",           func(): return load("res://tests/suites/TestLogger.gd").new())
	_maybe_run("TestBattleData",       func(): return load("res://tests/suites/TestBattleData.gd").new())
	_maybe_run("TestHandLayout",       func(): return load("res://tests/suites/TestHandLayout.gd").new())
	_maybe_run("TestRewardScreen",     func(): return load("res://tests/suites/TestRewardScreen.gd").new())
	_maybe_run("TestGameMapFlow",      func(): return load("res://tests/suites/TestGameMapFlow.gd").new())
	_maybe_run("TestInGameMenu",       func(): return load("res://tests/suites/TestInGameMenu.gd").new())
	_maybe_run("TestCharacterSelect",  func(): return load("res://tests/suites/TestCharacterSelect.gd").new())
	_maybe_run("TestBattleEngineLogic",func(): return load("res://tests/suites/TestBattleEngineLogic.gd").new())
	_maybe_run("TestMapGenerator",     func(): return load("res://tests/suites/TestMapGenerator.gd").new())
	_maybe_run("TestCardEffects",      func(): return load("res://tests/suites/TestCardEffects.gd").new())
	_maybe_run("TestEnemyBehavior",    func(): return load("res://tests/suites/TestEnemyBehavior.gd").new())
	_maybe_run("TestSpiritStones",     func(): return load("res://tests/suites/TestSpiritStones.gd").new())
	# 新增套件在此继续 _maybe_run("TestXxx", func(): return load("res://tests/suites/TestXxx.gd").new())
	# 注意：TestEnemyDebug 是诊断工具，不纳入自动化（手动调用时直接 -s 运行该文件）

	# ── 汇总 ─────────────────────────────────────────────────────
	_separator()
	_line("总计：%d 通过  %d 失败" % [_total_pass, _total_fail])
	if _total_fail == 0:
		_line("✓ 全部通过")
	else:
		_line("✗ 存在失败，请检查上方详情")
	_separator()

	# 写入结果文件
	var f := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_all_lines) + "\n")
		f.close()

	quit(0 if _total_fail == 0 else 1)


# ── 内部 ─────────────────────────────────────────────────────────

func _maybe_run(suite_name: String, loader: Callable) -> void:
	if _suite_filter.is_empty() or suite_name in _suite_filter:
		_run_suite(loader.call())


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
