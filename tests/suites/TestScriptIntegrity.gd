## TestScriptIntegrity.gd
## 白盒测试：验证所有 GDScript 文件能被 Godot 正确解析加载。
## 输出策略：成功只打印汇总行，失败逐条展开——保持输出精简。
## 每新增一个 .gd 文件，都必须在此注册。
extends RefCounted

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
	"res://scripts/CardRenderer.gd",
	"res://scripts/CardZoomOverlay.gd",
	"res://scripts/CharacterSelect.gd",
	"res://scripts/GameMap.gd",
	"res://scripts/BattleScene.gd",
	"res://scripts/MapGenerator.gd",
	"res://scripts/MapDrawLayer.gd",
	"res://scripts/RewardScreen.gd",
]

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
	"res://tests/suites/TestCharacterSelect.gd",
	"res://tests/suites/TestBattleEngineLogic.gd",
	"res://tests/suites/TestMapGenerator.gd",
]

const SCENES: Array[String] = [
	"res://scenes/MainMenu.tscn",
	"res://scenes/OptionsMenu.tscn",
	"res://scenes/CharacterSelect.tscn",
	"res://scenes/GameMap.tscn",
	"res://scenes/Battle.tscn",
	"res://scenes/RewardScreen.tscn",
]

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestScriptIntegrity ]")

	_check_scripts_group("游戏脚本", GAME_SCRIPTS)
	_check_scripts_group("测试脚本", TEST_SCRIPTS)
	_check_autoloads()
	_check_scene_script_refs()

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ── 分组检查：仅打印失败，成功只汇总 ─────────────────────────────

func _check_scripts_group(label: String, paths: Array[String]) -> void:
	var ok := 0
	var fail_lines: Array[String] = []
	for path in paths:
		if not FileAccess.file_exists(path):
			fail_lines.append("    ✗ %s  ← 文件不存在" % path.get_file())
			_fail_count += 1
		elif load(path) == null:
			fail_lines.append("    ✗ %s  ← load() 返回 null（解析失败）" % path.get_file())
			_fail_count += 1
		else:
			ok += 1
			_pass_count += 1
	if fail_lines.is_empty():
		_lines.append("  ✓ %s：%d 个全部解析通过" % [label, ok])
	else:
		_lines.append("  ✗ %s：%d 通过  %d 失败" % [label, ok, fail_lines.size()])
		_lines.append_array(fail_lines)


func _check_autoloads() -> void:
	const PROJECT_PATH := "res://project.godot"
	if not FileAccess.file_exists(PROJECT_PATH):
		_lines.append("  ✗ Autoload 检查  ← project.godot 不存在")
		_fail_count += 1
		return
	var src := FileAccess.get_file_as_string(PROJECT_PATH)
	var ok := 0
	var fail_lines: Array[String] = []
	for entry in REQUIRED_AUTOLOADS:
		var name: String = entry[0]
		var path: String = entry[1]
		if src.contains('%s="*%s"' % [name, path]):
			ok += 1
			_pass_count += 1
		else:
			fail_lines.append("    ✗ Autoload %s  ← 未在 project.godot 注册" % name)
			_fail_count += 1
	if fail_lines.is_empty():
		_lines.append("  ✓ Autoload：%d 个全部已注册" % ok)
	else:
		_lines.append("  ✗ Autoload：%d 已注册  %d 缺失" % [ok, fail_lines.size()])
		_lines.append_array(fail_lines)


func _check_scene_script_refs() -> void:
	var regex := RegEx.new()
	regex.compile('path="(res://[^"]+\\.gd)"')
	var ok := 0
	var fail_lines: Array[String] = []
	for scene_path in SCENES:
		if not FileAccess.file_exists(scene_path):
			fail_lines.append("    ✗ %s  ← 场景文件不存在" % scene_path.get_file())
			_fail_count += 1
			continue
		var content := FileAccess.get_file_as_string(scene_path)
		for result in regex.search_all(content):
			var script_path := result.get_string(1)
			if not FileAccess.file_exists(script_path):
				fail_lines.append("    ✗ %s → %s  ← 脚本不存在" % [scene_path.get_file(), script_path.get_file()])
				_fail_count += 1
			else:
				ok += 1
				_pass_count += 1
	if fail_lines.is_empty():
		_lines.append("  ✓ 场景脚本引用：%d 条全部有效" % ok)
	else:
		_lines.append("  ✗ 场景脚本引用：%d 有效  %d 失效" % [ok, fail_lines.size()])
		_lines.append_array(fail_lines)
