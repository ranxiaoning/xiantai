## TestMapGenerator.gd
## 验证 MapGenerator 生成地图的结构正确性
extends RefCounted

const MapGeneratorScript = preload("res://scripts/MapGenerator.gd")

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _cur: String = ""

var _map_data: Dictionary = {}


func run_all() -> Dictionary:
	_lines.append("\n[ TestMapGenerator ]")

	# 生成一次地图，所有测试共用
	_map_data = MapGeneratorScript.generate()

	_t("test_floor_count")
	_t("test_floor1_all_normal")
	_t("test_floor15_all_bonfire")
	_t("test_floor16_all_boss")
	_t("test_floor16_single_node")
	_t("test_no_orphan_nodes")
	_t("test_connectivity")
	_t("test_no_consecutive_elite")
	_t("test_no_consecutive_rest")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ── 测试用例 ──────────────────────────────────────────────────────

func test_floor_count() -> void:
	var floors: Array = _map_data["floors"]
	_assert_eq(floors.size(), 16, "地图应有16层 floors")


func test_floor1_all_normal() -> void:
	var floors: Array  = _map_data["floors"]
	var nodes: Dictionary = _map_data["nodes"]
	if floors.is_empty():
		_fail("floors 为空")
		return
	var floor1: Array = floors[0]
	var all_ok := true
	for nid in floor1:
		var nd: Dictionary = nodes[nid]
		if nd["type"] != "normal":
			all_ok = false
			break
	_assert_true(all_ok, "第1层所有节点类型应为 normal")


func test_floor15_all_bonfire() -> void:
	var floors: Array  = _map_data["floors"]
	var nodes: Dictionary = _map_data["nodes"]
	if floors.size() < 15:
		_fail("floors 层数不足15")
		return
	var floor15: Array = floors[14]  # index 14 = floor 15
	var all_ok := true
	for nid in floor15:
		var nd: Dictionary = nodes[nid]
		if nd["type"] != "bonfire":
			all_ok = false
			break
	_assert_true(all_ok, "第15层所有节点类型应为 bonfire")


func test_floor16_all_boss() -> void:
	var floors: Array  = _map_data["floors"]
	var nodes: Dictionary = _map_data["nodes"]
	if floors.size() < 16:
		_fail("floors 层数不足16")
		return
	var floor16: Array = floors[15]  # index 15 = floor 16
	var all_ok := true
	for nid in floor16:
		var nd: Dictionary = nodes[nid]
		if nd["type"] != "boss":
			all_ok = false
			break
	_assert_true(all_ok, "第16层所有节点类型应为 boss")


func test_floor16_single_node() -> void:
	var floors: Array = _map_data["floors"]
	if floors.size() < 16:
		_fail("floors 层数不足16")
		return
	var floor16: Array = floors[15]
	_assert_eq(floor16.size(), 1, "第16层（Boss层）应只有1个节点")


func test_no_orphan_nodes() -> void:
	## 除第1层外，每层每个节点都应至少有1条入边
	var floors: Array  = _map_data["floors"]
	var nodes: Dictionary = _map_data["nodes"]
	if floors.size() < 2:
		_fail("floors 层数不足2")
		return

	# 统计每个节点的入边数
	var in_degree: Dictionary = {}
	for node_id in nodes:
		in_degree[node_id] = 0

	for node_id in nodes:
		var nd: Dictionary = nodes[node_id]
		for next_id in nd["next_ids"]:
			if in_degree.has(next_id):
				in_degree[next_id] += 1

	# 验证第2层及以上没有孤立节点
	var found_orphan := false
	var orphan_id := ""
	for fi in range(1, floors.size()):  # 从index 1（floor 2）开始
		for nid in floors[fi]:
			if int(in_degree.get(nid, 0)) == 0:
				found_orphan = true
				orphan_id = nid
				break
		if found_orphan:
			break

	_assert_true(not found_orphan, "第2层及以上不应有孤立节点（孤立: %s）" % orphan_id)


func test_connectivity() -> void:
	## 每个floor1节点至少有1条出边（可到达下一层）
	var floors: Array  = _map_data["floors"]
	var nodes: Dictionary = _map_data["nodes"]
	if floors.is_empty():
		_fail("floors 为空")
		return
	var floor1: Array = floors[0]
	var all_connected := true
	var bad_id := ""
	for nid in floor1:
		var nd: Dictionary = nodes[nid]
		if nd["next_ids"].is_empty():
			all_connected = false
			bad_id = nid
			break
	_assert_true(all_connected, "第1层每个节点应有出边（无出边: %s）" % bad_id)


func test_no_consecutive_elite() -> void:
	## 同一路径上不应出现连续精英
	var nodes: Dictionary = _map_data["nodes"]
	var floors: Array     = _map_data["floors"]
	if floors.is_empty():
		_fail("floors 为空")
		return

	var found_violation := false
	var violation_path := ""
	for start_id in floors[0]:
		if _dfs_check_consecutive(nodes, start_id, "", "elite"):
			found_violation = true
			violation_path = start_id
			break

	_assert_true(not found_violation, "路径上不应出现连续精英（起自: %s）" % violation_path)


func test_no_consecutive_rest() -> void:
	## 同一路径上不应出现连续篝火或商店
	var nodes: Dictionary = _map_data["nodes"]
	var floors: Array     = _map_data["floors"]
	if floors.is_empty():
		_fail("floors 为空")
		return

	var found_violation := false
	var violation_path := ""
	for start_id in floors[0]:
		if _dfs_check_consecutive_rest(nodes, start_id, ""):
			found_violation = true
			violation_path = start_id
			break

	_assert_true(not found_violation, "路径上不应出现连续篝火/商店（起自: %s）" % violation_path)


# ── DFS 辅助 ─────────────────────────────────────────────────────

func _dfs_check_consecutive(nodes: Dictionary, node_id: String, parent_type: String, bad_type: String) -> bool:
	var nd: Dictionary = nodes[node_id]
	var cur_type: String = nd["type"]
	var floor: int = int(nd["floor"])

	# 跳过强制层（第8/15层的篝火不算违规）
	if floor != 8 and floor != 15 and floor != 16:
		if cur_type == bad_type and parent_type == bad_type:
			return true

	for next_id in nd["next_ids"]:
		if nodes.has(next_id):
			if _dfs_check_consecutive(nodes, next_id, cur_type, bad_type):
				return true
	return false


func _dfs_check_consecutive_rest(nodes: Dictionary, node_id: String, parent_type: String) -> bool:
	var nd: Dictionary = nodes[node_id]
	var cur_type: String = nd["type"]
	var floor: int = int(nd["floor"])
	var rest_types := ["bonfire", "shop"]

	if floor != 8 and floor != 15 and floor != 16:
		if rest_types.has(cur_type) and rest_types.has(parent_type):
			return true

	for next_id in nd["next_ids"]:
		if nodes.has(next_id):
			if _dfs_check_consecutive_rest(nodes, next_id, cur_type):
				return true
	return false


# ── 测试框架工具 ─────────────────────────────────────────────────

func _t(method: String) -> void:
	_cur = method
	call(method)


func _assert_true(condition: bool, msg: String) -> void:
	if condition:
		_pass_count += 1
		_lines.append("  ✓ %s" % _cur)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← %s" % [_cur, msg])


func _assert_eq(a, b, msg: String) -> void:
	if a == b:
		_pass_count += 1
		_lines.append("  ✓ %s" % _cur)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← %s（期望=%s 实际=%s）" % [_cur, msg, str(b), str(a)])


func _fail(msg: String) -> void:
	_fail_count += 1
	_lines.append("  ✗ %s  ← %s" % [_cur, msg])
