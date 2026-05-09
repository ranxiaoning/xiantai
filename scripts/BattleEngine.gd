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
signal deck_reshuffled(cards: Array)
signal cards_drawn(cards: Array)

const STARTING_HAND_SIZE := 3
const HAND_LIMIT := 10

# ── 战斗状态 ──────────────────────────────────────────────────────
var s: Dictionary = {}   # 全部状态都在这个字典里

var _next_instance_id: int = 1

## 初始化战斗
func init(char_data: Dictionary, deck_ids: Array, enemy_data: Dictionary) -> void:
	var player_hp_max: int = char_data.get("hp_max", 60)
	var player_start_hp := player_hp_max
	if not GameState.character.is_empty() \
			and str(char_data.get("id", "")) == str(GameState.character.get("id", "")):
		player_start_hp = clampi(GameState.current_hp, 1, player_hp_max)
	s = {
		# 玩家
		"player_hp":          player_start_hp,
		"player_hp_max":      player_hp_max,
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
		"hand_size":    STARTING_HAND_SIZE,

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
	_next_instance_id = 1
	for id in deck_ids:
		var card = CardDatabase.get_card(id)
		if not card.is_empty():
			card["_instance_id"] = _next_instance_id
			_next_instance_id += 1
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


## 返回卡牌无法打出的原因文本；可打出时返回空字符串。
func get_play_block_reason(card: Dictionary) -> String:
	if s["phase"] != "player":
		return ""
	var lack_ling: bool = int(s["player_ling_li"]) < card.get("ling_li", 0)
	var lack_dao: bool  = int(s["player_dao_hui"]) < card.get("dao_hui", 0)
	if lack_ling and lack_dao:
		return "灵力不足 · 道慧不足"
	if lack_ling:
		return "灵力不足"
	if lack_dao:
		return "道慧不足"
	return ""


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
	# 玩家状态 tick（在玩家回合结束时递减，确保敌人施加的状态能作用到本回合）
	_tick_player_statuses()
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

	## 每回合开始：处理敌人被动（道行自动叠加等）
	_apply_enemy_passive_start_of_turn()

	## 按 action_cycle 取当前动作索引
	var cycle: Array = enemy_data.get("action_cycle", [])
	var idx: int = 0
	if not cycle.is_empty():
		idx = cycle[s["enemy_action_idx"] % cycle.size()]
	var action: Dictionary = actions[idx].duplicate(true)  # 强制深拷贝，避免 const 只读问题
	s["enemy_action_idx"] += 1

	_log("敌人行动：%s" % action["name"])

	match action.get("type", ""):
		"attack":
			## ── 攻击类 ─────────────────────────────────────
			var base_dmg: int = action.get("damage", 0)
			var hits: int = action.get("hits", 1)  # 连击段数
			base_dmg = _apply_enemy_attack_modifiers(base_dmg)  # 道行加成

			for _h in range(hits):
				var dmg_before_player_hp = s["player_hp"]
				_deal_damage_to_player(base_dmg)
				var hp_lost = dmg_before_player_hp - s["player_hp"]
				## 嗜血被动：造成实际HP伤害时回复50%
				if enemy_data.get("passive_shi_xue", false) and hp_lost > 0:
					var heal: int = maxi(1, floori(hp_lost * 0.5))
					s["enemy_hp"] = min(s["enemy_hp"] + heal, s["enemy_hp_max"])
					_log("  嗜血回复 %d HP（当前%d）" % [heal, s["enemy_hp"]])
				## 深渊吞噬：造成HP伤害时等量回血
				if action.get("heal_self_on_dmg", false) and hp_lost > 0:
					s["enemy_hp"] = min(s["enemy_hp"] + hp_lost, s["enemy_hp_max"])
					_log("  吸血回复 %d HP（当前%d）" % [hp_lost, s["enemy_hp"]])

			## 攻击后自身获得身形（盾击）
			if action.has("self_shield_after"):
				var sh: int = action["self_shield_after"]
				if action.get("self_shield_is_shen_xing", false):
					s["enemy_shen_xing"] = s.get("enemy_shen_xing", 0) + sh
					_log("  获得 %d 身形" % sh)
				else:
					s["enemy_hu_ti"] += sh

			## 攻击附带给玩家的状态（如震慑）
			var ps = action.get("player_status", null)
			if ps != null:
				_apply_player_status_from_action(ps)
			var ps2 = action.get("player_status_2", null)
			if ps2 != null:
				_apply_player_status_from_action(ps2)

			## 攻击附带插入污染牌
			var ic = action.get("insert_card", null)
			if ic != null:
				_insert_curse_card(ic)

		"defend":
			## ── 防守类：敌人获得护体或身形 ──────────────
			var sh: int = action.get("shield", 0)
			if action.get("is_shen_xing", false):
				# 身形（临时格挡，回合结束清零）
				s["enemy_shen_xing"] = s.get("enemy_shen_xing", 0) + sh
				_log("  获得 %d 点身形（临时护盾）" % sh)
			else:
				# 永久护体
				s["enemy_hu_ti"] += sh
				_log("  获得 %d 点护体（共 %d）" % [sh, s["enemy_hu_ti"]])

		"buff":
			## ── 增益类：敌人自身获得状态 ─────────────────
			if action.has("self_status"):
				_apply_enemy_self_status(action["self_status"])
			else:
				_log("  %s（蓄力/无效果）" % action["name"])

		"debuff":
			## ── 减益类：对玩家施加负面状态 ────────────────
			var ps_d = action.get("player_status", null)
			if ps_d != null:
				_apply_player_status_from_action(ps_d)
			## 支持第二个状态字段（const 不支持数组，用 player_status_2 代替）
			var ps_d2 = action.get("player_status_2", null)
			if ps_d2 != null:
				_apply_player_status_from_action(ps_d2)
			## 同时插入污染牌
			var ic_d = action.get("insert_card", null)
			if ic_d != null:
				_insert_curse_card(ic_d)

	if _check_battle_end():
		return

	## 回合结束：清零身形（临时格挡）
	if s.get("enemy_shen_xing", 0) > 0:
		s["enemy_shen_xing"] = 0

	# 敌方状态 tick（在敌方回合结束时递减）
	_tick_enemy_statuses()
	_update_enemy_intent()
	state_changed.emit()
	_start_player_turn()


## ── 敌人被动：回合开始处理 ────────────────────────────────────────
func _apply_enemy_passive_start_of_turn() -> void:
	var enemy_data: Dictionary = s["enemy_data"]
	## 道行自动叠加（远古噬天虫等）
	var dao_per_turn: int = enemy_data.get("passive_dao_xing_per_turn", 0)
	if dao_per_turn > 0:
		s["enemy_dao_xing"] = s.get("enemy_dao_xing", 0) + dao_per_turn
		_log("  敌人被动·道行 +%d（共%d层）" % [dao_per_turn, s["enemy_dao_xing"]])


## ── 敌人攻击修正（含道行加成）────────────────────────────────────
func _apply_enemy_attack_modifiers(base_dmg: int) -> int:
	var dmg: float = base_dmg
	# 敌人道行：每层+1伤害
	var dao_xing: int = s.get("enemy_dao_xing", 0)
	if dao_xing > 0:
		dmg += dao_xing
	# 敌人虚弱：攻击力 -25%
	if s["enemy_statuses"].get("xu_ruo", 0) > 0:
		dmg *= 0.75
	return int(dmg)


## ── 给玩家施加状态（支持单个字典或字典数组）────────────────────────────
func _apply_player_status_from_action(status_data) -> void:
	## status_data 可以是 {"key":..., "stacks":n} 或 [{"key":...},...]
	if status_data is Array:
		for item in status_data:
			_apply_player_status_from_action(item)
	elif status_data is Dictionary:
		var key: String = status_data.get("key", "")
		var stacks: int = status_data.get("stacks", 1)
		if key.is_empty():
			return
		if not s["player_statuses"].has(key):
			s["player_statuses"][key] = 0
		s["player_statuses"][key] += stacks
		_log("  施加玩家状态：%s ×%d（共%d）" % [key, stacks, s["player_statuses"][key]])


## ── 给敌人自身施加状态（道行/荆棘等）───────────────────────────
func _apply_enemy_self_status(status_data: Dictionary) -> void:
	var key: String = status_data["key"]
	var stacks: int = status_data.get("stacks", 1)
	match key:
		"dao_xing":
			s["enemy_dao_xing"] = s.get("enemy_dao_xing", 0) + stacks
			_log("  敌人道行 +%d（共%d层）" % [stacks, s["enemy_dao_xing"]])
		"jing_ci":
			s["enemy_jing_ci"] = s.get("enemy_jing_ci", 0) + stacks
			_log("  敌人荆棘 +%d（共%d层）" % [stacks, s["enemy_jing_ci"]])
		_:
			if not s["enemy_statuses"].has(key):
				s["enemy_statuses"][key] = 0
			s["enemy_statuses"][key] += stacks
			_log("  敌人状态 %s +%d" % [key, stacks])


## ── 插入污染牌到玩家牌库 ─────────────────────────────────────────
func _insert_curse_card(insert_data: Dictionary) -> void:
	var card_id: String = insert_data.get("card_id", "an_shang")
	var target: String  = insert_data.get("target", "discard")
	var curse_card := {
		"id":        card_id,
		"name":      _get_curse_name(card_id),
		"card_type": "curse",
		"keywords":  ["unplayable"],  # 禁锢：不可打出
		"is_curse":  true,
		"_instance_id": _next_instance_id,
	}
	_next_instance_id += 1
	match target:
		"discard":
			s["discard_pile"].append(curse_card)
			_log("  塞入【%s】→ 弃牌堆" % curse_card["name"])
		"draw_top":
			s["draw_pile"].push_front(curse_card)
			_log("  塞入【%s】→ 抽牌堆顶（下回合必抽）" % curse_card["name"])
		"hand":
			if s["hand"].size() < 10:
				s["hand"].append(curse_card)
			_log("  塞入【%s】→ 手牌" % curse_card["name"])


func _get_curse_name(card_id: String) -> String:
	match card_id:
		"an_shang":   return "暗伤"
		"tian_wei":   return "天威"
		"mi_wang":    return "迷惘"
		"ji_sheng":   return "寄生道果"
		"xin_mo":     return "心魔"
		_:            return card_id




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
	s["enemy_hp"] = max(0, s["enemy_hp"] - hp_dmg)
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

	var base := 0
	var dmg := 0
	var shield := 0
	var hits := 0
	var extra := 0
	var bonus_ling := 0
	match id:
		"1":
			base = 14 if upgraded else 9
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
			_draw_cards(1 if upgraded else 1)
		"2":
			base = 10 if upgraded else 6
			dmg = _calc_player_damage(base)
			var hp_before = s["enemy_hp"]
			_deal_damage_to_enemy(dmg)
			if s["enemy_hp"] < hp_before:
				s["player_ling_li"] = min(s["player_ling_li"] + 3, s["player_ling_li_max"])
			s["attack_cards_played_this_turn"] += 1
		"3":
			base = 10 if upgraded else 7
			extra = 4 if upgraded else 3
			base += floor(s["player_ling_li"] / 2.0) * extra
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
		"4":
			base = 2
			hits = 3 if upgraded else 2
			for _i in range(hits):
				dmg = _calc_player_damage(base)
				_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
		"5":
			base = 9 if upgraded else 6
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
		"6":
			base = 7 if upgraded else 5
			hits = 2
			for _i in range(hits):
				dmg = _calc_player_damage(base)
				_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
		"7":
			base = 6 if upgraded else 5
			hits = 5 if upgraded else 4
			for _i in range(hits):
				dmg = _calc_player_damage(base)
				_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
		"8":
			base = 20 if upgraded else 15
			dmg = _calc_player_damage(base)
			if s["enemy_hu_ti"] > 0:
				dmg += 12 if upgraded else 8
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
		"9":
			base = 36 if upgraded else 26
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
		"10":
			base = 9 if upgraded else 6
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
			s["next_turn_dao_xing"] = s.get("next_turn_dao_xing", 0) + (2 if upgraded else 1)
		"11":
			base = 11 if upgraded else 8
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
			if not s["enemy_statuses"].has("lie_shang"):
				s["enemy_statuses"]["lie_shang"] = 0
			s["enemy_statuses"]["lie_shang"] += (3 if upgraded else 2)
		"12":
			base = 14 if upgraded else 10
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
			_draw_cards(3 if upgraded else 2)
		"13":
			base = 30 if upgraded else 20
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
			shield = 15 if upgraded else 10
			_add_player_hu_ti(shield)
			_draw_cards(3 if upgraded else 2)
			s["player_dao_xing"] += 3 if upgraded else 2
		"14":
			base = 5 if upgraded else 4
			hits = 4 if upgraded else 3
			var hp_before = s["enemy_hp"]
			for _i in range(hits):
				dmg = _calc_player_damage(base)
				_deal_damage_to_enemy(dmg)
			if s["enemy_hp"] < hp_before:
				s["ti_gu_draw_turns"] = 3 if upgraded else 2
			s["attack_cards_played_this_turn"] += 1
		"15":
			base = 16 if upgraded else 12
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["delayed_damage"] = s.get("delayed_damage", 0) + (16 if upgraded else 12)
			s["attack_cards_played_this_turn"] += 1
		"16":
			base = 5 if upgraded else 5
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
			if not s["enemy_statuses"].has("ku_jie"):
				s["enemy_statuses"]["ku_jie"] = 0
			s["enemy_statuses"]["ku_jie"] += (3 if upgraded else 2)
		"17":
			base = 16 if upgraded else 12
			dmg = _calc_player_damage(base)
			_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
			_add_player_hu_ti(dmg)
		"18":
			base = 30 if upgraded else 20
			dmg = _calc_player_damage(base)
			if s["enemy_hp"] <= s["enemy_hp_max"] * (0.15 if upgraded else 0.10):
				_deal_damage_to_enemy(99999)
			else:
				_deal_damage_to_enemy(dmg)
			s["attack_cards_played_this_turn"] += 1
		"19":
			base = 1
			hits = 8 if upgraded else 6
			for _i in range(hits):
				dmg = _calc_player_damage(base)
				_deal_damage_to_enemy(dmg)
				s["player_ling_li"] = min(s["player_ling_li"] + 1, s["player_ling_li_max"])
			s["attack_cards_played_this_turn"] += 1
		"20":
			shield = 10 if upgraded else 6
			_add_player_hu_ti(shield)
		"21":
			shield = 12 if upgraded else 8
			_add_player_hu_ti(shield)
			bonus_ling = 4 if upgraded else 3
			s["player_ling_li"] = min(s["player_ling_li"] + bonus_ling, s["player_ling_li_max"])
		"22":
			shield = 9 if upgraded else 6
			_add_player_hu_ti(shield)
			s["player_dao_xing"] += 2 if upgraded else 1
		"23":
			shield = 6 if upgraded else 6
			_add_player_hu_ti(shield)
			s["player_ling_li_regen"] += (3 if upgraded else 2)
		"24":
			_draw_cards(3 if upgraded else 2)
			bonus_ling = 5 if upgraded else 3
			s["player_ling_li"] = min(s["player_ling_li"] + bonus_ling, s["player_ling_li_max"])
		"25":
			var hs = s["hand"].size()
			for card_ in s["hand"]:
				s["discard_pile"].append(card_)
			s["hand"].clear()
			_draw_cards(hs + (2 if upgraded else 1))
		"26":
			shield = 8 if upgraded else 5
			_add_player_hu_ti(shield)
			s["extra_draw_next_turn"] += 1
		"27":
			var found = null
			for i in range(s["discard_pile"].size()-1, -1, -1):
				if s["discard_pile"][i].get("card_type") == "attack":
					found = s["discard_pile"][i]
					s["discard_pile"].remove_at(i)
					break
			if found:
				found["dao_hui_discount"] = 2 if upgraded else 1
				s["hand"].append(found)
		"28":
			shield = 18 if upgraded else 12
			_add_player_hu_ti(shield)
		"29":
			var hs = s["hand"].size()
			for card_ in s["hand"]:
				s["discard_pile"].append(card_)
			s["hand"].clear()
			_add_player_hu_ti(hs * (5 if upgraded else 4))
			_draw_cards(2)
		"30":
			_draw_cards(3 if upgraded else 2)
			if not s["player_statuses"].has("xin_liu"):
				s["player_statuses"]["xin_liu"] = 0
			s["player_statuses"]["xin_liu"] += (3 if upgraded else 2)
		"31":
			shield = 28 if upgraded else 20
			_add_player_hu_ti(shield)
			if not s["player_statuses"].has("bu_qin"):
				s["player_statuses"]["bu_qin"] = 0
			s["player_statuses"]["bu_qin"] += 2
		"32":
			var cost = 3 if upgraded else 4
			while s["player_ling_li"] >= cost:
				s["player_ling_li"] -= cost
				s["player_dao_xing"] += 1
		"33":
			if not s.has("powers_active"):
				s["powers_active"] = []
			s["powers_active"].append({"id": "33", "upgraded": upgraded})
		"34":
			if not s.has("powers_active"):
				s["powers_active"] = []
			s["powers_active"].append({"id": "34", "upgraded": upgraded})
		"35":
			shield = 8 if upgraded else 5
			_add_player_hu_ti(shield)
			if not s.has("powers_active"):
				s["powers_active"] = []
			s["powers_active"].append({"id": "35", "upgraded": upgraded})
		"36":
			_draw_cards(2 if upgraded else 1)
			bonus_ling = 2 if upgraded else 1
			s["player_ling_li"] = min(s["player_ling_li"] + bonus_ling, s["player_ling_li_max"])
			if not s.has("powers_active"):
				s["powers_active"] = []
			s["powers_active"].append({"id": "36", "upgraded": upgraded})
		"37":
			if not s.has("powers_active"):
				s["powers_active"] = []
			s["powers_active"].append({"id": "37", "upgraded": upgraded})
		"38":
			s["player_dao_xing"] += 1 if upgraded else 1
			if not s.has("powers_active"):
				s["powers_active"] = []
			s["powers_active"].append({"id": "38", "upgraded": upgraded})
		_:
			push_warning("BattleEngine: 未实现效果的卡牌 id = " + id)


# ── 牌库管理 ──────────────────────────────────────────────────────

func _draw_cards(count: int) -> void:
	var drawn_cards: Array = []
	var remaining: int = count
	while remaining > 0:
		if s["draw_pile"].is_empty():
			if _reshuffle_deck():
				remaining = int(s["hand_size"])
			else:
				_log("  牌库已耗尽")
				break
		if s["hand"].size() >= HAND_LIMIT:
			_log("  手牌已达上限 (10张)")
			break
		var card = s["draw_pile"].pop_front()
		s["hand"].append(card)
		drawn_cards.append(card)
		remaining -= 1
	_log("  手牌 %d 张" % s["hand"].size())
	if not drawn_cards.is_empty():
		cards_drawn.emit(drawn_cards.duplicate(true))


func _reshuffle_deck() -> bool:
	var cards_to_shuffle: Array = []
	for card in s["hand"]:
		cards_to_shuffle.append(card)
	for card in s["discard_pile"]:
		cards_to_shuffle.append(card)
	if cards_to_shuffle.is_empty():
		return false
	_log("  ── 牌库耗尽：手牌与弃牌洗回抽牌堆，重抽%d张 ──" % s["hand_size"])
	s["draw_pile"] = cards_to_shuffle.duplicate()
	s["hand"].clear()
	s["discard_pile"].clear()
	s["draw_pile"].shuffle()
	deck_reshuffled.emit(cards_to_shuffle.duplicate(true))
	return true


# ── 状态管理 ──────────────────────────────────────────────────────

## 玩家状态 tick：在玩家回合结束时（end_turn）调用
func _tick_player_statuses() -> void:
	for key in s["player_statuses"].keys():
		s["player_statuses"][key] -= 1
		if s["player_statuses"][key] <= 0:
			s["player_statuses"].erase(key)


## 敌方状态 tick：在敌方回合结束时（_enemy_turn 末尾）调用
func _tick_enemy_statuses() -> void:
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
