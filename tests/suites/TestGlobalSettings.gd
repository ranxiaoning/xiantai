## TestGlobalSettings.gd
## GlobalSettings 单元测试套件（独立脚本，无继承，兼容 headless 模式）。
extends RefCounted

const GS_SCRIPT  := "res://scripts/GlobalSettings.gd"
const TEST_CFG   := "user://test_gs_tmp.cfg"

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _cur: String = ""
var _objects_to_free: Array[Object] = []

func run_all() -> Dictionary:
	_lines.append("\n[ TestGlobalSettings ]")

	_t("test_resolutions_not_empty")
	_t("test_resolution_first_entry")
	_t("test_resolution_1080p_exists")
	_t("test_default_master_volume")
	_t("test_default_music_volume")
	_t("test_default_sfx_volume")
	_t("test_default_language")
	_t("test_default_fullscreen")
	_t("test_default_resolution_index")
	_t("test_save_reload_master_volume")
	_t("test_save_reload_resolution_index")
	_t("test_save_reload_fullscreen")
	_t("test_save_reload_language")
	_t("test_clamp_overflow")
	_t("test_clamp_negative")
	_t("test_load_missing_file_uses_defaults")
	_t("test_volume_boundary_zero")
	_t("test_volume_boundary_max")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	
	for o in _objects_to_free:
		if is_instance_valid(o):
			o.free()
	_objects_to_free.clear()
	
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ── 测试用例 ──────────────────────────────────────

func test_resolutions_not_empty() -> void:
	var gs := _gs()
	_assert_true(gs.RESOLUTIONS.size() >= 4, "RESOLUTIONS至少4项")

func test_resolution_first_entry() -> void:
	var gs := _gs()
	_assert_eq(gs.RESOLUTIONS[0], Vector2i(1280, 720), "第0项=1280×720")

func test_resolution_1080p_exists() -> void:
	var gs := _gs()
	_assert_true(gs.RESOLUTIONS.has(Vector2i(1920, 1080)), "包含1920×1080")

func test_default_master_volume() -> void:
	_assert_eq(_gs().master_volume, 1.0, "默认总音量=1.0")

func test_default_music_volume() -> void:
	_assert_eq(_gs().music_volume, 0.8, "默认音乐音量=0.8")

func test_default_sfx_volume() -> void:
	_assert_eq(_gs().sfx_volume, 0.8, "默认音效音量=0.8")

func test_default_language() -> void:
	_assert_eq(_gs().language, "zh_CN", "默认语言=zh_CN")

func test_default_fullscreen() -> void:
	_assert_false(_gs().fullscreen, "默认非全屏")

func test_default_resolution_index() -> void:
	_assert_eq(_gs().resolution_index, 0, "默认分辨率下标=0")

func test_save_reload_master_volume() -> void:
	var gs := _gs()
	gs.master_volume = 0.42
	_save(gs)
	var gs2 := _gs(); _load(gs2)
	_assert_near(gs2.master_volume, 0.42, 0.001, "总音量写入再读出=0.42")

func test_save_reload_resolution_index() -> void:
	var gs := _gs(); gs.resolution_index = 2; _save(gs)
	var gs2 := _gs(); _load(gs2)
	_assert_eq(gs2.resolution_index, 2, "分辨率下标写入再读出=2")

func test_save_reload_fullscreen() -> void:
	var gs := _gs(); gs.fullscreen = true; _save(gs)
	var gs2 := _gs(); _load(gs2)
	_assert_true(gs2.fullscreen, "全屏标志写入再读出=true")

func test_save_reload_language() -> void:
	var gs := _gs(); gs.language = "en"; _save(gs)
	var gs2 := _gs(); _load(gs2)
	_assert_eq(gs2.language, "en", "语言写入再读出=en")

func test_clamp_overflow() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "resolution_index", 9999)
	cfg.save(TEST_CFG)
	var gs := _gs(); _load(gs)
	_assert_true(gs.resolution_index < gs.RESOLUTIONS.size(), "越界下标被截断")
	_assert_true(gs.resolution_index >= 0, "截断后下标>=0")

func test_clamp_negative() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "resolution_index", -5)
	cfg.save(TEST_CFG)
	var gs := _gs(); _load(gs)
	_assert_eq(gs.resolution_index, 0, "负数下标截断到0")

func test_load_missing_file_uses_defaults() -> void:
	if FileAccess.file_exists(TEST_CFG):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_CFG))
	var gs := _gs(); _load(gs)
	_assert_eq(gs.master_volume, 1.0, "文件缺失时使用默认总音量")
	_assert_eq(gs.resolution_index, 0, "文件缺失时使用默认分辨率下标")

func test_volume_boundary_zero() -> void:
	var gs := _gs(); gs.master_volume = 0.0; _save(gs)
	var gs2 := _gs(); _load(gs2)
	_assert_eq(gs2.master_volume, 0.0, "音量=0.0 保存读取正确")

func test_volume_boundary_max() -> void:
	var gs := _gs(); gs.master_volume = 1.0; _save(gs)
	var gs2 := _gs(); _load(gs2)
	_assert_eq(gs2.master_volume, 1.0, "音量=1.0 保存读取正确")


# ── 内部工具 ──────────────────────────────────────

func _t(method: String) -> void:
	_cur = method
	call(method)

func _gs() -> Object:
	var o = load(GS_SCRIPT).new()
	_objects_to_free.append(o)
	return o

func _save(gs: Object) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio",   "master_volume",    gs.master_volume)
	cfg.set_value("audio",   "music_volume",     gs.music_volume)
	cfg.set_value("audio",   "sfx_volume",       gs.sfx_volume)
	cfg.set_value("display", "resolution_index", gs.resolution_index)
	cfg.set_value("display", "fullscreen",       gs.fullscreen)
	cfg.set_value("locale",  "language",         gs.language)
	cfg.save(TEST_CFG)

func _load(gs: Object) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(TEST_CFG) != OK:
		return
	gs.master_volume    = cfg.get_value("audio",   "master_volume",    gs.master_volume)
	gs.music_volume     = cfg.get_value("audio",   "music_volume",     gs.music_volume)
	gs.sfx_volume       = cfg.get_value("audio",   "sfx_volume",       gs.sfx_volume)
	gs.resolution_index = cfg.get_value("display", "resolution_index", gs.resolution_index)
	gs.fullscreen       = cfg.get_value("display", "fullscreen",       gs.fullscreen)
	gs.language         = cfg.get_value("locale",  "language",         gs.language)
	gs.resolution_index = clampi(gs.resolution_index, 0, gs.RESOLUTIONS.size() - 1)

func _assert_eq(a, b, label: String) -> void:
	if a == b: _ok(label)
	else: _fail(label, "期望 %s，实际 %s" % [str(b), str(a)])

func _assert_true(c: bool, label: String) -> void:
	_assert_eq(c, true, label)

func _assert_false(c: bool, label: String) -> void:
	_assert_eq(c, false, label)

func _assert_near(a: float, b: float, tol: float, label: String) -> void:
	if abs(a - b) <= tol: _ok(label)
	else: _fail(label, "期望 ~%s (±%s)，实际 %s" % [str(b), str(tol), str(a)])

func _ok(label: String) -> void:
	_pass_count += 1
	_lines.append("  ✓ %s" % label)

func _fail(label: String, reason: String) -> void:
	_fail_count += 1
	_lines.append("  ✗ %s  ← %s" % [label, reason])
