## TestScriptIntegrity.gd
## 白盒测试：验证所有 GDScript 文件能被 Godot 正确解析加载。
## 这类测试能在运行前捕获：解析错误、类型推断失败、缺失依赖等问题。
## 每新增一个 .gd 文件，都必须在此注册。
extends RefCounted

# ── 待验证脚本列表（新增脚本后在此追加）──────────────────
const GAME_SCRIPTS: Array[String] = [
	"res://scripts/Logger.gd",
	"res://scripts/Log.gd",
	"res://scripts/GlobalSettings.gd",
	"res://scripts/MainMenu.gd",
	"res://scripts/OptionsMenu.gd",
	"res://scripts/data/CardDatabase.gd",
	"res://scripts/data/CharacterDatabase.gd",
	"res://scripts/data/EnemyDatabase.gd",
	"res://scripts/GameState.gd",
	"res://scripts/MusicManager.gd",
	"res://scripts/BattleEngine.gd",
	"res://scripts/CharacterSelect.gd",
	"res://scripts/GameMap.gd",
	"res://scripts/BattleScene.gd",
]

# 必须在 project.godot [autoload] 中注册的脚本 → [autoload名, 脚本路径]
# Autoload 是让脚本全局可用的可靠方式，不依赖编辑器 class cache 扫描
const REQUIRED_AUTOLOADS: Array = [
	["Logger", "res://scripts/Logger.gd"],
	["Log",    "res://scripts/Log.gd"],
	["GlobalSettings", "res://scripts/GlobalSettings.gd"],
	["CardDatabase", "res://scripts/data/CardDatabase.gd"],
	["CharacterDatabase", "res://scripts/data/CharacterDatabase.gd"],
	["EnemyDatabase", "res://scripts/data/EnemyDatabase.gd"],
	["GameState", "res://scripts/GameState.gd"],
	["MusicManager", "res://scripts/MusicManager.gd"],
]

const TEST_SCRIPTS: Array[String] = [
	"res://tests/TestMain.gd",
	"res://tests/suites/TestGlobalSettings.gd",
	"res://tests/suites/TestLogger.gd",
	"res://tests/suites/TestScriptIntegrity.gd",
]

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestScriptIntegrity ]")

	_lines.append("  # 游戏脚本解析验证")
	for path in GAME_SCRIPTS:
		_check_script(path)

	_lines.append("  # 测试脚本自身解析验证")
	for path in TEST_SCRIPTS:
		_check_script(path)

	_lines.append("  # Autoload 注册验证")
	_check_autoloads()

	_lines.append("  # 场景脚本引用验证")
	_check_scene_script_refs()

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ── 核心检查 ──────────────────────────────────────

func _check_script(path: String) -> void:
	var label := path.get_file()
	if not FileAccess.file_exists(path):
		_fail(label, "文件不存在: " + path)
		return
	var script = load(path)
	if script == null:
		_fail(label, "load() 返回 null（解析失败）")
	else:
		_ok(label + " 解析通过")


func _check_autoloads() -> void:
	# 读取 project.godot，验证必要的 Autoload 都已注册
	# Autoload 是让脚本全局可见的可靠方式（不依赖编辑器 class cache）
	# 曾因 Log 未注册为 Autoload 且 class_name 缓存未更新，导致游戏运行时找不到 Log
	const PROJECT_PATH := "res://project.godot"
	if not FileAccess.file_exists(PROJECT_PATH):
		_fail("project.godot", "文件不存在")
		return
	var src := FileAccess.get_file_as_string(PROJECT_PATH)
	for entry in REQUIRED_AUTOLOADS:
		var name: String = entry[0]
		var path: String = entry[1]
		var expected := '%s="*%s"' % [name, path]
		if src.contains(expected):
			_ok("Autoload " + name + " 已注册")
		else:
			_fail("Autoload " + name, "未在 project.godot 中注册（全局不可用）")


func _check_scene_script_refs() -> void:
	# 检查 .tscn 文件中引用的脚本路径是否存在
	var scenes: Array[String] = [
		"res://scenes/MainMenu.tscn",
		"res://scenes/OptionsMenu.tscn",
		"res://scenes/CharacterSelect.tscn",
		"res://scenes/GameMap.tscn",
		"res://scenes/Battle.tscn",
	]
	for scene_path in scenes:
		if not FileAccess.file_exists(scene_path):
			_fail(scene_path.get_file(), "场景文件不存在")
			continue
		var content := FileAccess.get_file_as_string(scene_path)
		# 提取所有 path="res://scripts/..." 引用
		var regex := RegEx.new()
		regex.compile('path="(res://[^"]+\\.gd)"')
		for result in regex.search_all(content):
			var script_path := result.get_string(1)
			if not FileAccess.file_exists(script_path):
				_fail(scene_path.get_file(), "引用了不存在的脚本: " + script_path)
			else:
				_ok(scene_path.get_file() + " → " + script_path.get_file() + " 引用有效")


# ── 断言工具 ──────────────────────────────────────

func _ok(label: String) -> void:
	_pass_count += 1
	_lines.append("  ✓ %s" % label)

func _fail(label: String, reason: String) -> void:
	_fail_count += 1
	_lines.append("  ✗ %s  ← %s" % [label, reason])
