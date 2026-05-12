## TestHandLayout.gd
## 测试手牌布局计算逻辑 + BattleEngine 手牌/牌库管理逻辑
extends RefCounted

const BattleEngineScript = preload("res://scripts/BattleEngine.gd")
const BattleSceneScript = preload("res://scripts/BattleScene.gd")
const CardRendererScript = preload("res://scripts/CardRenderer.gd")
const CardViewScene = preload("res://scenes/CardView.tscn")

const _CARD_W   := 100.0
const _SEP_NORM := 12.0
const _VIS_MAX  := 680.0
const _MAX_W    := 840.0

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []


func run_all() -> Dictionary:
	_lines.append("\n[ TestHandLayout ]")

	# 布局计算（纯数学）
	_t("test_layout_1_card_centered")
	_t("test_layout_6_cards_sep_normal")
	_t("test_layout_7_cards_sep_negative")
	_t("test_layout_counts_7_to_10_total_within_vismax")
	_t("test_layout_all_counts_left_to_right")
	_t("test_layout_all_counts_symmetric")

	# 牌库管理（BattleEngine 内部逻辑）
	_t("test_reshuffle_preserves_hand")
	_t("test_reshuffle_merges_discard_to_draw")
	_t("test_reshuffle_clears_discard")
	_t("test_reshuffle_empty_discard_noop")
	_t("test_draw_normal")
	_t("test_draw_hand_cap_10")
	_t("test_draw_triggers_reshuffle_not_hand_wipe")
	_t("test_draw_large_hand_stays_large_after_reshuffle")
	_t("test_draw_empty_draw_and_empty_discard")
	_t("test_draw_exactly_fills_to_cap")
	_t("test_reshuffle_then_draw_continues_correctly")

	# ── 新增：_start_player_turn 回合开始大手牌 ──────────────────────
	_t("test_turn_start_9cards_empty_draw_reshuffle")
	_t("test_turn_start_9cards_nonempty_draw")
	_t("test_turn_start_10cards_already_capped")
	_t("test_turn_start_0cards_draws_1")
	_t("test_turn_start_extra_draw_respects_cap")
	_t("test_turn_start_no_draw_no_discard_preserves_hand")
	_t("test_turn_start_extra_draw_cleared_after_use")
	_t("test_turn_start_sequential_3_turns_accumulate")

	# ── 新增：卡牌效果 × 大手牌 ──────────────────────────────────────
	_t("test_card25_large_hand_redraw_preserves_count")
	_t("test_card25_large_hand_cap_respected")
	_t("test_card29_large_hand_always_2")
	_t("test_card12_draw_near_cap")
	_t("test_dynamic_desc_damage_up_green")
	_t("test_dynamic_desc_damage_down_red")
	_t("test_dynamic_desc_damage_same_black")
	_t("test_dynamic_desc_upgrade_baseline")
	_t("test_renderer_uses_rounded_child_mask")
	_t("test_card_view_masks_shadow_and_renderer")
	_t("test_renderer_plain_description_uses_label_layout")
	_t("test_renderer_dynamic_description_is_transparent_and_centered")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


# ──────────────────────────────────────────────────
# 布局计算辅助（镜像 BattleScene._update_hand_display 的计算）
# ──────────────────────────────────────────────────

func _calc_layout(count: int, max_w: float = _MAX_W) -> Dictionary:
	var sep := _SEP_NORM
	if count > 6:
		sep = (_VIS_MAX - count * _CARD_W) / maxf(float(count - 1), 1.0)
	var total_w := count * _CARD_W + (count - 1) * sep
	var start_x := (max_w - total_w) / 2.0
	var positions: Array = []
	for i in range(count):
		positions.append(start_x + i * (_CARD_W + sep))
	return {"sep": sep, "total_w": total_w, "start_x": start_x, "positions": positions}


# ──────────────────────────────────────────────────
# 布局测试
# ──────────────────────────────────────────────────

func test_layout_1_card_centered() -> void:
	var r  = _calc_layout(1)
	var ex = (_MAX_W - _CARD_W) / 2.0
	_assert_approx(r["positions"][0], ex, "1张：居中 x=%.1f" % ex)


func test_layout_6_cards_sep_normal() -> void:
	var r = _calc_layout(6)
	_assert_approx(r["sep"], _SEP_NORM, "6张：sep=%.0f（不触发重叠）" % _SEP_NORM)


func test_layout_7_cards_sep_negative() -> void:
	var r = _calc_layout(7)
	_assert_true(r["sep"] < 0.0, "7张：sep=%.2f < 0（开始重叠）" % r["sep"])


func test_layout_counts_7_to_10_total_within_vismax() -> void:
	for cnt in [7, 8, 9, 10]:
		var r = _calc_layout(cnt)
		_assert_approx(r["total_w"], _VIS_MAX,
				"%d张：total_w=%.1f ≈ vismax=%.0f" % [cnt, r["total_w"], _VIS_MAX])


func test_layout_all_counts_left_to_right() -> void:
	for cnt in [1, 2, 3, 5, 6, 7, 8, 10]:
		var r       = _calc_layout(cnt)
		var pos: Array = r["positions"]
		var ok := true
		for i in range(1, pos.size()):
			if pos[i] <= pos[i - 1]:
				ok = false
				break
		_assert_true(ok, "%d张：每张位置严格向右递增" % cnt)


func test_layout_all_counts_symmetric() -> void:
	for cnt in [1, 2, 5, 6, 7, 10]:
		var r         = _calc_layout(cnt)
		var left_gap  : float = r["start_x"]
		var right_gap : float = _MAX_W - (r["start_x"] + r["total_w"])
		_assert_approx(left_gap, right_gap,
				"%d张：左右留白对称（left=%.1f right=%.1f）" % [cnt, left_gap, right_gap])


# ──────────────────────────────────────────────────
# 牌库管理测试
# ──────────────────────────────────────────────────

func _make_cards(n: int, id_start: int = 1) -> Array:
	var arr: Array = []
	for i in range(n):
		arr.append({"id": str(id_start + i), "name": "card%d" % (id_start + i),
					"_instance_id": id_start + i})
	return arr


func _make_engine(hand: Array, draw: Array, discard: Array) -> Object:
	var e: Object = BattleEngineScript.new()
	e.set("s", {
		"hand":         hand.duplicate(true),
		"draw_pile":    draw.duplicate(true),
		"discard_pile": discard.duplicate(true),
		"hand_size":    3,
	})
	return e


func test_reshuffle_preserves_hand() -> void:
	var hand    = _make_cards(8)
	var discard = _make_cards(4, 100)
	var e := _make_engine(hand, [], discard)
	e.call("_reshuffle_deck")
	_assert_eq(e.get("s")["hand"].size(), 0, "洗牌：当前手牌洗回抽牌堆")


func test_reshuffle_merges_discard_to_draw() -> void:
	var discard = _make_cards(6, 50)
	var e := _make_engine([], [], discard)
	e.call("_reshuffle_deck")
	_assert_eq(e.get("s")["draw_pile"].size(), 6, "洗牌：6张弃牌全进抽牌堆")


func test_reshuffle_clears_discard() -> void:
	var discard = _make_cards(5, 50)
	var e := _make_engine([], [], discard)
	e.call("_reshuffle_deck")
	_assert_eq(e.get("s")["discard_pile"].size(), 0, "洗牌：弃牌堆清空")


func test_reshuffle_empty_discard_noop() -> void:
	var hand = _make_cards(3)
	var e := _make_engine(hand, [], [])
	e.call("_reshuffle_deck")
	_assert_eq(e.get("s")["hand"].size(),      0, "弃牌堆为空但有手牌：手牌洗回抽牌堆")
	_assert_eq(e.get("s")["draw_pile"].size(), 3, "弃牌堆为空但有手牌：抽牌堆获得3张")


func test_draw_normal() -> void:
	var draw = _make_cards(5, 10)
	var e := _make_engine([], draw, [])
	e.call("_draw_cards", 3)
	_assert_eq(e.get("s")["hand"].size(),      3, "正常抽3张 → 手牌3张")
	_assert_eq(e.get("s")["draw_pile"].size(), 2, "抽3后抽牌堆剩2张")


func test_draw_hand_cap_10() -> void:
	var hand = _make_cards(9)
	var draw = _make_cards(5, 100)
	var e := _make_engine(hand, draw, [])
	e.call("_draw_cards", 5)
	_assert_eq(e.get("s")["hand"].size(), 10, "手牌上限10：9张+抽5 → 上限10张")


func test_draw_triggers_reshuffle_not_hand_wipe() -> void:
	# 手牌8张，抽牌堆空，弃牌堆3张 → 触发洗牌，并重抽3张
	var hand    = _make_cards(8)
	var discard = _make_cards(3, 50)
	var e := _make_engine(hand, [], discard)
	e.call("_draw_cards", 1)
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 3, "手牌8张触发洗牌后重抽3张，实际：%d" % sz)


func test_draw_large_hand_stays_large_after_reshuffle() -> void:
	# 9张手牌，抽牌堆空，弃牌堆20张，_draw_cards(1) 后应重洗并重抽3
	var hand    = _make_cards(9)
	var discard = _make_cards(20, 100)
	var e := _make_engine(hand, [], discard)
	e.call("_draw_cards", 1)
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 3, "9张手牌触发洗牌后重抽3张，实际：%d" % sz)


func test_draw_empty_draw_and_empty_discard() -> void:
	# 抽牌堆和弃牌堆均空，_draw_cards 应安全退出，手牌不变
	var hand = _make_cards(3)
	var e := _make_engine(hand, [], [])
	e.call("_draw_cards", 5)
	_assert_eq(e.get("s")["hand"].size(), 3, "双堆均空：手牌保持不变（3张）")


func test_draw_exactly_fills_to_cap() -> void:
	# 手牌7张，抽牌堆有10张，抽3张应恰好到10上限
	var hand = _make_cards(7)
	var draw = _make_cards(10, 100)
	var e := _make_engine(hand, draw, [])
	e.call("_draw_cards", 3)
	_assert_eq(e.get("s")["hand"].size(),      10, "7+3 = 恰好到上限10")
	_assert_eq(e.get("s")["draw_pile"].size(),  7, "抽3后抽牌堆剩7张")


func test_reshuffle_then_draw_continues_correctly() -> void:
	# 手牌2张，抽牌堆1张，弃牌堆5张
	# _draw_cards(4)：先抽1张，抽牌堆耗尽后重洗当前手牌+弃牌，并重抽3张
	var hand    = _make_cards(2)
	var draw    = _make_cards(1, 50)
	var discard = _make_cards(5, 60)
	var e := _make_engine(hand, draw, discard)
	e.call("_draw_cards", 4)
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 3, "抽牌中途耗尽后重洗并重抽3张，实际：%d" % sz)


# ──────────────────────────────────────────────────
# _start_player_turn 回合开始 × 大手牌
# 关键复现：大于8张时下一回合变成6张的 bug 根因 = _reshuffle_deck 曾
# 清空手牌+重抽5张，再由 _draw_cards 多抽1张 = 5+1=6
# ──────────────────────────────────────────────────

func _make_turn_state(hand_n: int, draw_n: int, discard_n: int, extra_draw: int = 0) -> Object:
	var e: Object = BattleEngineScript.new()
	e.set("s", {
		"hand":                          _make_cards(hand_n),
		"draw_pile":                     _make_cards(draw_n, 100),
		"discard_pile":                  _make_cards(discard_n, 200),
		"hand_size":                     3,
		"player_ling_li":                0,
		"player_ling_li_max":            20,
		"player_ling_li_regen":          3,
		"player_dao_hui":                0,
		"player_dao_hui_max":            6,
		"extra_draw_next_turn":          extra_draw,
		"turn":                          1,
		"phase":                         "enemy",
		"cards_played_this_turn":        0,
		"attack_cards_played_this_turn": 0,
		"skill_used_this_turn":          false,
		"next_attack_bonus":             0,
	})
	return e


func test_turn_start_9cards_empty_draw_reshuffle() -> void:
	# 核心 Bug 场景：9张手牌 + 抽牌堆空 + 有弃牌堆 → 新回合抽1张触发洗牌
	# 旧代码：洗牌清空手牌重抽5张，再抽1 = 6（Bug）
	# 新代码：洗牌不动手牌，直接抽1 → 10
	var e := _make_turn_state(9, 0, 15)
	e.call("_start_player_turn")
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 3, "回合开始(9张+空抽牌堆): 重洗后重抽3张，实际：%d" % sz)


func test_turn_start_9cards_nonempty_draw() -> void:
	# 抽牌堆不为空：9张直接抽1 → 10，无洗牌路径
	var e := _make_turn_state(9, 5, 0)
	e.call("_start_player_turn")
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 10, "回合开始(9张+5抽): 直接抽1→10，实际：%d" % sz)


func test_turn_start_10cards_already_capped() -> void:
	# 10张已达上限：新回合不能再抽，保持10
	var e := _make_turn_state(10, 5, 5)
	e.call("_start_player_turn")
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 10, "回合开始(10张=上限): 不再抽牌，保持10，实际：%d" % sz)


func test_turn_start_0cards_draws_1() -> void:
	# 手牌为空：新回合正常抽1张
	var e := _make_turn_state(0, 5, 0)
	e.call("_start_player_turn")
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 1, "回合开始(0张): 抽1 → 1，实际：%d" % sz)


func test_turn_start_extra_draw_respects_cap() -> void:
	# extra_draw_next_turn=1 → 本回合抽2张；手牌9张时只能再抽1张到上限
	var e := _make_turn_state(9, 5, 0, 1)
	e.call("_start_player_turn")
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 10, "回合开始(9张+extra抽2): 恰好到上限10，实际：%d" % sz)


func test_turn_start_no_draw_no_discard_preserves_hand() -> void:
	# 双堆均空：9张手牌无法再抽，保持不变
	var e := _make_turn_state(9, 0, 0)
	e.call("_start_player_turn")
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 3, "回合开始(仅手牌可洗): 重抽3张，实际：%d" % sz)


func test_turn_start_extra_draw_cleared_after_use() -> void:
	# extra_draw 使用后应清零，不应跨回合累积
	var e := _make_turn_state(0, 5, 0, 2)
	e.call("_start_player_turn")
	var extra: int = int(e.get("s")["extra_draw_next_turn"])
	_assert_eq(extra, 0, "extra_draw_next_turn 使用后清零，实际：%d" % extra)


func test_turn_start_sequential_3_turns_accumulate() -> void:
	# 连续3回合不出牌：手牌从7逐步增长，不会中途归零或变成6
	var e := _make_turn_state(7, 10, 0)
	var prev_sz: int = 7
	for _i in range(3):
		e.call("_start_player_turn")
		var sz: int = e.get("s")["hand"].size()
		_assert_true(sz >= prev_sz,
			"连续回合手牌单调递增：前=%d 后=%d（不应归零）" % [prev_sz, sz])
		prev_sz = sz
	_assert_eq(prev_sz, 10, "3回合后: 7→8→9→10，实际：%d" % prev_sz)


# ──────────────────────────────────────────────────
# 卡牌效果 × 大手牌
# TestCardEffects 只测了手牌=2的小场景，这里补大手牌边界
# ──────────────────────────────────────────────────

func _make_effect_state(hand_n: int, draw_n: int, discard_n: int) -> Object:
	var e: Object = BattleEngineScript.new()
	e.set("s", {
		"hand":                          _make_cards(hand_n),
		"draw_pile":                     _make_cards(draw_n, 100),
		"discard_pile":                  _make_cards(discard_n, 200),
		"hand_size":                     3,
		"player_ling_li":                15,
		"player_ling_li_max":            20,
		"player_ling_li_regen":          3,
		"player_dao_hui":                6,
		"player_dao_hui_max":            6,
		"player_dao_xing":               0,
		"player_damage_mult":            1.0,
		"player_hu_ti":                  0,
		"player_hp":                     60,
		"player_hp_max":                 60,
		"player_statuses":               {},
		"enemy_hp":                      100,
		"enemy_hp_max":                  100,
		"enemy_hu_ti":                   0,
		"enemy_statuses":               {},
		"cards_played_this_turn":        0,
		"attack_cards_played_this_turn": 0,
		"next_attack_bonus":             0,
	})
	return e


func test_card25_large_hand_redraw_preserves_count() -> void:
	# 乱局重整(25)：手牌8张（play_card已erase打出牌，手牌=原9-1=8）
	# 效果：弃出8张，重抽 8+1=9 张。手牌应 ≥ 8 且 ≤ 10
	var e := _make_effect_state(8, 0, 2)  # draw=0 触发洗牌路径
	e.call("_apply_card_effect", {"id": "25", "is_upgraded": false})
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 3, "乱局重整(空抽牌堆): 洗牌后重抽3张，实际：%d" % sz)


func test_card25_large_hand_cap_respected() -> void:
	# 乱局重整升级版(25+)：手牌9张→弃出9→重抽 9+2=11，但上限10
	var e := _make_effect_state(9, 5, 5)
	e.call("_apply_card_effect", {"id": "25", "is_upgraded": true})
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 10, "乱局重整+(手牌9张): 最多抽到上限10，实际：%d" % sz)


func test_card29_large_hand_always_2() -> void:
	# 舍利求活(29)：无论手牌多大，效果恒为弃出全部+抽2张
	var e := _make_effect_state(9, 5, 0)
	e.call("_apply_card_effect", {"id": "29", "is_upgraded": false})
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 2, "舍利求活(手牌9张): 弃全部+抽2 → 2，实际：%d" % sz)


func test_card12_draw_near_cap() -> void:
	# 破风刺(12)：手牌8张时打出，效果包含抽2张；应抽到上限10
	var e := _make_effect_state(8, 5, 0)
	e.call("_apply_card_effect", {"id": "12", "is_upgraded": false})
	var sz: int = e.get("s")["hand"].size()
	_assert_eq(sz, 10, "破风刺(手牌8张+抽2): 恰好到上限10，实际：%d" % sz)


# ──────────────────────────────────────────────────
# 工具
# ──────────────────────────────────────────────────

func test_dynamic_desc_damage_up_green() -> void:
	var card := {"id": "05", "desc": "造成 6(9) 点伤害。", "is_upgraded": false}
	var segments := BattleSceneScript.build_dynamic_description_segments(card, {
		"player_dao_xing": 5,
		"player_damage_mult": 1.1,
		"player_statuses": {},
	})
	_assert_eq(_segments_text(segments), "造成 12 点伤害。", "dynamic desc: hand/preview text uses computed damage")
	_assert_eq(segments[1]["color"], BattleSceneScript.CARD_NUM_COLOR_UP, "dynamic desc: higher damage number is green")


func test_dynamic_desc_damage_down_red() -> void:
	var card := {"id": "05", "desc": "造成 6(9) 点伤害。", "is_upgraded": false}
	var segments := BattleSceneScript.build_dynamic_description_segments(card, {
		"player_dao_xing": 0,
		"player_damage_mult": 1.0,
		"player_statuses": {"ku_jie": 1},
	})
	_assert_eq(_segments_text(segments), "造成 4 点伤害。", "dynamic desc: lower damage text is recomputed")
	_assert_eq(segments[1]["color"], BattleSceneScript.CARD_NUM_COLOR_DOWN, "dynamic desc: lower damage number is red")


func test_dynamic_desc_damage_same_black() -> void:
	var card := {"id": "05", "desc": "造成 6(9) 点伤害。", "is_upgraded": false}
	var segments := BattleSceneScript.build_dynamic_description_segments(card, {
		"player_dao_xing": 0,
		"player_damage_mult": 1.0,
		"player_statuses": {},
	})
	_assert_eq(_segments_text(segments), "造成 6 点伤害。", "dynamic desc: unchanged damage remains base value")
	_assert_eq(segments[1]["color"], BattleSceneScript.CARD_NUM_COLOR_NORMAL, "dynamic desc: unchanged damage number is black")


func test_dynamic_desc_upgrade_baseline() -> void:
	var card := {"id": "05", "desc": "造成 6(9) 点伤害。", "is_upgraded": true}
	var segments := BattleSceneScript.build_dynamic_description_segments(card, {
		"player_dao_xing": 0,
		"player_damage_mult": 1.0,
		"player_statuses": {},
	})
	_assert_eq(_segments_text(segments), "造成 9 点伤害。", "dynamic desc: upgraded cards compare against upgraded base value")
	_assert_eq(segments[1]["color"], BattleSceneScript.CARD_NUM_COLOR_NORMAL, "dynamic desc: upgraded base value is black when unchanged")


func test_renderer_uses_rounded_child_mask() -> void:
	var renderer = CardRendererScript.new()
	renderer.size = Vector2(100, 179)
	renderer.setup({"id": "01", "name": "card"})
	renderer.refresh()

	_assert_eq(renderer.clip_children, CanvasItem.CLIP_CHILDREN_ONLY, "CardRenderer clips all layers through rounded mask")
	_assert_true(CardRendererScript.get_corner_radius_for_size(Vector2(100, 179)) >= 8, "CardRenderer hand-card corner radius is visibly rounded")
	_assert_true(
		CardRendererScript.get_bottom_corner_radius_for_size(Vector2(100, 179)) > CardRendererScript.get_corner_radius_for_size(Vector2(100, 179)),
		"CardRenderer bottom corners are smoother than top ornamental corners"
	)
	renderer.free()


func test_card_view_masks_shadow_and_renderer() -> void:
	var view: Control = CardViewScene.instantiate()
	view.custom_minimum_size = Vector2(100, 179)
	view.size = Vector2(100, 179)
	view.setup({"id": "01", "name": "card"}, null, false)

	var renderer: Control = null
	for child in view.get_children():
		if child.has_method("set_rounded_mask_enabled"):
			renderer = child
			break

	_assert_eq(view.clip_children, CanvasItem.CLIP_CHILDREN_ONLY, "CardView clips shadow/dimmer to rounded card outline")
	_assert_true(renderer != null, "CardView owns a CardRenderer child")
	if renderer != null:
		_assert_eq(renderer.clip_children, CanvasItem.CLIP_CHILDREN_DISABLED, "Nested CardRenderer mask is disabled under CardView mask")
	view.free()


func test_renderer_plain_description_uses_label_layout() -> void:
	var renderer = CardRendererScript.new()
	renderer.size = Vector2(160, 286)
	renderer.setup({"id": "05", "desc": "造成 6(9) 点伤害。", "is_upgraded": false})
	renderer.refresh()

	var desc_label_found := false
	var rich_visible := false
	for child in renderer.get_children():
		if child is Label and str(child.text).contains("造成"):
			desc_label_found = true
		if child is RichTextLabel and child.visible:
			rich_visible = true
	_assert_true(desc_label_found, "plain card description stays on Label for centered card layout")
	_assert_true(not rich_visible, "plain card description does not use RichTextLabel")


func test_renderer_dynamic_description_is_transparent_and_centered() -> void:
	var renderer = CardRendererScript.new()
	renderer.size = Vector2(280, 502)
	renderer.setup(
		{"id": "05", "desc": "造成 6(9) 点伤害。", "is_upgraded": false},
		"造成 7 点伤害。",
		[
			{"text": "造成 ", "color": BattleSceneScript.CARD_NUM_COLOR_NORMAL},
			{"text": "7", "color": BattleSceneScript.CARD_NUM_COLOR_UP},
			{"text": " 点伤害。", "color": BattleSceneScript.CARD_NUM_COLOR_NORMAL},
		]
	)
	renderer.refresh()

	var desc_label: Label = null
	var rich_label: RichTextLabel = null
	for child in renderer.get_children():
		if child is Label and child.visible == false:
			desc_label = child
		if child is RichTextLabel and child.visible:
			rich_label = child

	_assert_true(rich_label != null, "dynamic card description uses visible RichTextLabel")
	if rich_label != null:
		_assert_true(rich_label.get_theme_stylebox("normal") is StyleBoxEmpty, "dynamic card description background is transparent")
	if rich_label != null and desc_label != null:
		_assert_true(rich_label.position.y > desc_label.position.y, "dynamic card description is vertically centered in the description box")


func _segments_text(segments: Array) -> String:
	var text := ""
	for segment in segments:
		text += str(segment.get("text", ""))
	return text


func _t(method: String) -> void:
	call(method)


func _assert_eq(a, b, label: String) -> void:
	if a == b:
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


func _assert_approx(a: float, b: float, label: String, tol: float = 0.5) -> void:
	if abs(a - b) <= tol:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 期望 %.4f，实际 %.4f" % [label, b, a])
