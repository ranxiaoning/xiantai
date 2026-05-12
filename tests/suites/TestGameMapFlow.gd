## TestGameMapFlow.gd
## 白盒测试：地图流程状态，避免战斗后回地图重复播放重天标题。
extends RefCounted

const BattleEngineScript = preload("res://scripts/BattleEngine.gd")
const GameMapScene := preload("res://scenes/GameMap.tscn")

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _cur: String = ""


func run_all() -> Dictionary:
	_lines.append("\n[ TestGameMapFlow ]")

	_t("test_map_intro_flag_resets_only_on_new_run")
	_t("test_battle_win_heals_current_hp_once")
	_t("test_non_battle_node_heals_current_hp_once")
	_t("test_battle_starts_from_persistent_current_hp")
	_t("test_shop_node_requests_shop_scene_transition")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_map_intro_flag_resets_only_on_new_run() -> void:
	GameState.start_run("chen_tian_feng")
	_assert_eq(GameState.map_intro_played, false, "新局开始：重天标题允许播放一次")

	GameState.map_intro_played = true
	GameState.start_map()
	_assert_eq(GameState.map_intro_played, true, "同一 run 进入地图后：重天标题状态保持已播放")

	var first_floor: Array = GameState.map_floors[0]
	GameState.visit_map_node(first_floor[0])
	GameState.on_battle_won()
	_assert_eq(GameState.map_intro_played, true, "战斗胜利回地图：不重置重天标题播放状态")

	GameState.start_run("chen_tian_feng")
	_assert_eq(GameState.map_intro_played, false, "下一局开始：重天标题状态重新允许播放")


func test_battle_win_heals_current_hp_once() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.current_hp = 42
	GameState.on_battle_won()
	_assert_eq(GameState.current_hp, 47, "战斗胜利：保留战斗后生命并回复生命回复值")


func test_non_battle_node_heals_current_hp_once() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.current_hp = 40
	var node_id := _first_non_battle_node_id()
	if node_id.is_empty():
		_fail("没有找到非战斗节点")
		return
	GameState.visit_map_node(node_id)
	_assert_eq(GameState.current_hp, 45, "非战斗节点：经过节点后回复生命回复值")


func test_battle_starts_from_persistent_current_hp() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.current_hp = 37
	var engine: Object = BattleEngineScript.new()
	engine.call("init", GameState.character, GameState.deck, {"name": "测试敌人", "hp": 30})
	_assert_eq(engine.get("s")["player_hp"], 37, "战斗开始：使用地图维护的当前生命值")


func test_shop_node_requests_shop_scene_transition() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.map_intro_played = true
	GameState.map_started = true
	GameState.map_nodes = {
		"shop_probe": {
			"id": "shop_probe",
			"type": "shop",
			"floor": 1,
			"col": 0,
			"total_cols": 1,
			"next_ids": [],
			"visited": false,
		},
	}
	GameState.map_floors = [["shop_probe"]]
	GameState.map_accessible_ids = ["shop_probe"]
	GameState.map_current_floor = 0
	GameState.map_last_node_id = ""

	var tree := Engine.get_main_loop() as SceneTree
	var scene: Control = GameMapScene.instantiate()
	tree.root.add_child(scene)
	scene.call("_on_node_btn_pressed", "shop_probe")
	_assert_eq(GameState.pending_battle_node_type, "shop", "黑市节点点击：记录待处理节点类型为 shop")
	_assert_eq(GameState.pending_battle_node_floor, 1, "黑市节点点击：记录待处理节点层数")
	_assert_eq(scene.get("_scene_transition_pending"), true, "黑市节点点击：请求切换到 Shop.tscn")
	scene.free()


func _first_non_battle_node_id() -> String:
	for node_id in GameState.map_nodes:
		var node: Dictionary = GameState.map_nodes[node_id]
		if not ["normal", "elite", "boss"].has(str(node.get("type", ""))):
			return node_id
	return ""


func _t(method: String) -> void:
	_cur = method
	call(method)


func _assert_eq(a, b, label: String) -> void:
	if a == b:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 期望 %s，实际 %s" % [label, str(b), str(a)])


func _fail(label: String) -> void:
	_fail_count += 1
	_lines.append("  ✗ %s" % label)
