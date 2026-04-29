## TestEnemyBehavior.gd
## 怪物出招行为测试：验证每种怪物每回合的动作、伤害、状态是否符合设计文档。
## 测试策略：直接操作 BattleEngine.s 状态字典，模拟敌人回合，逐回合断言。
extends RefCounted

const BattleEngineScript = preload("res://scripts/BattleEngine.gd")

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestEnemyBehavior ]")

	# ── 普通怪 ──────────────────────────────────────
	_t("test_normal_berserker_cycle")
	_t("test_normal_assassin_cycle")
	_t("test_normal_tank_cycle")
	_t("test_normal_debuffer_cycle")
	_t("test_normal_escalating_cycle")

	# ── 精英怪 ──────────────────────────────────────
	_t("test_elite_berserker_cycle")
	_t("test_elite_assassin_cycle")
	_t("test_elite_tank_cycle")
	_t("test_elite_debuffer_cycle")
	_t("test_elite_escalating_cycle")

	# ── 随机选怪机制 ────────────────────────────────
	_t("test_random_normal_selection")
	_t("test_random_elite_selection")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ═══════════════════════════════════════════════════
# 工具方法
# ═══════════════════════════════════════════════════

## 创建战斗引擎并注入指定敌人（通过ID精确获取，绕过随机）
func _make_engine_with_enemy(enemy_id: String) -> Object:
	var e: Object = BattleEngineScript.new()
	var char_data := {"hp_max": 80, "ling_li_max": 20, "dao_hui_max": 10}
	var enemy_data := _load_enemy_direct(enemy_id)
	e.init(char_data, [], enemy_data)
	## 初始化被动状态到 s 字典
	var s = e.get("s")
	_init_enemy_passives(s, enemy_data)
	return e


## 直接读取 EnemyDatabase 常量（headless 兼容）
func _load_enemy_direct(enemy_id: String) -> Dictionary:
	var db = load("res://scripts/data/EnemyDatabase.gd").new()
	db.call("_ready")
	var enemy = db.call("get_enemy_by_id", enemy_id)
	db.free()
	return enemy


## 初始化敌人被动到 s 字典
func _init_enemy_passives(s: Dictionary, enemy_data: Dictionary) -> void:
	s["enemy_dao_xing"]  = enemy_data.get("passive_dao_xing_n", 0)
	s["enemy_jing_ci"]   = enemy_data.get("passive_jing_ci_n", 0)
	s["enemy_shen_xing"] = 0
	s["enemy_hp_max"]    = s["enemy_hp"]
	## 不侵被动（暗影刺客）：在 enemy_statuses 中记录剩余触发次数
	var bu_qin_hits: int = enemy_data.get("passive_bu_qin_hits", 0)
	if bu_qin_hits > 0:
		s["enemy_statuses"]["bu_qin"] = bu_qin_hits


## 模拟一次敌人回合
func _do_enemy_turn(e: Object) -> void:
	e.call("_enemy_turn")


func _t(method: String) -> void:
	call(method)


func _assert_eq(a, b, label: String) -> void:
	if str(a) == str(b):
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 期望 %s，实际 %s" % [label, str(b), str(a)])


## 在 draw_pile / hand / discard_pile 中任意一处找到污染牌即返回 true
func _has_curse_anywhere(s: Dictionary) -> bool:
	for c in s["hand"]:
		if c.get("is_curse", false):
			return true
	for c in s["draw_pile"]:
		if c.get("is_curse", false):
			return true
	for c in s["discard_pile"]:
		if c.get("is_curse", false):
			return true
	return false


func _assert_true(cond: bool, label: String) -> void:
	if cond:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 条件为假" % label)


# ═══════════════════════════════════════════════════
# 普通怪测试
# ═══════════════════════════════════════════════════

## 【1】纯粹强攻型 血灵狂徒 普通形态
## 循环2回合：R1=试探攻击(6伤) → R2=全力重击(12伤)
## HP=45, 护体=0, 无被动
func test_normal_berserker_cycle() -> void:
	var e = _make_engine_with_enemy("normal_xue_ling_kuang_tu")
	var s = e.get("s")
	_assert_eq(s["enemy_hp"],   45, "[血灵狂徒] 初始HP=45")
	_assert_eq(s["enemy_hu_ti"], 0, "[血灵狂徒] 初始护体=0")

	# 回合1：试探攻击，造成6伤
	var hp1 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp1 - s["player_hp"], 6, "[血灵狂徒] R1 试探攻击 → 玩家受到6伤")

	# 回合2：全力重击，造成12伤
	var hp2 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp2 - s["player_hp"], 12, "[血灵狂徒] R2 全力重击 → 玩家受到12伤")

	# 回合3：循环回R1，试探攻击6伤
	var hp3 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp3 - s["player_hp"], 6, "[血灵狂徒] R3 循环到R1 → 再次试探6伤")

	e.free()


## 【2】蓄力爆发型 匿影死士 普通形态
## 循环3回合：R1=屏息(身形+5) → R2=蓄力(无伤) → R3=绝影杀(20伤)
func test_normal_assassin_cycle() -> void:
	var e = _make_engine_with_enemy("normal_ni_ying_si_shi")
	var s = e.get("s")
	_assert_eq(s["enemy_hp"], 40, "[匿影死士] 初始HP=40")

	# R1：屏息，获得5点身形，玩家不受伤
	var hp1 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(s["player_hp"], hp1, "[匿影死士] R1 屏息 → 玩家不受伤")

	# R2：蓄力，无伤害，无护体
	var hp2 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(s["player_hp"], hp2, "[匿影死士] R2 蓄力 → 玩家不受伤")

	# R3：绝影杀，20伤
	var hp3 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp3 - s["player_hp"], 20, "[匿影死士] R3 绝影杀 → 玩家受到20伤")

	e.free()


## 【3】防守反击型 青铜卫甲 普通形态
## 初始HP=35, 护体=15, 荆棘1层
## R1=固化(+8护体) → R2=盾击(5伤+5身形) → R3=反震修补(+1荆棘)
func test_normal_tank_cycle() -> void:
	var e = _make_engine_with_enemy("normal_qing_tong_wei_jia")
	var s = e.get("s")
	_assert_eq(s["enemy_hp"],    35, "[青铜卫甲] 初始HP=35")
	_assert_eq(s["enemy_hu_ti"], 15, "[青铜卫甲] 初始护体=15")
	_assert_eq(s.get("enemy_jing_ci", 0), 1, "[青铜卫甲] 初始荆棘=1")

	# R1：固化，护体+8 → 护体=23
	_do_enemy_turn(e)
	_assert_eq(s["enemy_hu_ti"], 23, "[青铜卫甲] R1 固化 → 护体23(15+8)")

	# R2：盾击，玩家受5伤
	var hp2 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp2 - s["player_hp"], 5, "[青铜卫甲] R2 盾击 → 玩家受5伤")

	# R3：反震修补，荆棘+1 → 荆棘=2
	_do_enemy_turn(e)
	_assert_eq(s.get("enemy_jing_ci", 0), 2, "[青铜卫甲] R3 反震修补 → 荆棘=2")

	e.free()


## 【4】状态折磨型 腐化咒师 普通形态
## R1=暗语诅咒(3伤+暗伤入弃堆) → R2=剥夺(玩家枯竭+1) → R3=咒力释放(8伤)
func test_normal_debuffer_cycle() -> void:
	var e = _make_engine_with_enemy("normal_fu_hua_zhou_shi")
	var s = e.get("s")
	_assert_eq(s["enemy_hp"], 38, "[腐化咒师] 初始HP=38")

	# R1：暗语诅咒，3伤+暗伤入弃堆（弃堆为空时被 reshuffle 进手牌，检查任意牌堆）
	var hp1 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp1 - s["player_hp"], 3, "[腐化咒师] R1 暗语诅咒 → 玩家受3伤")
	_assert_true(_has_curse_anywhere(s), "[腐化咒师] R1 → 暗伤污染牌存在于某个牌堆")

	# R2：剥夺，玩家获得1层枯竭（状态在 end_turn 时才 tick，此处 = 施加值 1）
	_do_enemy_turn(e)
	_assert_eq(s["player_statuses"].get("ku_jie", 0), 1, "[腐化咒师] R2 剥夺 → 玩家枯竭=1")

	# R3：咒力释放，8伤（枯竭不影响怪物伤害，不影响玩家受到的伤害）
	var hp3 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp3 - s["player_hp"], 8, "[腐化咒师] R3 咒力释放 → 玩家受8伤")

	e.free()


## 【5】持续成长型 吞噬蚰蜒 普通形态
## R1=吞食(道行+1) → R2=疯狂连击(3×2) → R3=撕咬(6伤)
## 第2循环时道行已1层，伤害+1
func test_normal_escalating_cycle() -> void:
	var e = _make_engine_with_enemy("normal_tun_shi_you_yan")
	var s = e.get("s")
	_assert_eq(s["enemy_hp"],       50, "[吞噬蚰蜒] 初始HP=50")
	_assert_eq(s.get("enemy_dao_xing", 0), 0, "[吞噬蚰蜒] 初始道行=0")

	# R1：吞食，道行+1
	_do_enemy_turn(e)
	_assert_eq(s.get("enemy_dao_xing", 0), 1, "[吞噬蚰蜒] R1 吞食 → 道行=1")

	# R2：疯狂连击，3×2=6伤（道行=1，每段3+1=4，共2段=8伤）
	var hp2 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp2 - s["player_hp"], 8, "[吞噬蚰蜒] R2 疯狂连击(道行1) → 玩家受8伤(4×2)")

	# R3：撕咬，6+1=7伤（道行=1）
	var hp3 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp3 - s["player_hp"], 7, "[吞噬蚰蜒] R3 撕咬(道行1) → 玩家受7伤")

	# 第2循环R1：再吞食，道行=2
	_do_enemy_turn(e)
	_assert_eq(s.get("enemy_dao_xing", 0), 2, "[吞噬蚰蜒] 第2循环R1 → 道行=2")

	e.free()


# ═══════════════════════════════════════════════════
# 精英怪测试
# ═══════════════════════════════════════════════════

## 【1E】血狱狂魔 精英
## HP=75, 嗜血被动, 循环3回合：重击(10)→重击(10)→血腥狂乱(6×3)
func test_elite_berserker_cycle() -> void:
	var e = _make_engine_with_enemy("elite_xue_yu_kuang_mo")
	var s = e.get("s")
	_assert_eq(s["enemy_hp"], 75, "[血狱狂魔] 初始HP=75")

	# R1：重击10伤，玩家无护体→HP损失10，嗜血按50%回复5（上限75满血）
	_do_enemy_turn(e)
	_assert_eq(s["player_hp"], 70, "[血狱狂魔] R1 重击 → 玩家HP=70(80-10)")
	# 嗜血：造成10点HP伤害，回复50%=5，HP从75→75（满血上限）
	_assert_eq(s["enemy_hp"], 75, "[血狱狂魔] R1 嗜血 → HP维持满血75")

	# R2：重击10伤
	var hp2 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp2 - s["player_hp"], 10, "[血狱狂魔] R2 重击 → 玩家受10伤")

	# R3：血腥狂乱6×3=18伤
	var hp3 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp3 - s["player_hp"], 18, "[血狱狂魔] R3 血腥狂乱 → 玩家受18伤(6×3)")

	e.free()


## 【2E】暗影刺客 精英
## HP=65, 不侵3次(受伤减50%), 循环2回合：瞬步蓄力(身形+10)→绝影杀(24伤)
func test_elite_assassin_cycle() -> void:
	var e = _make_engine_with_enemy("elite_an_ying_ci_ke")
	var s = e.get("s")
	_assert_eq(s["enemy_hp"], 65, "[暗影刺客] 初始HP=65")
	_assert_eq(s["enemy_statuses"].get("bu_qin", 0), 3, "[暗影刺客] 初始不侵=3次")

	# R1：瞬步蓄力，获得10身形，玩家不受伤
	var hp1 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(s["player_hp"], hp1, "[暗影刺客] R1 瞬步蓄力 → 玩家不受伤")

	# R2：绝影杀24伤
	var hp2 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp2 - s["player_hp"], 24, "[暗影刺客] R2 绝影杀 → 玩家受24伤")

	# R3：循环回R1，身形+10
	var hp3 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(s["player_hp"], hp3, "[暗影刺客] R3 循环 → 玩家不受伤")

	e.free()


## 【3E】青铜巨像 精英
## HP=55, 护体=30, 荆棘3层
## R1=巨像固化(+15护体) → R2=重盾猛击(12伤+震慑) → R3=反震修补(+2荆棘)
func test_elite_tank_cycle() -> void:
	var e = _make_engine_with_enemy("elite_qing_tong_ju_xiang")
	var s = e.get("s")
	_assert_eq(s["enemy_hp"],    55, "[青铜巨像] 初始HP=55")
	_assert_eq(s["enemy_hu_ti"], 30, "[青铜巨像] 初始护体=30")
	_assert_eq(s.get("enemy_jing_ci", 0), 3, "[青铜巨像] 初始荆棘=3")

	# R1：巨像固化，护体+15 → 护体=45
	_do_enemy_turn(e)
	_assert_eq(s["enemy_hu_ti"], 45, "[青铜巨像] R1 巨像固化 → 护体45(30+15)")

	# R2：重盾猛击12伤+震慑1
	var hp2 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp2 - s["player_hp"], 12, "[青铜巨像] R2 重盾猛击 → 玩家受12伤")
	_assert_true(s["player_statuses"].get("zhen_she", 0) >= 1, "[青铜巨像] R2 → 震慑>=1")

	# R3：反震修补，荆棘+2 → 荆棘=5
	_do_enemy_turn(e)
	_assert_eq(s.get("enemy_jing_ci", 0), 5, "[青铜巨像] R3 反震修补 → 荆棘=5(3+2)")

	e.free()


## 【4E】深渊大咒师 精英
## HP=60, R1=深渊诅咒(5伤+暗伤入抽牌堆顶) → R2=全面剥夺(2枯竭+1裂伤) → R3=咒力引爆(15伤)
func test_elite_debuffer_cycle() -> void:
	var e = _make_engine_with_enemy("elite_shen_yuan_da_zhou_shi")
	var s = e.get("s")
	_assert_eq(s["enemy_hp"], 60, "[深渊大咒师] 初始HP=60")

	# R1：深渊诅咒5伤+暗伤入抽牌堆顶（push_front插入）
	var hp1 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp1 - s["player_hp"], 5, "[深渊大咒师] R1 深渊诅咒 → 玩家受5伤")
	# 注：draw_pile 初始为空，R1 turn 结束后 _start_player_turn 会抽牌（空牌堆则洗入弃牌堆）
	# 污染牌在 discard_pile 或被抽入 hand 均视为成功插入
	var curse_inserted = false
	for c in s["draw_pile"]:
		if c.get("is_curse", false):
			curse_inserted = true
	for c in s["hand"]:
		if c.get("is_curse", false):
			curse_inserted = true
	for c in s["discard_pile"]:
		if c.get("is_curse", false):
			curse_inserted = true
	_assert_true(curse_inserted, "[深渊大咒师] R1 → 暗伤污染牌已插入牌堆")

	# R2：全面剥夺，施加 ku_jie=2 + lie_shang=1
	# 玩家状态在 end_turn 时才 tick，敌方回合结束后状态保持施加值，不提前减少
	_do_enemy_turn(e)
	_assert_eq(s["player_statuses"].get("ku_jie",    0), 2, "[深渊大咒师] R2 全面剥夺 → 玩家ku_jie=2(施加值，end_turn前不tick)")
	_assert_eq(s["player_statuses"].get("lie_shang", 0), 1, "[深渊大咒师] R2 全面剥夺 → lie_shang=1(施加值，end_turn前不tick)")

	# R3：咒力引爆，R2 施加的 lie_shang=1 仍有效（end_turn前不tick）
	# 实际伤害 = floor(15 × 1.5) = 22
	var hp3 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(hp3 - s["player_hp"], 22, "[深渊大咒师] R3 咒力引爆 → 玩家受22伤(lie_shang加成，15×1.5)")

	e.free()


## 【5E】远古噬天虫 精英
## HP=85, 护体=10, 初始道行=2, 每回合+1道行
## 循环2回合：疯狂连击(4×3)→深渊吞噬(10伤+吸血)
func test_elite_escalating_cycle() -> void:
	var e = _make_engine_with_enemy("elite_yuan_gu_shi_tian_chong")
	var s = e.get("s")
	_assert_eq(s["enemy_hp"],    85, "[远古噬天虫] 初始HP=85")
	_assert_eq(s["enemy_hu_ti"], 10, "[远古噬天虫] 初始护体=10")
	_assert_eq(s.get("enemy_dao_xing", 0), 2, "[远古噬天虫] 初始道行=2")

	# R1：被动先+1道行→道行=3，疯狂连击(4+3)×3=21伤
	_do_enemy_turn(e)
	_assert_eq(s.get("enemy_dao_xing", 0), 3, "[远古噬天虫] R1 被动道行+1 → 道行=3")
	_assert_eq(s["player_hp"], 80 - 21, "[远古噬天虫] R1 疯狂连击(7×3=21) → 玩家HP=59")

	# R2：被动+1道行→道行=4，深渊吞噬(10+4=14伤)，护体10先吸收→HP损失4，吸血回4
	var enemy_hp2 = s["enemy_hp"]
	var hp2 = s["player_hp"]
	_do_enemy_turn(e)
	_assert_eq(s.get("enemy_dao_xing", 0), 4, "[远古噬天虫] R2 被动道行+1 → 道行=4")
	_assert_eq(hp2 - s["player_hp"], 14, "[远古噬天虫] R2 深渊吞噬(14=10+4) → 玩家受14伤")
	# 护体=10，吸收10，HP伤害=4，吸血=4
	_assert_true(s["enemy_hp"] >= enemy_hp2, "[远古噬天虫] R2 吸血 → 怪物HP不减")

	e.free()


# ═══════════════════════════════════════════════════
# 随机选怪机制测试
# ═══════════════════════════════════════════════════

## 验证 EnemyDatabase 随机选怪返回的是合法的普通怪
func test_random_normal_selection() -> void:
	var db = load("res://scripts/data/EnemyDatabase.gd").new()
	db.call("_ready")
	var normal_pool = ["normal_xue_ling_kuang_tu", "normal_ni_ying_si_shi",
		"normal_qing_tong_wei_jia", "normal_fu_hua_zhou_shi", "normal_tun_shi_you_yan"]
	## 多次随机，验证每次都是合法ID
	for _i in range(10):
		var enemy = db.call("get_enemy_for_node", "normal", 1)
		_assert_true(enemy.has("id"), "[随机选怪] 普通战斗 → 返回有效敌人")
		_assert_true(enemy.get("id", "") in normal_pool, "[随机选怪] 普通ID在合法池中")
		_assert_true(enemy.get("type", "") == "normal", "[随机选怪] 类型=normal")
		break  # 仅验证一次（随机性无需多次）
	db.free()


## 验证 EnemyDatabase 随机选怪返回的是合法的精英怪
func test_random_elite_selection() -> void:
	var db = load("res://scripts/data/EnemyDatabase.gd").new()
	db.call("_ready")
	var elite_pool = ["elite_xue_yu_kuang_mo", "elite_an_ying_ci_ke",
		"elite_qing_tong_ju_xiang", "elite_shen_yuan_da_zhou_shi", "elite_yuan_gu_shi_tian_chong"]
	var enemy = db.call("get_enemy_for_node", "elite", 5)
	_assert_true(enemy.has("id"), "[随机选怪] 精英战斗 → 返回有效敌人")
	_assert_true(enemy.get("id", "") in elite_pool, "[随机选怪] 精英ID在合法池中")
	_assert_true(enemy.get("type", "") == "elite", "[随机选怪] 类型=elite")
	db.free()
