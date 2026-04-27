## BattleEngine.gd
## 战斗逻辑核心。不依赖任何 UI 节点，通过信号通知外部。
## 使用方式：
##   var engine = BattleEngine.new()
##   engine.init(char_data, deck_ids, enemy_data)
##   engine.start_battle()
##   engine.play_card(card_id)
##   engine.end_turn()
extends RefCounted

# ── 信号 ──────────────────────────────────────────────────────────
signal state_changed()
signal log_added(text: String)
signal battle_ended(player_won: bool)

# ── 战斗状态 ──────────────────────────────────────────────────────
var s: Dictionary = {}   # 全部状态都在这个字典里

## 初始化战斗
func init(char_data: Dictionary, deck_ids: Array, enemy_data: Dictionary) -> void:
	s = {
		# 玩家
		"player_hp":          char_data.get("hp_max", 60),
		"player_hp_max":      char_data.get("hp_max", 60),
		"player_hu_ti":       0,
		"player_ling_li":     0,
		"player_ling_li_max": char_data.get("ling_li_max", 20),
		"player_ling_li_regen": GameState.get_ling_li_regen(),
		"player_dao_hui":     char_data.get("dao_hui_max", 10),
		"player_dao_hui_max": char_data.get("dao_hui_max", 10),
		"player_dao_xing":    GameState.dao_xing_battle_start,
		"player_damage_mult": char_data.get("damage_mult", 1.0),
		"player_statuses":    {},   # {"lie_shang":n, "xu_ruo":n, ...}
		"skill_used_this_turn": false,
		"skill_dao_hui_cost": char_data.get("skill_dao_hui_cost", 10),
		"skill_dao_xing_gain": char_data.get("skill_dao_xing_gain", 1),

		# 牌堆
		"draw_pile":    [],
		"hand":         [],     # Array of card dicts
		"discard_pile": [],
		"hand_size":    5,

		# 本回合临时加成
		"next_attack_bonus":  0,  # 踏雪无痕
		"extra_draw_next_turn": 0,

		# 敌人
		"enemy_hp":          enemy_data.get("hp", 30),
		"enemy_hp_max":      enemy_data.get("hp", 30),
		"enemy_hu_ti":       enemy_data.get("hu_ti", 0),
		"enemy_statuses":    {},
		"enemy_data":        enemy_data,
		"enemy_action_idx":  0,
		"enemy_intent_text": "",

		# 元数据
		"turn":                    1,
		"cards_played_this_turn":  0,
		"attack_cards_played_this_turn": 0,
		"phase": "player",   # "player" / "enemy" / "over"
		"battle_won": false,
	}
	# 初始化牌堆
	for id in deck_ids:
		var card = CardDatabase.get_card(id)
		if not card.is_empty():
			s["draw_pile"].append(card)
	s["draw_pile"].shuffle()
	_update_enemy_intent()


func start_battle() -> void:
	_log("═══ 战斗开始 ═══")
	_log("对手：%s  HP %d" % [s["enemy_data"]["name"], s["enemy_hp"]])
	
	# 首回合灵力回复
	var regen: int = s["player_ling_li_regen"]
	s["player_ling_li"] = min(s["player_ling_li"] + regen, s["player_ling_li_max"])
	_log("  首回合灵力 +%d → %d" % [regen, s["player_ling_li"]])

	# 战斗开始抽初始手牌
	_draw_cards(s["hand_size"])
	state_changed.emit()


# ── 玩家行动 ──────────────────────────────────────────────────────

func can_play_card(card: Dictionary) -> bool:
	if s["phase"] != "player":
		return false
	return s["player_ling_li"] >= card.get("ling_li", 0) and \
		   s["player_dao_hui"] >= card.get("dao_hui", 0)


func play_card(card: Dictionary) -> void:
	if not can_play_card(card):
		return
	# 消耗资源
	s["player_ling_li"] -= card.get("ling_li", 0)
	s["player_dao_hui"] -= card.get("dao_hui", 0)
	# 从手牌移除
	s["hand"].erase(card)
	s["cards_played_this_turn"] += 1
	_log("打出：%s" % card["name"])
	# 执行效果
	_apply_card_effect(card)
	# 处理卡牌去向
	if "exhaust" in card.get("keywords", []):
		_log("  → 耗尽移出")
	elif card["card_type"] == "power":
		_log("  → 道法生效，移出本局")
	else:
		s["discard_pile"].append(card)
	# 检查战斗结束
	if _check_battle_end():
		return
	state_changed.emit()


func can_use_skill() -> bool:
	return s["phase"] == "player" and \
		   not s["skill_used_this_turn"] and \
		   s["player_dao_hui"] >= s["skill_dao_hui_cost"]


func use_hero_skill() -> void:
	if not can_use_skill():
		return
	s["player_dao_hui"] -= s["skill_dao_hui_cost"]
	s["player_dao_xing"] += s["skill_dao_xing_gain"]
	s["skill_used_this_turn"] = true
	_log("剑意凝神 → 道行 +%d（当前 %d 层）" % [s["skill_dao_xing_gain"], s["player_dao_xing"]])
	state_changed.emit()


func end_turn() -> void:
	if s["phase"] != "player":
		return
	_log("── 回合结束 ──")
	# 检查并移除带有【溃散】(ethereal) 词缀的卡牌，其他手牌保留到下回合
	var kept_hand = []
	for card in s["hand"]:
		if "ethereal" in card.get("keywords", []):
			_log("  → 溃散触发：%s 已耗尽" % card["name"])
		else:
			kept_hand.append(card)
	s["hand"] = kept_hand
	# 道慧清零
	s["player_dao_hui"] = 0
	# 进入敌方回合
	s["phase"] = "enemy"
	state_changed.emit()
	_enemy_turn()


# ── 敌方回合 ──────────────────────────────────────────────────────

func _enemy_turn() -> void:
	var enemy_data: Dictionary = s["enemy_data"]
	var actions: Array = enemy_data.get("actions", [])
	if actions.is_empty():
		_start_player_turn()
		return
	var idx: int = s["enemy_action_idx"] % actions.size()
	var action: Dictionary = actions[idx]
	s["enemy_action_idx"] += 1
	_log("敌人行动：%s" % action["name"])
	match action.get("type", ""):
		"attack":
			var dmg: int = action.get("damage", 0)
			dmg = _apply_enemy_attack_modifiers(dmg)
			_deal_damage_to_player(dmg)
	if _check_battle_end():
		return
	_update_enemy_intent()
	state_changed.emit()
	_start_player_turn()


func _apply_enemy_attack_modifiers(base_dmg: int) -> int:
	var dmg: float = base_dmg
	# 敌人虚弱：攻击力 -25%
	if s["enemy_statuses"].get("xu_ruo", 0) > 0:
		dmg *= 0.75
	return int(dmg)


# ── 新玩家回合 ────────────────────────────────────────────────────

func _start_player_turn() -> void:
	s["turn"] += 1
	s["phase"] = "player"
	s["cards_played_this_turn"] = 0
	s["attack_cards_played_this_turn"] = 0
	s["skill_used_this_turn"] = false
	s["next_attack_bonus"] = 0

	# 回合开始：灵力回复
	var regen: int = s["player_ling_li_regen"]
	s["player_ling_li"] = min(s["player_ling_li"] + regen, s["player_ling_li_max"])
	_log("═══ 第 %d 回合 ═══  灵力 +%d → %d" % [s["turn"], regen, s["player_ling_li"]])

	# 道慧重置
	s["player_dao_hui"] = s["player_dao_hui_max"]

	# 状态结算（先增益后负面）
	_tick_statuses()

	# 抽1张牌
	var draw_count: int = 1 + int(s["extra_draw_next_turn"])
	s["extra_draw_next_turn"] = 0
	_draw_cards(draw_count)

	state_changed.emit()


# ── 伤害计算 ──────────────────────────────────────────────────────

## 玩家对敌人造成伤害（含完整公式）
## formula: floor( (base + 道行) × 伤害倍率 × 状态乘区 )
func _calc_player_damage(base: int) -> int:
	var val: float = (base + s["player_dao_xing"]) * s["player_damage_mult"]
	# 玩家状态乘区
	if s["player_statuses"].get("ku_jie", 0) > 0:   # 枯竭：-25%
		val *= 0.75
	if s["player_statuses"].get("xu_ruo", 0) > 0:   # 虚弱：-25%（攻击力）
		val *= 0.75
	# 本回合加成（心流等）
	if s["player_statuses"].get("xin_liu", 0) > 0:
		val *= 1.25
	# 次次攻击临时加成（踏雪无痕）
	val += s["next_attack_bonus"]
	s["next_attack_bonus"] = 0
	return floori(val)


func _deal_damage_to_enemy(amount: int) -> void:
	# 敌人状态乘区（裂伤：受伤+50%）
	var final_dmg: float = amount
	if s["enemy_statuses"].get("lie_shang", 0) > 0:
		final_dmg *= 1.5
	# 敌人不侵：受伤-50%
	if s["enemy_statuses"].get("bu_qin", 0) > 0:
		final_dmg *= 0.5
	final_dmg = floori(final_dmg)
	# 先扣护体
	var absorbed: int = min(int(final_dmg), int(s["enemy_hu_ti"]))
	s["enemy_hu_ti"] -= absorbed
	var hp_dmg: int = int(final_dmg) - absorbed
	s["enemy_hp"] -= hp_dmg
	_log("  对敌造成 %d 伤害（护体吸收 %d，HP --%d → %d）" % [int(final_dmg), absorbed, hp_dmg, s["enemy_hp"]])


func _deal_damage_to_player(amount: int) -> void:
	var final_dmg: float = amount
	# 玩家裂伤：受伤+50%
	if s["player_statuses"].get("lie_shang", 0) > 0:
		final_dmg *= 1.5
	# 玩家不侵：受伤-50%
	if s["player_statuses"].get("bu_qin", 0) > 0:
		final_dmg *= 0.5
	final_dmg = floori(final_dmg)
	var absorbed: int = min(int(final_dmg), int(s["player_hu_ti"]))
	s["player_hu_ti"] -= absorbed
	var hp_dmg: int = int(final_dmg) - absorbed
	s["player_hp"] = max(0, s["player_hp"] - hp_dmg)
	_log("  受到 %d 伤害（护体吸收 %d，HP --%d → %d）" % [int(final_dmg), absorbed, hp_dmg, s["player_hp"]])
	GameState.apply_hp_change(-hp_dmg)


func _add_player_hu_ti(amount: int) -> void:
	s["player_hu_ti"] += amount
	_log("  获得 %d 护体（共 %d）" % [amount, s["player_hu_ti"]])


# ── 卡牌效果执行 ──────────────────────────────────────────────────

func _apply_card_effect(card: Dictionary) -> void:
	var id: String = card.get("id", "")
	var upgraded: bool = card.get("is_upgraded", false)

	match id:
		"quick_sword_pi_shan":
			var base: int = card.get("base_damage_up" if upgraded else "base_damage", 6)
			var dmg := _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1

		"ding_xin_zhou":
			var shield: int = card.get("base_shield_up" if upgraded else "base_shield", 6)
			_add_player_hu_ti(shield)

		"ling_jian_dian_xing":
			var base: int = card.get("base_damage_up" if upgraded else "base_damage", 10)
			var dmg := _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
			_draw_cards(card.get("extra_draw", 1))

		"ding_qi_ceng":
			var shield: int = card.get("base_shield_up" if upgraded else "base_shield", 8)
			_add_player_hu_ti(shield)
			var bonus_ling: int = card.get("bonus_ling_li", 3) if not upgraded else 4
			s["player_ling_li"] = min(s["player_ling_li"] + bonus_ling, s["player_ling_li_max"])
			_log("  灵力 +%d → %d" % [bonus_ling, s["player_ling_li"]])

		"zhong_jian_beng_jia":
			var base: int = card.get("base_damage_up" if upgraded else "base_damage", 15)
			var dmg := _calc_player_damage(base)
			if s["enemy_hu_ti"] > 0:
				var bonus: int = 8 if not upgraded else 12
				dmg += bonus
				_log("  目标有护体，额外 +%d 伤害" % bonus)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1

		_:
			push_warning("BattleEngine: 未实现效果的卡牌 id = " + id)


# ── 牌库管理 ──────────────────────────────────────────────────────

func _draw_cards(count: int) -> void:
	for _i in range(count):
		if s["hand"].size() >= 10:
			_log("  手牌已达上限 (10张)")
			break
		if s["draw_pile"].is_empty():
			_reshuffle_deck()
			if s["draw_pile"].is_empty():
				_log("  牌库已耗尽")
				break
		var card = s["draw_pile"].pop_front()
		s["hand"].append(card)
	_log("  手牌 %d 张" % s["hand"].size())


func _reshuffle_deck() -> void:
	## 抽牌堆归零：弃掉所有手牌 → 与弃牌堆合并洗牌 → 重抽5张
	_log("  ── 牌库归零，洗牌重置 ──")
	for card in s["hand"]:
		s["discard_pile"].append(card)
	s["hand"].clear()
	s["draw_pile"] = s["discard_pile"].duplicate()
	s["discard_pile"].clear()
	s["draw_pile"].shuffle()
	# 重抽5张
	for _i in range(s["hand_size"]):
		if s["draw_pile"].is_empty():
			break
		s["hand"].append(s["draw_pile"].pop_front())


# ── 状态管理 ──────────────────────────────────────────────────────

func _tick_statuses() -> void:
	## 每回合递减有时限的状态（虚弱、裂伤等）
	for key in s["player_statuses"].keys():
		s["player_statuses"][key] -= 1
		if s["player_statuses"][key] <= 0:
			s["player_statuses"].erase(key)
	for key in s["enemy_statuses"].keys():
		s["enemy_statuses"][key] -= 1
		if s["enemy_statuses"][key] <= 0:
			s["enemy_statuses"].erase(key)


func _update_enemy_intent() -> void:
	var actions: Array = s["enemy_data"].get("actions", [])
	if actions.is_empty():
		s["enemy_intent_text"] = "等待"
		return
	var idx: int = s["enemy_action_idx"] % actions.size()
	s["enemy_intent_text"] = actions[idx].get("intent_text", "？")


# ── 战斗结束检测 ──────────────────────────────────────────────────

func _check_battle_end() -> bool:
	if s["enemy_hp"] <= 0:
		s["phase"] = "over"
		s["battle_won"] = true
		_log("══ 战斗胜利 ══")
		GameState.on_battle_won()
		battle_ended.emit(true)
		state_changed.emit()
		return true
	if s["player_hp"] <= 0:
		s["phase"] = "over"
		s["battle_won"] = false
		_log("══ 战斗失败 ══")
		battle_ended.emit(false)
		state_changed.emit()
		return true
	return false


func _log(text: String) -> void:
	Log.info("Battle", text)
	log_added.emit(text)
