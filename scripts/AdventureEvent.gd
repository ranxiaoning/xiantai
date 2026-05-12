## AdventureEvent.gd
## 奇遇节点全屏场景：显示事件叙事、多选项、执行效果、卡牌选择。
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"
const BATTLE_SCENE   := "res://scenes/Battle.tscn"
const CardViewScene  = preload("res://scenes/CardView.tscn")

const CARD_ASPECT := 2752.0 / 1536.0
const COLS        := 5
const H_SEP       := 10
const PAD_X       := 80.0

# ── UI 节点引用（代码构建）───────────────────────────────────────
var _title_label:      Label
var _desc_label:       Label
var _options_box:      VBoxContainer
var _result_panel:     PanelContainer
var _result_label:     Label
var _continue_btn:     Button
var _card_picker:      Control

# ── 状态 ─────────────────────────────────────────────────────────
var _event: Dictionary = {}
var _pending_option: Dictionary = {}        # 待执行的选项（等卡牌选择）
var _card_pick_mode: String = ""            # "remove" | "upgrade"
var _pending_result_parts: Array[String] = []


func _ready() -> void:
	MusicManager.play("map")
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var event_id := GameState.pending_event_id
	_event = EventDatabase.get_event(event_id)
	if _event.is_empty():
		_event = EventDatabase.get_event("Q-101")

	_build_ui()


# ─────────────────────────────────────────────────────────────────
# UI 构建
# ─────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var vp := get_viewport_rect().size

	# 背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.04, 0.02, 0.97)
	add_child(bg)

	# 标题
	_title_label = Label.new()
	_title_label.text = _event.get("title", "❓ 奇遇")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title_label.offset_top    = 16
	_title_label.offset_bottom = 60
	add_child(_title_label)

	# 叙事文本（可滚动）
	var scroll_desc := ScrollContainer.new()
	scroll_desc.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll_desc.offset_top    = 68
	scroll_desc.offset_bottom = 68 + 120
	scroll_desc.offset_left   = PAD_X
	scroll_desc.offset_right  = -PAD_X
	add_child(scroll_desc)

	_desc_label = Label.new()
	_desc_label.text = _event.get("desc", "")
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_desc_label.add_theme_font_size_override("font_size", 17)
	_desc_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.80))
	_desc_label.custom_minimum_size = Vector2(vp.x - PAD_X * 2, 0)
	scroll_desc.add_child(_desc_label)

	# 选项按钮区
	_options_box = VBoxContainer.new()
	_options_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_options_box.add_theme_constant_override("separation", 10)
	_options_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_options_box.offset_top    = 68 + 130
	_options_box.offset_bottom = 68 + 130 + 230
	_options_box.offset_left   = PAD_X
	_options_box.offset_right  = -PAD_X
	add_child(_options_box)

	_build_option_buttons()

	# 结果面板（隐藏）
	_result_panel = PanelContainer.new()
	_result_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_result_panel.offset_top    = 68 + 370
	_result_panel.offset_bottom = 68 + 370 + 90
	_result_panel.offset_left   = PAD_X
	_result_panel.offset_right  = -PAD_X
	_result_panel.hide()
	add_child(_result_panel)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 16)
	_result_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.75))
	_result_panel.add_child(_result_label)

	# 继续前行按钮（隐藏）
	_continue_btn = Button.new()
	_continue_btn.text = "继续前行"
	_continue_btn.focus_mode = Control.FOCUS_NONE
	_continue_btn.custom_minimum_size = Vector2(200, 50)
	_continue_btn.add_theme_font_size_override("font_size", 20)
	_continue_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_continue_btn.offset_left   = (vp.x - 200.0) * 0.5
	_continue_btn.offset_right  = -(vp.x - 200.0) * 0.5
	_continue_btn.offset_top    = -60
	_continue_btn.offset_bottom = -10
	_continue_btn.pressed.connect(_on_continue_pressed)
	_continue_btn.hide()
	add_child(_continue_btn)

	# 卡牌选择覆层（隐藏）
	_build_card_picker()


func _build_option_buttons() -> void:
	var options: Array = _event.get("options", [])
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var btn := Button.new()
		btn.text = opt.get("text", "选项 %d" % (i + 1))
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 17)

		var condition: String = opt.get("condition", "")
		if not EventDatabase.check_condition(condition):
			btn.disabled = true
			btn.modulate.a = 0.45
			var hint := _condition_hint(condition)
			if not hint.is_empty():
				btn.text = btn.text + "  [%s]" % hint

		btn.pressed.connect(_on_option_clicked.bind(i))
		_options_box.add_child(btn)


func _build_card_picker() -> void:
	var vp := get_viewport_rect().size

	_card_picker = Control.new()
	_card_picker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card_picker.z_index = 100
	_card_picker.hide()
	add_child(_card_picker)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.80)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_card_picker.add_child(shade)

	var hint_lbl := Label.new()
	hint_lbl.name = "HintLabel"
	hint_lbl.text = "选择一张卡牌"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 24)
	hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	hint_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint_lbl.offset_top    = 20
	hint_lbl.offset_bottom = 60
	_card_picker.add_child(hint_lbl)

	var scroll := ScrollContainer.new()
	scroll.name = "CardScroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 70
	scroll.offset_bottom = -20
	scroll.offset_left   = PAD_X * 0.5
	scroll.offset_right  = -PAD_X * 0.5
	_card_picker.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "CardGrid"
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", H_SEP)
	grid.add_theme_constant_override("v_separation", H_SEP)
	scroll.add_child(grid)


# ─────────────────────────────────────────────────────────────────
# 事件逻辑
# ─────────────────────────────────────────────────────────────────

func _on_option_clicked(option_index: int) -> void:
	var options: Array = _event.get("options", [])
	if option_index < 0 or option_index >= options.size():
		return
	var opt: Dictionary = options[option_index]

	# 禁用所有按钮，防止重复点击
	for child in _options_box.get_children():
		if child is Button:
			(child as Button).disabled = true

	# 如果效果中包含 card_remove_choose 或 card_upgrade_choose，先显示卡牌选择
	var all_effects: Array = _collect_all_effects(opt)
	var needs_card_pick := false
	for e in all_effects:
		if e.get("type", "") in ["card_remove_choose", "card_upgrade_choose"]:
			needs_card_pick = true
			_card_pick_mode = "upgrade" if e["type"] == "card_upgrade_choose" else "remove"
			break

	if needs_card_pick:
		_pending_option = opt
		_show_card_picker()
	else:
		_execute_option(opt)


func _collect_all_effects(opt: Dictionary) -> Array:
	var result: Array = []
	result.append_array(opt.get("pre_effects", []))
	result.append_array(opt.get("effects", []))
	for outcome in opt.get("random_outcomes", []):
		result.append_array(outcome.get("effects", []))
	return result


func _execute_option(opt: Dictionary) -> void:
	var parts: Array[String] = []

	# 先执行 pre_effects（必定执行，不受随机影响）
	for e in opt.get("pre_effects", []):
		parts.append_array(_apply_single_effect(e))

	# 判断是否随机分支
	if opt.get("random", false):
		var outcomes: Array = opt.get("random_outcomes", [])
		var outcome := _roll_outcome(outcomes)
		var result_desc: String = outcome.get("result_desc", "")
		if not result_desc.is_empty():
			parts.append(result_desc)
		for e in outcome.get("effects", []):
			# battle_event 会自行切换场景，直接返回
			if e.get("type", "") == "battle_event":
				_trigger_event_battle(e)
				return
			parts.append_array(_apply_single_effect(e))
	else:
		for e in opt.get("effects", []):
			if e.get("type", "") == "battle_event":
				_trigger_event_battle(e)
				return
			parts.append_array(_apply_single_effect(e))

	# 显示 flavor 文本（若有）
	var flavor: String = opt.get("flavor", "")
	if not flavor.is_empty():
		parts.append("\n" + flavor)

	_show_result(parts)


func _roll_outcome(outcomes: Array) -> Dictionary:
	if outcomes.is_empty():
		return {}
	var total := 0
	for o in outcomes:
		total += int(o.get("weight", 0))
	if total <= 0:
		return outcomes[0]
	var roll := randi() % total
	var acc := 0
	for o in outcomes:
		acc += int(o.get("weight", 0))
		if roll < acc:
			return o
	return outcomes[-1]


# ─────────────────────────────────────────────────────────────────
# 效果执行
# ─────────────────────────────────────────────────────────────────

func _apply_single_effect(e: Dictionary) -> Array[String]:
	var msgs: Array[String] = []
	var etype: String = e.get("type", "")

	match etype:
		"stones":
			var n := int(e.get("amount", 0))
			GameState.add_spirit_stones(n)
			msgs.append("获得 %d 灵石" % n)

		"stones_range":
			var n := randi_range(int(e.get("min", 0)), int(e.get("max", 0)))
			GameState.add_spirit_stones(n)
			msgs.append("获得 %d 灵石" % n)

		"stones_spend":
			var n := int(e.get("amount", 0))
			GameState.spend_spirit_stones(n)
			msgs.append("消耗 %d 灵石" % n)

		"heal":
			var n := int(e.get("amount", 0))
			GameState.apply_hp_change(n)
			if n >= 0:
				msgs.append("回复 %d HP" % n)
			else:
				msgs.append("失去 %d HP" % abs(n))

		"heal_pct":
			var pct: float = float(e.get("pct", 0.0))
			var hp_max := int(GameState.character.get("hp_max", 60))
			var n := int(hp_max * abs(pct))
			GameState.apply_hp_change(int(pct * hp_max))
			if pct >= 0:
				msgs.append("回复 %d HP" % n)
			else:
				msgs.append("失去 %d HP" % n)

		"heal_full":
			var hp_max := int(GameState.character.get("hp_max", 60))
			GameState.apply_hp_change(hp_max)
			msgs.append("回复至满血")

		"max_hp_perm":
			var n := int(e.get("amount", 0))
			var old_max := int(GameState.character.get("hp_max", 60))
			var new_max := maxi(1, old_max + n)
			GameState.character["hp_max"] = new_max
			GameState.current_hp = clampi(GameState.current_hp, 0, new_max)
			if n >= 0:
				msgs.append("最大HP永久 +%d" % n)
			else:
				msgs.append("最大HP永久 %d" % n)

		"ling_li_max_perm":
			var n := int(e.get("amount", 0))
			var old_val := int(GameState.character.get("ling_li_max", 20))
			GameState.character["ling_li_max"] = maxi(1, old_val + n)
			if n >= 0:
				msgs.append("灵力上限永久 +%d" % n)
			else:
				msgs.append("灵力上限永久 %d" % n)

		"hp_regen_perm":
			var n := int(e.get("amount", 0))
			GameState.character["hp_regen"] = int(GameState.character.get("hp_regen", 0)) + n
			msgs.append("每战生命回复永久 +%d" % n)

		"perm_shield":
			var n := int(e.get("amount", 0))
			GameState.character["hu_ti"] = int(GameState.character.get("hu_ti", 0)) + n
			msgs.append("永久护体 +%d" % n)

		"dao_xing_start":
			var n := int(e.get("amount", 0))
			GameState.dao_xing_battle_start = maxi(0, GameState.dao_xing_battle_start + n)
			if n >= 0:
				msgs.append("永久初始剑意 +%d" % n)
			else:
				msgs.append("失去 %d 初始剑意" % abs(n))

		"card_random":
			var rarity: String = e.get("rarity", "黄品")
			var subtype: String = e.get("subtype", "")
			var card_id: String = EventDatabase.get_random_card_by_rarity(rarity, subtype)
			if not card_id.is_empty():
				GameState.deck.append(card_id)
				var cdata: Dictionary = CardDatabase.get_card(card_id)
				msgs.append("获得卡牌：%s（%s）" % [cdata.get("name", card_id), rarity])
			else:
				msgs.append("（未能获得卡牌）")

		"card_remove_choose":
			# 此效果由卡牌选择覆层处理，不在此直接执行
			pass

		"card_upgrade_choose":
			# 同上，由覆层处理
			pass

		"artifact_random":
			var rarity: String = e.get("rarity", "yellow")
			var artifact: Dictionary = EventDatabase.get_random_artifact_by_rarity(rarity)
			if not artifact.is_empty():
				GameState.add_artifact(artifact.duplicate(true))
				msgs.append("获得宝物：%s" % artifact.get("name", "宝物"))
			else:
				msgs.append("（未能获得宝物）")

		"artifact_event":
			var art_id: String = e.get("artifact_id", "")
			var artifact: Dictionary = EventDatabase.get_event_artifact(art_id)
			if not artifact.is_empty():
				GameState.add_artifact(artifact)
				msgs.append("获得宝物：%s" % artifact.get("name", "宝物"))

		"consumable_get":
			var item_id: String = e.get("id", "")
			var item: Dictionary = ShopDatabase.get_item_by_id(item_id)
			if not item.is_empty():
				if GameState.add_consumable(item.duplicate(true)):
					msgs.append("获得：%s" % item.get("name", item_id))
				else:
					msgs.append("（背包已满，未能收取 %s）" % item.get("name", item_id))

		"consumable_random":
			var count := int(e.get("count", 1))
			var category: String = e.get("category", "")
			var rarity_filter: String = e.get("rarity_filter", "")
			var added := 0
			for _i in range(count):
				var item: Dictionary = EventDatabase.get_random_consumable(category, rarity_filter)
				if not item.is_empty() and GameState.add_consumable(item.duplicate(true)):
					added += 1
			if added > 0:
				var cat_label := _category_label(category)
				msgs.append("获得 %d 件%s" % [added, cat_label])
			else:
				msgs.append("（背包已满）")

		"consumable_spend_type":
			var category: String = e.get("category", "")
			var count := int(e.get("count", 1))
			var removed := 0
			for k in range(GameState.consumables.size() - 1, -1, -1):
				if removed >= count:
					break
				if GameState.consumables[k].get("category", "") == category:
					GameState.consumables.remove_at(k)
					removed += 1
			msgs.append("消耗 %d 件%s" % [removed, _category_label(category)])

		"curse_card":
			var card_id: String = e.get("card_id", "")
			if not card_id.is_empty():
				GameState.deck.append(card_id)
				msgs.append("牌库塞入了1张【%s】" % _curse_display_name(card_id))

		"battle_event":
			# 由 _trigger_event_battle 处理
			pass

	return msgs


func _trigger_event_battle(e: Dictionary) -> void:
	var enemy_id: String = e.get("enemy_id", "")
	GameState.event_battle_enemy_id = enemy_id
	GameState.pending_battle_node_type = "event_battle"
	# 标记此事件已触发，避免重复
	if not GameState.visited_events.has(_event.get("id", "")):
		GameState.visited_events.append(_event.get("id", ""))
	# 如果事件要求战斗胜利后提供卡牌升级选项，写入 flag
	if e.get("post_upgrade", false):
		GameState.event_chain_flags["post_battle_upgrade"] = true
	get_tree().change_scene_to_file(BATTLE_SCENE)


# ─────────────────────────────────────────────────────────────────
# 卡牌选择覆层
# ─────────────────────────────────────────────────────────────────

func _show_card_picker() -> void:
	var hint_lbl := _card_picker.get_node("HintLabel") as Label
	if _card_pick_mode == "remove":
		hint_lbl.text = "选择一张卡牌将其永久移除"
	else:
		hint_lbl.text = "选择一张卡牌将其升级"

	var grid := _card_picker.get_node("CardScroll/CardGrid") as GridContainer
	# 清空旧内容
	for child in grid.get_children():
		child.queue_free()

	var vp := get_viewport_rect().size
	var card_w := int((vp.x - PAD_X - H_SEP * (COLS - 1)) / float(COLS))
	var card_h := int(card_w * CARD_ASPECT)

	for i in range(GameState.deck.size()):
		var card_id: String = GameState.deck[i]
		var cdata: Dictionary = CardDatabase.get_card(card_id)
		if cdata.is_empty():
			continue
		if _card_pick_mode == "upgrade" and card_id.ends_with("+"):
			continue

		var view: Control = CardViewScene.instantiate()
		view.custom_minimum_size = Vector2(card_w, card_h)
		view.mouse_filter = Control.MOUSE_FILTER_STOP
		view.set_hover_motion_enabled(false)
		view.setup(cdata, null, false)
		view.activated.connect(_on_card_picked.bind(i))
		grid.add_child(view)

	_card_picker.show()


func _on_card_picked(_card_data: Dictionary, deck_index: int) -> void:
	_card_picker.hide()

	var parts: Array[String] = []
	if _card_pick_mode == "remove":
		if deck_index >= 0 and deck_index < GameState.deck.size() and GameState.deck.size() > 1:
			var removed_id: String = GameState.deck[deck_index]
			var cdata: Dictionary = CardDatabase.get_card(removed_id)
			GameState.deck.remove_at(deck_index)
			parts.append("移除了卡牌：%s" % cdata.get("name", removed_id))
	elif _card_pick_mode == "upgrade":
		if deck_index >= 0 and deck_index < GameState.deck.size():
			var base_id := GameState.deck[deck_index].trim_suffix("+")
			GameState.deck[deck_index] = base_id + "+"
			var cdata: Dictionary = CardDatabase.get_card(base_id + "+")
			parts.append("升级了卡牌：%s" % cdata.get("name", base_id))

	# 执行剩余效果（排除 card_remove_choose / card_upgrade_choose）
	var opt := _pending_option
	var all_fx: Array = []
	all_fx.append_array(opt.get("pre_effects", []))
	if opt.get("random", false):
		var outcome := _roll_outcome(opt.get("random_outcomes", []))
		parts.append(outcome.get("result_desc", ""))
		all_fx.append_array(outcome.get("effects", []))
	else:
		all_fx.append_array(opt.get("effects", []))

	for e in all_fx:
		if e.get("type", "") in ["card_remove_choose", "card_upgrade_choose"]:
			continue
		if e.get("type", "") == "battle_event":
			_trigger_event_battle(e)
			return
		parts.append_array(_apply_single_effect(e))

	var flavor: String = opt.get("flavor", "")
	if not flavor.is_empty():
		parts.append("\n" + flavor)

	_pending_option = {}
	_show_result(parts)


# ─────────────────────────────────────────────────────────────────
# 结果显示
# ─────────────────────────────────────────────────────────────────

func _show_result(parts: Array[String]) -> void:
	var filtered: Array[String] = []
	for p in parts:
		var s := p.strip_edges()
		if not s.is_empty():
			filtered.append(s)
	_result_label.text = "\n".join(filtered) if not filtered.is_empty() else "无事发生。"
	_result_panel.show()
	_continue_btn.show()


func _on_continue_pressed() -> void:
	var eid: String = _event.get("id", "")
	if not eid.is_empty() and not GameState.visited_events.has(eid):
		GameState.visited_events.append(eid)
	get_tree().change_scene_to_file(GAME_MAP_SCENE)


# ─────────────────────────────────────────────────────────────────
# 工具方法
# ─────────────────────────────────────────────────────────────────

func _condition_hint(condition: String) -> String:
	if condition.is_empty():
		return ""
	var parts := condition.split(":", false, 2)
	match parts[0]:
		"stones_gte":   return "需要 %s 灵石" % (parts[1] if parts.size() > 1 else "?")
		"has_type":
			match parts[1] if parts.size() > 1 else "":
				"elixir":    return "需要丹药"
				"talisman":  return "需要符箓"
				"formation": return "需要阵法"
		"dao_xing_gte": return "需要道行 ≥ %s" % (parts[1] if parts.size() > 1 else "?")
		"has_non_upgraded": return "需要未升级的卡牌"
		"deck_size_gte": return "需要至少 %s 张卡牌" % (parts[1] if parts.size() > 1 else "?")
	return condition


func _category_label(category: String) -> String:
	match category:
		"elixir":    return "丹药"
		"talisman":  return "符箓"
		"formation": return "阵法"
		_:           return "消耗品"


func _curse_display_name(card_id: String) -> String:
	match card_id:
		"curse_dark_wound": return "暗伤"
		"curse_xin_mo":     return "心魔"
		_:
			var cdata: Dictionary = CardDatabase.get_card(card_id)
			return cdata.get("name", card_id)
