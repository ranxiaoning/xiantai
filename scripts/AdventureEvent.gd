## AdventureEvent.gd
## 奇遇节点全屏场景：显示事件叙事、多选项、执行效果、卡牌选择。
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"
const BATTLE_SCENE   := "res://scenes/Battle.tscn"
const CardViewScene  = preload("res://scenes/CardView.tscn")
const MenuUiStyle    = preload("res://scripts/ui/MenuUiStyle.gd")
const SafeNodeUiStyle = preload("res://scripts/ui/SafeNodeUiStyle.gd")
const MAP_BG         = preload("res://assets/bg/map.png")

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

	var bg_tex := TextureRect.new()
	bg_tex.name = "BG"
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.texture = MAP_BG
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg_tex)

	var bg := ColorRect.new()
	bg.name = "EventDim"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.016, 0.010, 0.008, 0.76)
	add_child(bg)

	var panel_w := minf(vp.x * 0.88, 1040.0)
	var panel_h := minf(vp.y * 0.80, 580.0)
	var panel := PanelContainer.new()
	panel.name = "EventPanel"
	SafeNodeUiStyle.apply_modal_panel(panel, "event")
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.offset_left = -panel_w * 0.5
	panel.offset_top = -panel_h * 0.5
	panel.offset_right = panel_w * 0.5
	panel.offset_bottom = panel_h * 0.5
	add_child(panel)

	var pad := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(side, 26)
	for side in ["margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 22)
	panel.add_child(pad)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 14)
	pad.add_child(root_box)

	var title_row := HBoxContainer.new()
	title_row.name = "EventTitleRow"
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root_box.add_child(title_row)

	var title_pill := PanelContainer.new()
	title_pill.name = "EventTitlePill"
	SafeNodeUiStyle.apply_title_pill(title_pill, "red")
	title_row.add_child(title_pill)

	var title_pad := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		title_pad.add_theme_constant_override(side, 18)
	for side in ["margin_top", "margin_bottom"]:
		title_pad.add_theme_constant_override(side, 6)
	title_pill.add_child(title_pad)

	_title_label = Label.new()
	_title_label.text = _event.get("title", "❓ 奇遇")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuUiStyle.apply_heading(_title_label, 30, Color(1.0, 0.88, 0.46, 1.0))
	title_pad.add_child(_title_label)

	var scroll_desc := ScrollContainer.new()
	scroll_desc.name = "EventDescScroll"
	scroll_desc.custom_minimum_size = Vector2(0, 128)
	scroll_desc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_box.add_child(scroll_desc)

	_desc_label = Label.new()
	_desc_label.text = _event.get("desc", "")
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_desc_label.custom_minimum_size = Vector2(panel_w - 64, 0)
	MenuUiStyle.apply_body(_desc_label, 17, Color(0.91, 0.89, 0.82, 0.96))
	scroll_desc.add_child(_desc_label)

	_options_box = VBoxContainer.new()
	_options_box.name = "EventOptionsBox"
	_options_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_options_box.add_theme_constant_override("separation", 10)
	_options_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(_options_box)

	_build_option_buttons()

	_result_panel = PanelContainer.new()
	_result_panel.name = "EventResultPanel"
	SafeNodeUiStyle.apply_result_panel(_result_panel)
	_result_panel.hide()
	root_box.add_child(_result_panel)

	var result_pad := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		result_pad.add_theme_constant_override(side, 14)
	for side in ["margin_top", "margin_bottom"]:
		result_pad.add_theme_constant_override(side, 10)
	_result_panel.add_child(result_pad)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuUiStyle.apply_body(_result_label, 16, Color(1.0, 0.93, 0.66, 0.96))
	result_pad.add_child(_result_label)

	_continue_btn = Button.new()
	_continue_btn.name = "EventContinueBtn"
	_continue_btn.text = "继续前行"
	_continue_btn.focus_mode = Control.FOCUS_NONE
	_continue_btn.custom_minimum_size = Vector2(200, 50)
	_continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	MenuUiStyle.apply_button(_continue_btn, "primary", 20)
	_continue_btn.pressed.connect(_on_continue_pressed)
	_continue_btn.hide()
	root_box.add_child(_continue_btn)

	_build_card_picker()


func _build_option_buttons() -> void:
	var options: Array = _event.get("options", [])
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var btn := Button.new()
		btn.name = "EventOptionBtn%d" % i
		btn.text = opt.get("text", "选项 %d" % (i + 1))
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		MenuUiStyle.apply_button(btn, "secondary", 17)

		var condition: String = opt.get("condition", "")
		if not EventDatabase.check_condition(condition):
			btn.disabled = true
			btn.modulate.a = 0.45
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
			var hint := _condition_hint(condition)
			if not hint.is_empty():
				btn.text = btn.text + "  [%s]" % hint

		btn.pressed.connect(_on_option_clicked.bind(i))
		_options_box.add_child(btn)


func _build_card_picker() -> void:
	var vp := get_viewport_rect().size

	_card_picker = Control.new()
	_card_picker.name = "EventCardPicker"
	_card_picker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card_picker.z_index = 100
	_card_picker.hide()
	add_child(_card_picker)

	var shade := ColorRect.new()
	shade.name = "EventCardPickerScrim"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	SafeNodeUiStyle.apply_scrim(shade, 0.80)
	_card_picker.add_child(shade)

	var panel_w := minf(vp.x * 0.90, 1120.0)
	var panel_h := minf(vp.y * 0.84, 620.0)
	var panel := PanelContainer.new()
	panel.name = "EventCardPickerPanel"
	SafeNodeUiStyle.apply_modal_panel(panel, "event")
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.offset_left = -panel_w * 0.5
	panel.offset_top = -panel_h * 0.5
	panel.offset_right = panel_w * 0.5
	panel.offset_bottom = panel_h * 0.5
	_card_picker.add_child(panel)

	var pad := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(side, 22)
	for side in ["margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 18)
	panel.add_child(pad)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	pad.add_child(box)

	var hint_lbl := Label.new()
	hint_lbl.name = "HintLabel"
	hint_lbl.text = "选择一张卡牌"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuUiStyle.apply_heading(hint_lbl, 24, Color(1.0, 0.88, 0.46, 1.0))
	box.add_child(hint_lbl)

	var scroll := ScrollContainer.new()
	scroll.name = "CardScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

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
			(child as Button).mouse_default_cursor_shape = Control.CURSOR_ARROW

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
	var hint_lbl := _card_picker.find_child("HintLabel", true, false) as Label
	if _card_pick_mode == "remove":
		hint_lbl.text = "选择一张卡牌将其永久移除"
	else:
		hint_lbl.text = "选择一张卡牌将其升级"

	var grid := _card_picker.find_child("CardGrid", true, false) as GridContainer
	# 清空旧内容
	for child in grid.get_children():
		child.queue_free()

	var vp := get_viewport_rect().size
	var picker_w := minf(vp.x * 0.90, 1120.0)
	var card_w := int((picker_w - PAD_X - H_SEP * (COLS - 1)) / float(COLS))
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
		view.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		view.set_hover_motion_enabled(false)
		view.setup(cdata, null, false)
		view.mouse_entered.connect(func() -> void:
			SafeNodeUiStyle.animate_choice_hover(view, true)
		)
		view.mouse_exited.connect(func() -> void:
			SafeNodeUiStyle.animate_choice_hover(view, false)
		)
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
