## TestCardEffects.gd
## 38张卡牌效果单元测试。每张牌都有独立的测试函数。
extends RefCounted

const BattleEngineScript = preload("res://scripts/BattleEngine.gd")

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestCardEffects ]")
	_t("test_card_1")
	_t("test_card_2")
	_t("test_card_3")
	_t("test_card_4")
	_t("test_card_5")
	_t("test_card_6")
	_t("test_card_7")
	_t("test_card_8")
	_t("test_card_9")
	_t("test_card_10")
	_t("test_card_11")
	_t("test_card_12")
	_t("test_card_13")
	_t("test_card_14")
	_t("test_card_15")
	_t("test_card_16")
	_t("test_card_17")
	_t("test_card_18")
	_t("test_card_19")
	_t("test_card_20")
	_t("test_card_21")
	_t("test_card_22")
	_t("test_card_23")
	_t("test_card_24")
	_t("test_card_25")
	_t("test_card_26")
	_t("test_card_27")
	_t("test_card_28")
	_t("test_card_29")
	_t("test_card_30")
	_t("test_card_31")
	_t("test_card_32")
	_t("test_card_33")
	_t("test_card_34")
	_t("test_card_35")
	_t("test_card_36")
	_t("test_card_37")
	_t("test_card_38")
	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ── 工具 ──────────────────────────────────────────

## 创建一个战斗引擎，已初始化好玩家和敌人数据。
## 玩家：HP=60, 灵力上限=20, 道慧=10
## 敌人：HP=100, 护体=0
func _make_engine() -> Object:
	var e: Object = BattleEngineScript.new()
	var char_data = {"hp_max": 60, "ling_li_max": 20, "dao_hui_max": 10}
	var enemy_data = {"hp": 100, "hu_ti": 0, "name": "测试敌人", "actions": []}
	e.init(char_data, [], enemy_data)
	return e


func _t(method: String) -> void:
	call(method)


func _assert_eq(a, b, label: String) -> void:
	if str(a) == str(b):
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 期望 %s，实际 %s" % [label, str(b), str(a)])


func _assert_true(cond: bool, label: String) -> void:
	if cond:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 条件为假" % label)


# ── 测试用例 ──────────────────────────────────────────

## 测试 [1] 点星剑法（术法）
func test_card_1() -> void:
	var e = _make_engine()
	var card = {"id": "1", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 91, "点星剑法 基础伤害应为9 (100-9=91)")
	_assert_eq(s["hand"].size(), 1, "点星剑法 应该抽取1张牌")

## 测试 [2] 枭首斩（术法）
func test_card_2() -> void:
	var e = _make_engine()
	var card = {"id": "2", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 94, "枭首斩 基础伤害应为6 (100-6=94)")
	_assert_eq(s["player_ling_li"], 3, "枭首斩 造成HP损失后应获得3灵力")

## 测试 [3] 灵能汇聚剑（术法）
func test_card_3() -> void:
	var e = _make_engine()
	var card = {"id": "3", "is_upgraded": false}
	var s = e.get("s")
	# 设置灵力为4，用于测试灵力加成伤害
	s["player_ling_li"] = 4
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 87, "灵能汇聚剑 灵力4时伤害应为13 (7+2*3=13, 100-13=87)")

## 测试 [4] 蜻蜓点水剑（术法）
func test_card_4() -> void:
	var e = _make_engine()
	var card = {"id": "4", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 96, "蜻蜓点水剑 应造成2×2=4点伤害 (100-4=96)")

## 测试 [5] 剑气斩（术法）
func test_card_5() -> void:
	var e = _make_engine()
	var card = {"id": "5", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 94, "剑气斩 基础伤害应为6 (100-6=94)")

## 测试 [6] 双影斩（术法）
func test_card_6() -> void:
	var e = _make_engine()
	var card = {"id": "6", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 90, "双影斩 应造成5×2=10点伤害 (100-10=90)")

## 测试 [7] 百脉连击（术法）
func test_card_7() -> void:
	var e = _make_engine()
	var card = {"id": "7", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 80, "百脉连击 应造成5×4=20点伤害 (100-20=80)")

## 测试 [8] 崩甲剑（术法）
func test_card_8() -> void:
	var e = _make_engine()
	var card = {"id": "8", "is_upgraded": false}
	var s = e.get("s")
	# 设置敌人护体10，触发崩甲额外伤害
	s["enemy_hu_ti"] = 10
	s["enemy_hp_max"] = 100
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hu_ti"], 0, "崩甲剑 应破除所有护体")
	_assert_eq(s["enemy_hp"], 87, "崩甲剑 破甲后额外8伤，总23伤穿透10护体，HP损失13 (100-13=87)")

## 测试 [9] 孤注一掷（术法）
func test_card_9() -> void:
	var e = _make_engine()
	var card = {"id": "9", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 74, "孤注一掷 基础伤害应为26 (100-26=74)")

## 测试 [10] 藏锋积势（术法）
func test_card_10() -> void:
	var e = _make_engine()
	var card = {"id": "10", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 94, "藏锋积势 伤害应为6 (100-6=94)")
	_assert_eq(s["next_turn_dao_xing"], 1, "藏锋积势 应设置下回合道行+1")

## 测试 [11] 逆鳞斩（术法）
func test_card_11() -> void:
	var e = _make_engine()
	var card = {"id": "11", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 92, "逆鳞斩 基础伤害应为8 (100-8=92)")
	_assert_eq(s["enemy_statuses"].get("lie_shang", 0), 2, "逆鳞斩 应施加2层裂伤")

## 测试 [12] 破风刺（术法）
func test_card_12() -> void:
	var e = _make_engine()
	var card = {"id": "12", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 90, "破风刺 基础伤害应为10 (100-10=90)")
	_assert_eq(s["hand"].size(), 2, "破风刺 应抽取2张牌")

## 测试 [13] 万法合击（术法）
func test_card_13() -> void:
	var e = _make_engine()
	var card = {"id": "13", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 80, "万法合击 基础伤害应为20 (100-20=80)")
	_assert_eq(s["player_hu_ti"], 10, "万法合击 应获得10护体")
	_assert_eq(s["hand"].size(), 2, "万法合击 应抽取2张牌")
	_assert_eq(s["player_dao_xing"], 2, "万法合击 应获得2层道行")

## 测试 [14] 剔骨诀（术法）
func test_card_14() -> void:
	var e = _make_engine()
	var card = {"id": "14", "is_upgraded": false}
	var s = e.get("s")
	# 降低敌人血量，确保攻击能造成伤害触发buff
	s["enemy_hp"] = 50
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 38, "剔骨诀 应造成4×3=12点伤害 (50-12=38)")
	_assert_true(s.has("ti_gu_draw_turns"), "剔骨诀 敌人掉血后应设置额外抽牌buff")

## 测试 [15] 游丝连击（术法）
func test_card_15() -> void:
	var e = _make_engine()
	var card = {"id": "15", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 88, "游丝连击 基础伤害应为12 (100-12=88)")
	_assert_eq(s["delayed_damage"], 12, "游丝连击 应设置12点延迟伤害")

## 测试 [16] 百剑回响（术法）
func test_card_16() -> void:
	var e = _make_engine()
	var card = {"id": "16", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 95, "百剑回响 基础伤害应为5 (100-5=95)")
	_assert_eq(s["enemy_statuses"].get("ku_jie", 0), 2, "百剑回响 应施加2层枯竭")

## 测试 [17] 磐石剑（术法）
func test_card_17() -> void:
	var e = _make_engine()
	var card = {"id": "17", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 88, "磐石剑 基础伤害应为12 (100-12=88)")
	_assert_eq(s["player_hu_ti"], 12, "磐石剑 应获得等量护体12")

## 测试 [18] 斩道剑（术法）
func test_card_18() -> void:
	var e = _make_engine()
	var card = {"id": "18", "is_upgraded": false}
	var s = e.get("s")
	# 敌人血量低于10%（100*10%=10），触发秒杀
	s["enemy_hp"] = 1
	s["enemy_hp_max"] = 100
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 0, "斩道剑 敌人HP低于10%时应直接击杀 (enemy_hp=0)")

## 测试 [19] 万灵破（术法）
func test_card_19() -> void:
	var e = _make_engine()
	var card = {"id": "19", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")
	_assert_eq(s["enemy_hp"], 94, "万灵破 应造成1×6=6点伤害 (100-6=94)")
	_assert_eq(s["player_ling_li"], 6, "万灵破 6次命中应恢复6灵力")

## 测试 [20] 剑气护体（秘法）
func test_card_20() -> void:
	var e = _make_engine()
	var card = {"id": "20", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["player_hu_ti"], 6, "剑气护体 应获得6点护体")

## 测试 [21] 凝气层（秘法）
func test_card_21() -> void:
	var e = _make_engine()
	var card = {"id": "21", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["player_hu_ti"], 8, "凝气层 应获得8点护体")
	_assert_eq(s["player_ling_li"], 3, "凝气层 应获得3点灵力")

## 测试 [22] 踏雪无痕（秘法）
func test_card_22() -> void:
	var e = _make_engine()
	var card = {"id": "22", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["player_hu_ti"], 6, "踏雪无痕 应获得6点护体")
	_assert_eq(s["player_dao_xing"], 1, "踏雪无痕 应获得1层道行")

## 测试 [23] 引灵归元（秘法）
func test_card_23() -> void:
	var e = _make_engine()
	var card = {"id": "23", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["player_hu_ti"], 6, "引灵归元 应获得6点护体")
	_assert_eq(s["player_ling_li_regen"], s.get("player_ling_li_regen", 0), "引灵归元 应增加灵力回复量")

## 测试 [24] 导气术（秘法）
func test_card_24() -> void:
	var e = _make_engine()
	var card = {"id": "24", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["hand"].size(), 2, "导气术 应抽取2张牌")
	_assert_eq(s["player_ling_li"], 3, "导气术 应获得3点灵力")

## 测试 [25] 乱局重整（秘法）
func test_card_25() -> void:
	var e = _make_engine()
	var card = {"id": "25", "is_upgraded": false}
	var s = e.get("s")
	# 预置2张手牌用于弃置
	s["hand"] = [{"id": "1", "card_type": "attack"}, {"id": "2", "card_type": "skill"}]
	s["draw_pile"] = [{"id": "3"}, {"id": "4"}, {"id": "5"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["discard_pile"].size(), 2, "乱局重整 应将手牌2张放入弃牌堆")
	_assert_eq(s["hand"].size(), 3, "乱局重整 应抽取手牌数量+1=3张牌")

## 测试 [26] 缓气式（秘法）
func test_card_26() -> void:
	var e = _make_engine()
	var card = {"id": "26", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["player_hu_ti"], 5, "缓气式 应获得5点护体")
	_assert_eq(s["extra_draw_next_turn"], 1, "缓气式 应设置下回合额外抽牌1张")

## 测试 [27] 旧招重现（秘法）
func test_card_27() -> void:
	var e = _make_engine()
	var card = {"id": "27", "is_upgraded": false}
	var s = e.get("s")
	# 弃牌堆里有1张术法牌可以回收
	s["discard_pile"] = [{"id": "1", "card_type": "attack", "dao_hui": 4}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["hand"].size(), 1, "旧招重现 应将弃牌堆顶术法牌加入手牌")
	_assert_true(s["hand"][0].has("dao_hui_discount"), "旧招重现 回手牌应附带道慧折扣")

## 测试 [28] 收敛锋芒（秘法）
func test_card_28() -> void:
	var e = _make_engine()
	var card = {"id": "28", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["player_hu_ti"], 12, "收敛锋芒 应获得12点护体")

## 测试 [29] 舍利求活（秘法）
func test_card_29() -> void:
	var e = _make_engine()
	var card = {"id": "29", "is_upgraded": false}
	var s = e.get("s")
	# 预置2张手牌用于弃置
	s["hand"] = [{"id": "1", "card_type": "attack"}, {"id": "2", "card_type": "skill"}]
	s["draw_pile"] = [{"id": "3"}, {"id": "4"}, {"id": "5"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["player_hu_ti"], 8, "舍利求活 每弃1张获得4护体，弃2张=8护体")
	_assert_eq(s["hand"].size(), 2, "舍利求活 应抽取2张牌")

## 测试 [30] 剑压锁喉（秘法）
func test_card_30() -> void:
	var e = _make_engine()
	var card = {"id": "30", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["hand"].size(), 2, "剑压锁喉 应抽取2张牌")
	_assert_eq(s["player_statuses"].get("xin_liu", 0), 2, "剑压锁喉 应获得2层心流")

## 测试 [31] 化剑为盾（秘法）
func test_card_31() -> void:
	var e = _make_engine()
	var card = {"id": "31", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["player_hu_ti"], 20, "化剑为盾 应获得20点护体")
	_assert_eq(s["player_statuses"].get("bu_qin", 0), 2, "化剑为盾 应获得2层不侵")

## 测试 [32] 灵化剑心（秘法）
func test_card_32() -> void:
	var e = _make_engine()
	var card = {"id": "32", "is_upgraded": false}
	var s = e.get("s")
	# 设置灵力=10，cost=4时可消耗2次，获得2层道行
	s["player_ling_li"] = 10
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_eq(s["player_ling_li"], 2, "灵化剑心 消耗灵力 10 / 4 = 2次消耗，剩余 10 - 4*2 = 2")
	_assert_eq(s["player_dao_xing"], 2, "灵化剑心 应获得2层道行 (各消耗一次)")

## 测试 [33] 养剑功（道法）
func test_card_33() -> void:
	var e = _make_engine()
	var card = {"id": "33", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s.has("powers_active"), "道法牌 powers_active 应被创建")
	_assert_true(s["powers_active"].size() > 0, "道法牌 应被加入激活列表")
	_assert_eq(s["powers_active"][0]["id"], "33", "激活的道法牌ID应为33")

## 测试 [34] 剑意化盾（道法）
func test_card_34() -> void:
	var e = _make_engine()
	var card = {"id": "34", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s.has("powers_active"), "道法牌 powers_active 应被创建")
	_assert_true(s["powers_active"].size() > 0, "道法牌 应被加入激活列表")
	_assert_eq(s["powers_active"][0]["id"], "34", "激活的道法牌ID应为34")

## 测试 [35] 固本经（道法）
func test_card_35() -> void:
	var e = _make_engine()
	var card = {"id": "35", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s.has("powers_active"), "道法牌 powers_active 应被创建")
	_assert_true(s["powers_active"].size() > 0, "道法牌 应被加入激活列表")
	_assert_eq(s["powers_active"][0]["id"], "35", "激活的道法牌ID应为35")

## 测试 [36] 势如破竹（道法）
func test_card_36() -> void:
	var e = _make_engine()
	var card = {"id": "36", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s.has("powers_active"), "道法牌 powers_active 应被创建")
	_assert_true(s["powers_active"].size() > 0, "道法牌 应被加入激活列表")
	_assert_eq(s["powers_active"][0]["id"], "36", "激活的道法牌ID应为36")

## 测试 [37] 连战连捷（道法）
func test_card_37() -> void:
	var e = _make_engine()
	var card = {"id": "37", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s.has("powers_active"), "道法牌 powers_active 应被创建")
	_assert_true(s["powers_active"].size() > 0, "道法牌 应被加入激活列表")
	_assert_eq(s["powers_active"][0]["id"], "37", "激活的道法牌ID应为37")

## 测试 [38] 破天立命（道法）
func test_card_38() -> void:
	var e = _make_engine()
	var card = {"id": "38", "is_upgraded": false}
	var s = e.get("s")
	s["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]
	e.call("_apply_card_effect", card)
	# 断言
	_assert_true(s.has("powers_active"), "道法牌 powers_active 应被创建")
	_assert_true(s["powers_active"].size() > 0, "道法牌 应被加入激活列表")
	_assert_eq(s["powers_active"][0]["id"], "38", "激活的道法牌ID应为38")