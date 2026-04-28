## MapGenerator.gd
## 16层战斗地图生成器（纯逻辑，无场景依赖）
class_name MapGenerator

const FLOOR_COUNT := 16
const MIN_COLS := 3
const MAX_COLS := 4

## 强制层配置
const FORCED_FLOOR_1_TYPE  := "normal"   # 第1层全普通战斗
const FORCED_FLOOR_8_TYPES := ["shop", "bonfire", "event"]  # 第8层可选类型
const FORCED_FLOOR_15_TYPE := "bonfire"  # 第15层全篝火
const FORCED_FLOOR_16_TYPE := "boss"     # 第16层固定Boss

## 各层可用节点类型权重（第1/8/15/16层单独处理）
const TYPE_WEIGHTS_EARLY := {"normal": 80, "bonfire": 10, "shop": 10}       # 第2-3层（无精英）
const TYPE_WEIGHTS_MID   := {"normal": 55, "elite": 20, "bonfire": 10, "shop": 8, "event": 7}  # 第4-7层
const TYPE_WEIGHTS_LATE  := {"normal": 50, "elite": 25, "bonfire": 10, "shop": 8, "event": 7}  # 第9-14层


static func generate() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return _generate_with_rng(rng)


static func _generate_with_rng(rng: RandomNumberGenerator) -> Dictionary:
	var floors: Array = []   # floors[i] = [node_id, ...]
	var nodes: Dictionary = {}  # node_id -> node_dict

	# 1. 确定每层列数
	var floor_cols: Array = []
	for f in range(1, FLOOR_COUNT + 1):
		if f == 16:
			floor_cols.append(1)  # Boss层固定1列
		else:
			floor_cols.append(rng.randi_range(MIN_COLS, MAX_COLS))

	# 2. 生成节点
	for f in range(1, FLOOR_COUNT + 1):
		var col_count: int = floor_cols[f - 1]
		var floor_node_ids: Array = []
		for c in range(col_count):
			var nid := "n%d_%d" % [f, c]
			var ntype := _pick_type(f, c, col_count, rng)
			nodes[nid] = {
				"id": nid,
				"floor": f,
				"col": c,
				"total_cols": col_count,
				"type": ntype,
				"next_ids": [],
				"visited": false,
			}
			floor_node_ids.append(nid)
		floors.append(floor_node_ids)

	# 3. 生成连线（保证连通性）
	for f in range(0, FLOOR_COUNT - 1):
		var cur_floor: Array = floors[f]
		var nxt_floor: Array = floors[f + 1]
		var cur_count := cur_floor.size()
		var nxt_count := nxt_floor.size()

		# 先确保每个下层节点都有至少1条入边（先分配）
		var has_parent: Dictionary = {}
		for nid in nxt_floor:
			has_parent[nid] = false

		# 为当前层每个节点随机连1~2条出边
		var assigned: Array = []  # (src_idx, dst_idx) pairs for constraint checks
		for ci in range(cur_count):
			var src_id: String = cur_floor[ci]
			# 目标范围：映射到下层的对应区域
			var t_start := int(float(ci) / float(cur_count) * float(nxt_count))
			var t_end   := int(float(ci + 1) / float(cur_count) * float(nxt_count))
			t_end = clampi(t_end, t_start + 1, nxt_count)  # 至少1个
			t_start = clampi(t_start, 0, nxt_count - 1)

			var primary_target := rng.randi_range(t_start, t_end - 1)
			_add_edge(nodes, src_id, nxt_floor[primary_target])
			has_parent[nxt_floor[primary_target]] = true
			assigned.append([ci, primary_target])

			# 50%概率增加第二条边（不与现有重复）
			if rng.randf() < 0.5:
				var candidates: Array = []
				for ti in range(t_start, t_end):
					if ti != primary_target:
						candidates.append(ti)
				if not candidates.is_empty():
					var extra_target: int = candidates[rng.randi_range(0, candidates.size() - 1)]
					_add_edge(nodes, src_id, nxt_floor[extra_target])
					has_parent[nxt_floor[extra_target]] = true

		# 修补孤立节点：没有入边的下层节点，从最近的上层节点连一条
		for ni in range(nxt_count):
			var nid: String = nxt_floor[ni]
			if not has_parent[nid]:
				# 找最近的上层节点（按列索引距离）
				var best_ci := 0
				var best_dist := 9999
				for ci in range(cur_count):
					var dist := absi(ci - ni)
					if dist < best_dist:
						best_dist = dist
						best_ci = ci
				_add_edge(nodes, cur_floor[best_ci], nid)

	# 4. 路径约束检查：消除连续精英/篝火商店（简化：只调整节点类型）
	_apply_path_constraints(nodes, floors, rng)

	return {"nodes": nodes, "floors": floors}


static func _add_edge(nodes: Dictionary, src_id: String, dst_id: String) -> void:
	var src_node: Dictionary = nodes[src_id]
	var next_ids: Array = src_node["next_ids"]
	if not next_ids.has(dst_id):
		next_ids.append(dst_id)


static func _pick_type(floor: int, col: int, total_cols: int, rng: RandomNumberGenerator) -> String:
	# 强制层
	if floor == 1:
		return FORCED_FLOOR_1_TYPE
	if floor == 8:
		return FORCED_FLOOR_8_TYPES[rng.randi_range(0, FORCED_FLOOR_8_TYPES.size() - 1)]
	if floor == 15:
		return FORCED_FLOOR_15_TYPE
	if floor == 16:
		return FORCED_FLOOR_16_TYPE

	# 按层段选权重表
	var weights: Dictionary
	if floor <= 3:
		weights = TYPE_WEIGHTS_EARLY
	elif floor <= 7:
		weights = TYPE_WEIGHTS_MID
	else:
		weights = TYPE_WEIGHTS_LATE

	return _weighted_pick(weights, rng)


static func _weighted_pick(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0
	for k in weights:
		total += int(weights[k])
	var roll := rng.randi_range(0, total - 1)
	var acc := 0
	for k in weights:
		acc += int(weights[k])
		if roll < acc:
			return k
	return weights.keys()[0]


## 路径约束：沿每条路径检查，修正连续精英 / 连续篝火或商店
static func _apply_path_constraints(nodes: Dictionary, floors: Array, rng: RandomNumberGenerator) -> void:
	# 从每个floor1节点出发DFS，记录路径，遇到违规则替换类型
	for start_id in floors[0]:
		_dfs_fix(nodes, start_id, "", rng)


static func _dfs_fix(nodes: Dictionary, node_id: String, parent_type: String, rng: RandomNumberGenerator) -> void:
	var nd: Dictionary = nodes[node_id]
	var cur_type: String = nd["type"]
	var floor: int = int(nd["floor"])

	# 不修改强制层
	if floor == 1 or floor == 8 or floor == 15 or floor == 16:
		pass
	else:
		# 连续精英检查
		if cur_type == "elite" and parent_type == "elite":
			cur_type = _fallback_type(floor, rng)
			nd["type"] = cur_type

		# 连续篝火/商店检查
		var rest_types := ["bonfire", "shop"]
		if rest_types.has(cur_type) and rest_types.has(parent_type):
			cur_type = _fallback_type_no_rest(floor, rng)
			nd["type"] = cur_type

	for next_id in nd["next_ids"]:
		_dfs_fix(nodes, next_id, cur_type, rng)


static func _fallback_type(floor: int, rng: RandomNumberGenerator) -> String:
	if floor <= 3:
		return "normal"
	var picks := ["normal", "event"]
	return picks[rng.randi_range(0, picks.size() - 1)]


static func _fallback_type_no_rest(floor: int, rng: RandomNumberGenerator) -> String:
	if floor <= 3:
		return "normal"
	var picks := ["normal", "elite", "event"]
	# 第1-3层无精英
	if floor <= 3:
		picks = ["normal", "event"]
	return picks[rng.randi_range(0, picks.size() - 1)]
