## ShopScene.gd
## Full-screen black market scene: card, item, artifact purchases and deck services.
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"
const CardViewScene := preload("res://scenes/CardView.tscn")
const CardRendererScript = preload("res://scripts/CardRenderer.gd")

const CARD_SIZE := Vector2(122, 218)
const CARD_ASPECT := 2752.0 / 1536.0
const UPGRADE_COLS := 5
const UPGRADE_H_SEP := 10
const COLOR_BG := Color(0.045, 0.055, 0.065, 1.0)
const COLOR_PANEL := Color(0.10, 0.095, 0.085, 0.88)
const COLOR_PANEL_LIGHT := Color(0.16, 0.135, 0.095, 0.92)
const COLOR_BORDER := Color(0.72, 0.54, 0.22, 0.75)
const COLOR_TEXT := Color(0.94, 0.90, 0.78, 1.0)
const COLOR_MUTED := Color(0.72, 0.76, 0.78, 1.0)
const COLOR_PRICE := Color(0.96, 0.75, 0.32, 1.0)

var _stock: Dictionary = {"cards": [], "items": [], "artifacts": []}
var _root_vbox: VBoxContainer = null
var _stone_label: Label = null
var _message_label: Label = null
var _overlay: Control = null
var _remove_used_this_visit := false
var _shop_upgrade_overlay: Control = null
var _shop_upgrade_renderer = null
var _shop_upgrade_confirm_btn: Button = null
var _shop_upgrade_index: int = -1
var _shop_upgrade_price: int = 0


func _ready() -> void:
	MusicManager.play("map")
	if GameState.map_floors.is_empty():
		GameState.start_run("chen_tian_feng")
	_roll_stock()
	_build_ui()


func _roll_stock() -> void:
	var floor: int = maxi(maxi(GameState.pending_battle_node_floor, GameState.map_current_floor), 1)
	var seed: int = int(Time.get_ticks_msec() % 2147483647)
	_stock = ShopDatabase.generate_stock(floor, _get_owned_artifact_ids(), seed)


func _get_owned_artifact_ids() -> Array:
	var ids: Array = []
	for artifact in GameState.artifacts:
		if artifact is Dictionary:
			ids.append(str(artifact.get("id", "")))
	return ids


func _build_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_overlay = null

	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_root_vbox = VBoxContainer.new()
	_root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_vbox.add_theme_constant_override("separation", 12)
	_root_vbox.offset_left = 24.0
	_root_vbox.offset_top = 18.0
	_root_vbox.offset_right = -24.0
	_root_vbox.offset_bottom = -18.0
	add_child(_root_vbox)

	_build_header()
	_build_main_stock()
	_build_services()
	_build_message_bar()
	_refresh_affordability()


func _build_header() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	_root_vbox.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := Label.new()
	title.text = "黑市"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "买走想要的，留下承受不起的。"
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", COLOR_MUTED)
	title_box.add_child(subtitle)

	_stone_label = Label.new()
	_stone_label.custom_minimum_size = Vector2(130, 40)
	_stone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stone_label.add_theme_font_size_override("font_size", 24)
	_stone_label.add_theme_color_override("font_color", COLOR_PRICE)
	header.add_child(_stone_label)
	_update_stone_label()

	var return_btn := Button.new()
	return_btn.text = "返回地图"
	return_btn.custom_minimum_size = Vector2(120, 40)
	return_btn.focus_mode = Control.FOCUS_NONE
	return_btn.add_theme_stylebox_override("normal", _button_style(false))
	return_btn.add_theme_stylebox_override("hover", _button_style(true))
	return_btn.pressed.connect(_return_to_map)
	header.add_child(return_btn)


func _build_main_stock() -> void:
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 14)
	_root_vbox.add_child(main)

	main.add_child(_build_cards_column())
	main.add_child(_build_items_column())
	main.add_child(_build_artifacts_column())


func _build_cards_column() -> Control:
	var column := _section_panel("卡牌", "三张随机功法，购入后直接加入牌组。")
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body: VBoxContainer = column.get_meta("body")

	var stock_cards: Array = _stock.get("cards", [])
	if stock_cards.is_empty():
		body.add_child(_muted_label("货架已空。"))
		return column

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	body.add_child(row)

	for card in stock_cards:
		if not (card is Dictionary):
			continue
		row.add_child(_build_card_offer(card))
	return column


func _build_card_offer(card: Dictionary) -> Control:
	var wrap := VBoxContainer.new()
	wrap.custom_minimum_size = Vector2(CARD_SIZE.x + 18.0, 0)
	wrap.add_theme_constant_override("separation", 8)

	var view: Control = CardViewScene.instantiate()
	view.custom_minimum_size = CARD_SIZE
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	view.setup(card, null, false)
	view.set_hover_motion_enabled(false)
	wrap.add_child(view)

	var price: int = _discounted_price(ShopDatabase.get_card_price(card))
	var btn := _buy_button(price)
	btn.text = "购买  %d" % price
	btn.disabled = GameState.spirit_stones < price
	btn.pressed.connect(_buy_card.bind(str(card.get("id", "")), price))
	wrap.add_child(btn)
	return wrap


func _build_items_column() -> Control:
	var column := _section_panel("物品", "丹药可在地图使用；阵法激活后保留；符箓先入包。")
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body: VBoxContainer = column.get_meta("body")

	var stock_items: Array = _stock.get("items", [])
	if stock_items.is_empty():
		body.add_child(_muted_label("货架已空。"))
		return column

	for item in stock_items:
		if item is Dictionary:
			body.add_child(_build_item_offer(item))
	return column


func _build_item_offer(item: Dictionary) -> Control:
	var panel := _offer_panel()
	var pad: MarginContainer = panel.get_meta("pad")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	pad.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	box.add_child(top)

	var name := Label.new()
	name.text = "%s  ·  %s" % [item.get("name", ""), ShopDatabase.get_category_label(str(item.get("category", "")))]
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.add_theme_font_size_override("font_size", 17)
	name.add_theme_color_override("font_color", COLOR_TEXT)
	top.add_child(name)

	var rarity := Label.new()
	rarity.text = ShopDatabase.get_rarity_label(str(item.get("rarity", "yellow")))
	rarity.add_theme_font_size_override("font_size", 13)
	rarity.add_theme_color_override("font_color", COLOR_PRICE)
	top.add_child(rarity)

	var desc := _muted_label(str(item.get("effect_desc", "")))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)

	var price: int = _discounted_price(int(item.get("price", 0)))
	var btn := _buy_button(price)
	btn.text = "购买  %d" % price
	btn.disabled = GameState.spirit_stones < price or GameState.consumables.size() >= GameState.BAG_CAPACITY
	btn.pressed.connect(_buy_item.bind(item, price))
	box.add_child(btn)
	return panel


func _build_artifacts_column() -> Control:
	var column := _section_panel("宝物", "V1 完成购买与持有，战斗触发后续接入。")
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body: VBoxContainer = column.get_meta("body")

	var stock_artifacts: Array = _stock.get("artifacts", [])
	if stock_artifacts.is_empty():
		body.add_child(_muted_label("没有新的宝物愿意现身。"))
		return column

	for artifact in stock_artifacts:
		if artifact is Dictionary:
			body.add_child(_build_artifact_offer(artifact))
	return column


func _build_artifact_offer(artifact: Dictionary) -> Control:
	var panel := _offer_panel()
	var pad: MarginContainer = panel.get_meta("pad")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	pad.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	box.add_child(top)

	var name := Label.new()
	name.text = "%s  ·  %s" % [artifact.get("name", ""), ShopDatabase.get_rarity_label(str(artifact.get("rarity", "yellow")))]
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.add_theme_font_size_override("font_size", 17)
	name.add_theme_color_override("font_color", COLOR_TEXT)
	top.add_child(name)

	var kind := Label.new()
	kind.text = str(artifact.get("type", "passive"))
	kind.add_theme_font_size_override("font_size", 13)
	kind.add_theme_color_override("font_color", COLOR_MUTED)
	top.add_child(kind)

	var desc := _muted_label(str(artifact.get("effect_desc", "")))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)

	var price: int = _discounted_price(int(artifact.get("price", 0)))
	var btn := _buy_button(price)
	btn.text = "购买  %d" % price
	btn.disabled = GameState.spirit_stones < price
	btn.pressed.connect(_buy_artifact.bind(artifact, price))
	box.add_child(btn)
	return panel


func _build_services() -> void:
	var service_panel := PanelContainer.new()
	service_panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL_LIGHT, COLOR_BORDER))
	_root_vbox.add_child(service_panel)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	service_panel.add_child(pad)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	pad.add_child(row)

	var title := Label.new()
	title.text = "黑市服务"
	title.custom_minimum_size = Vector2(120, 0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(title)

	var remove_price := _discounted_price(ShopDatabase.get_remove_price(GameState.shop_remove_service_uses))
	var remove_btn := _service_button("删除卡牌  %d" % remove_price)
	remove_btn.disabled = _remove_used_this_visit or GameState.deck.size() <= 1 or GameState.spirit_stones < remove_price
	remove_btn.tooltip_text = "每次进入黑市最多删除 1 张。"
	remove_btn.pressed.connect(_open_deck_service.bind("remove"))
	row.add_child(remove_btn)

	var upgrade_btn := _service_button("升级卡牌")
	upgrade_btn.disabled = not _has_upgrade_target()
	upgrade_btn.tooltip_text = "选择一张未升级卡牌，费用按稀有度计算。"
	upgrade_btn.pressed.connect(_open_deck_service.bind("upgrade"))
	row.add_child(upgrade_btn)

	var hint := _muted_label("删牌费用随本局次数递增；升级后的卡牌 id 追加 +。")
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(hint)


func _build_message_bar() -> void:
	_message_label = Label.new()
	_message_label.text = "黑市不赊账。"
	_message_label.add_theme_font_size_override("font_size", 14)
	_message_label.add_theme_color_override("font_color", COLOR_MUTED)
	_root_vbox.add_child(_message_label)


func _section_panel(title: String, subtitle: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, COLOR_BORDER))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(pad)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	pad.add_child(body)
	panel.set_meta("body", body)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	body.add_child(title_label)

	var subtitle_label := _muted_label(subtitle)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(subtitle_label)

	var sep := HSeparator.new()
	body.add_child(sep)
	return panel


func _offer_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.045, 0.05, 0.42), Color(0.34, 0.28, 0.14, 0.55)))
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(pad)
	panel.set_meta("pad", pad)
	return panel


func _muted_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", COLOR_MUTED)
	return label


func _buy_button(price: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 32)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _button_style(false))
	btn.add_theme_stylebox_override("hover", _button_style(true))
	btn.add_theme_stylebox_override("disabled", _button_style(false, true))
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.55, 1.0))
	btn.tooltip_text = "需要 %d 灵石" % price
	return btn


func _service_button(text: String) -> Button:
	var btn := _buy_button(0)
	btn.text = text
	btn.custom_minimum_size = Vector2(150, 36)
	return btn


func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	return s


func _button_style(hovered: bool, disabled: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.19, 0.16, 0.10, 0.88) if not hovered else Color(0.28, 0.21, 0.10, 0.95)
	if disabled:
		s.bg_color = Color(0.09, 0.09, 0.09, 0.75)
	s.border_color = Color(0.72, 0.54, 0.22, 0.78)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 5
	s.corner_radius_top_right = 5
	s.corner_radius_bottom_left = 5
	s.corner_radius_bottom_right = 5
	return s


func _buy_card(card_id: String, price: int) -> void:
	if GameState.buy_shop_card(card_id, price):
		_remove_stock_entry("cards", card_id)
		_rebuild_after_action("已购入卡牌。")
	else:
		_set_message("灵石不足，或卡牌已不可购买。")


func _buy_item(item: Dictionary, price: int) -> void:
	if GameState.buy_shop_item(item, price):
		_remove_stock_entry("items", str(item.get("id", "")))
		_rebuild_after_action("物品已入包。")
	else:
		_set_message("灵石不足，或背包已满。")


func _buy_artifact(artifact: Dictionary, price: int) -> void:
	if GameState.buy_shop_artifact(artifact, price):
		_remove_stock_entry("artifacts", str(artifact.get("id", "")))
		_rebuild_after_action("宝物已收入囊中。")
	else:
		_set_message("灵石不足，或已持有该宝物。")


func _remove_stock_entry(section: String, id: String) -> void:
	var entries: Array = _stock.get(section, [])
	for i in range(entries.size() - 1, -1, -1):
		var entry = entries[i]
		if entry is Dictionary and str(entry.get("id", "")) == id:
			entries.remove_at(i)
			break
	_stock[section] = entries


func _rebuild_after_action(message: String) -> void:
	_build_ui()
	_set_message(message)


func _update_stone_label() -> void:
	if _stone_label:
		_stone_label.text = "灵石  %d" % GameState.spirit_stones


func _refresh_affordability() -> void:
	_update_stone_label()


func _set_message(message: String) -> void:
	if _message_label:
		_message_label.text = message


func _has_upgrade_target() -> bool:
	for card_id in GameState.deck:
		if not str(card_id).ends_with("+"):
			var card := CardDatabase.get_card(card_id)
			if not card.is_empty() and GameState.spirit_stones >= _discounted_price(ShopDatabase.get_upgrade_price(card_id)):
				return true
	return false


func _open_deck_service(mode: String) -> void:
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_shop_upgrade_overlay = null
	_shop_upgrade_renderer = null
	_shop_upgrade_confirm_btn = null

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.z_index = 100
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.68)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)

	var vp := get_viewport_rect().size
	var panel_w: float
	var panel_h: float
	if mode == "upgrade":
		panel_w = minf(vp.x * 0.90, 1100.0)
		panel_h = minf(vp.y * 0.88, 700.0)
	else:
		panel_w = 820.0
		panel_h = 560.0

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.075, 0.07, 0.065, 0.98), COLOR_BORDER))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.offset_left = -panel_w * 0.5
	panel.offset_top = -panel_h * 0.5
	panel.offset_right = panel_w * 0.5
	panel.offset_bottom = panel_h * 0.5
	_overlay.add_child(panel)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_right", 18)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(pad)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	pad.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	box.add_child(top)

	var title := Label.new()
	title.text = "选择要删除的卡牌" if mode == "remove" else "选择要升级的卡牌"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	top.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(90, 34)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_stylebox_override("normal", _button_style(false))
	close_btn.add_theme_stylebox_override("hover", _button_style(true))
	close_btn.pressed.connect(_close_overlay)
	top.add_child(close_btn)

	if mode == "upgrade":
		var hint := _muted_label("点击卡牌预览升级效果并确认。已升级或灵石不足的卡牌已置灰。")
		box.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	var card_w: int = int((panel_w - 52.0 - UPGRADE_H_SEP * (UPGRADE_COLS - 1)) / float(UPGRADE_COLS))
	var cols := UPGRADE_COLS if mode == "upgrade" else 4
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", UPGRADE_H_SEP)
	grid.add_theme_constant_override("v_separation", UPGRADE_H_SEP)
	scroll.add_child(grid)

	for i in range(GameState.deck.size()):
		var card_id := str(GameState.deck[i])
		var card := CardDatabase.get_card(card_id)
		if card.is_empty():
			continue
		if mode == "upgrade":
			grid.add_child(_build_upgrade_card_slot(i, card_id, card, card_w))
		else:
			grid.add_child(_build_deck_choice_button(mode, i, card_id, card))

	if mode == "upgrade":
		_build_shop_upgrade_preview_overlay()


func _build_upgrade_card_slot(index: int, card_id: String, card: Dictionary, card_w: int) -> Control:
	var card_h := int(card_w * CARD_ASPECT)
	var already_upgraded := card_id.ends_with("+")
	var upgrade_price := _discounted_price(ShopDatabase.get_upgrade_price(card_id))
	var can_afford := GameState.spirit_stones >= upgrade_price

	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 4)
	wrap.custom_minimum_size = Vector2(card_w, 0)

	var view: Control = CardViewScene.instantiate()
	view.custom_minimum_size = Vector2(card_w, card_h)
	view.mouse_filter = Control.MOUSE_FILTER_STOP
	view.set_hover_motion_enabled(false)

	if already_upgraded:
		view.setup(card, null, true)
		view.modulate.a = 0.4
	elif can_afford:
		view.setup(card, null, false)
		view.activated.connect(_on_shop_upgrade_card_clicked.bind(index, upgrade_price))
	else:
		view.setup(card, null, false)
		view.modulate.a = 0.5
	wrap.add_child(view)

	var price_label := Label.new()
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 14)
	if already_upgraded:
		price_label.text = "已升级"
		price_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	elif can_afford:
		price_label.text = "升级  %d ◆" % upgrade_price
		price_label.add_theme_color_override("font_color", COLOR_PRICE)
	else:
		price_label.text = "升级  %d ◆" % upgrade_price
		price_label.add_theme_color_override("font_color", Color(0.65, 0.35, 0.35))
	wrap.add_child(price_label)
	return wrap


func _build_shop_upgrade_preview_overlay() -> void:
	_shop_upgrade_overlay = Control.new()
	_shop_upgrade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop_upgrade_overlay.z_index = 110
	_shop_upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_upgrade_overlay.hide()
	_overlay.add_child(_shop_upgrade_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(_on_shop_upgrade_shade_input)
	_shop_upgrade_overlay.add_child(shade)

	var vp := get_viewport_rect().size
	var card_h := minf(vp.y * 0.68, 580.0)
	var card_w := card_h / CARD_ASPECT
	var card_x := (vp.x - card_w) * 0.5
	var card_y := (vp.y - card_h) * 0.5 - 36.0

	_shop_upgrade_renderer = CardRendererScript.new()
	_shop_upgrade_renderer.position = Vector2(card_x, card_y)
	_shop_upgrade_renderer.size = Vector2(card_w, card_h)
	_shop_upgrade_renderer.mouse_filter = Control.MOUSE_FILTER_STOP
	_shop_upgrade_overlay.add_child(_shop_upgrade_renderer)

	_shop_upgrade_confirm_btn = Button.new()
	_shop_upgrade_confirm_btn.text = "确认升级  0 ◆"
	_shop_upgrade_confirm_btn.focus_mode = Control.FOCUS_NONE
	_shop_upgrade_confirm_btn.custom_minimum_size = Vector2(200, 48)
	_shop_upgrade_confirm_btn.add_theme_font_size_override("font_size", 20)
	_shop_upgrade_confirm_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_shop_upgrade_confirm_btn.position = Vector2((vp.x - 200.0) * 0.5, card_y + card_h + 20.0)
	_shop_upgrade_confirm_btn.pressed.connect(_on_shop_upgrade_confirm)
	_shop_upgrade_overlay.add_child(_shop_upgrade_confirm_btn)


func _on_shop_upgrade_card_clicked(card_data: Dictionary, deck_index: int, price: int) -> void:
	_shop_upgrade_index = deck_index
	_shop_upgrade_price = price
	var upgraded_data := card_data.duplicate(true)
	upgraded_data["is_upgraded"] = true
	_shop_upgrade_renderer.setup(upgraded_data)
	_shop_upgrade_confirm_btn.text = "确认升级  %d ◆" % price
	_shop_upgrade_overlay.show()


func _on_shop_upgrade_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_shop_upgrade_overlay.hide()
		_shop_upgrade_index = -1


func _on_shop_upgrade_confirm() -> void:
	if _shop_upgrade_index < 0:
		return
	_shop_upgrade_overlay.hide()
	_confirm_upgrade_card(_shop_upgrade_index, _shop_upgrade_price)


func _build_deck_choice_button(mode: String, index: int, card_id: String, card: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180, 72)
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = _deck_choice_text(mode, card_id, card)
	btn.add_theme_stylebox_override("normal", _button_style(false))
	btn.add_theme_stylebox_override("hover", _button_style(true))
	btn.add_theme_stylebox_override("disabled", _button_style(false, true))
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.55, 1.0))

	if mode == "remove":
		var price := ShopDatabase.get_remove_price(GameState.shop_remove_service_uses)
		btn.disabled = _remove_used_this_visit or GameState.deck.size() <= 1 or GameState.spirit_stones < price
		btn.pressed.connect(_confirm_remove_card.bind(index, price))
	else:
		var upgrade_price := _discounted_price(ShopDatabase.get_upgrade_price(card_id))
		btn.disabled = card_id.ends_with("+") or GameState.spirit_stones < upgrade_price
		btn.pressed.connect(_confirm_upgrade_card.bind(index, upgrade_price))
	return btn


func _deck_choice_text(mode: String, card_id: String, card: Dictionary) -> String:
	var name := str(card.get("name", card_id))
	if mode == "remove":
		return "%s\n删除  %d" % [name, ShopDatabase.get_remove_price(GameState.shop_remove_service_uses)]
	return "%s%s\n升级  %d" % [
		name,
		"  已升级" if card_id.ends_with("+") else "",
		ShopDatabase.get_upgrade_price(card_id),
	]


func _confirm_remove_card(index: int, price: int) -> void:
	if GameState.remove_deck_card_at(index, price):
		_remove_used_this_visit = true
		_close_overlay()
		_rebuild_after_action("卡牌已删除。")
	else:
		_set_message("无法删除这张卡。")


func _confirm_upgrade_card(index: int, price: int) -> void:
	if GameState.upgrade_deck_card_at(index, price):
		_close_overlay()
		_rebuild_after_action("卡牌已升级。")
	else:
		_set_message("无法升级这张卡。")


func _close_overlay() -> void:
	_shop_upgrade_overlay = null
	_shop_upgrade_renderer = null
	_shop_upgrade_confirm_btn = null
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null


func _discounted_price(base_price: int) -> int:
	var disc := GameState.shop_discount_pct
	if disc > 0.0:
		return maxi(1, int(base_price * (1.0 - disc)))
	return base_price


func _return_to_map() -> void:
	get_tree().change_scene_to_file(GAME_MAP_SCENE)
