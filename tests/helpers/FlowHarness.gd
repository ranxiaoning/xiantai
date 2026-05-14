## FlowHarness.gd
## 测试专用玩家旅程辅助：封装跨场景状态准备，不进入生产代码路径。
extends RefCounted

const BattleEngineScript := preload("res://scripts/BattleEngine.gd")
const RewardScreenScene := preload("res://scenes/RewardScreen.tscn")


func start_new_run(char_id: String = "chen_tian_feng") -> void:
	seed(20260513)
	GameState.start_run(char_id)


func unlock_first_floor() -> void:
	GameState.start_map()


func prepare_single_node_map(node_id: String, node_type: String, floor: int = 1) -> void:
	GameState.map_nodes = {
		node_id: {
			"id": node_id,
			"type": node_type,
			"floor": floor,
			"col": 0,
			"total_cols": 1,
			"next_ids": [],
			"visited": false,
		},
	}
	GameState.map_floors = [[node_id]]
	GameState.map_current_floor = 0
	GameState.map_last_node_id = ""
	GameState.map_started = true
	GameState.map_accessible_ids = [node_id]
	GameState.pending_battle_node_type = ""
	GameState.pending_battle_node_floor = 0
	GameState.pending_event_id = ""


func visit_first_node_of_type(node_type: String) -> String:
	for node_id in GameState.map_accessible_ids:
		if str(GameState.map_nodes.get(node_id, {}).get("type", "")) == node_type:
			GameState.visit_map_node(node_id)
			return str(node_id)
	for node_id in GameState.map_nodes.keys():
		if str(GameState.map_nodes[node_id].get("type", "")) == node_type:
			GameState.visit_map_node(str(node_id))
			return str(node_id)
	return ""


func start_battle_for_pending_node() -> Object:
	var node_type := GameState.pending_battle_node_type
	if node_type.is_empty():
		node_type = "normal"
	var enemy_data: Dictionary = EnemyDatabase.get_enemy_for_node(node_type, GameState.pending_battle_node_floor)
	var engine: Object = BattleEngineScript.new()
	engine.call("init", GameState.character, GameState.deck, enemy_data)
	engine.call("start_battle")
	return engine


func force_win_battle(engine: Object) -> void:
	engine.call("apply_battle_consumable_effect", {"type": "damage", "amount": 9999})


func open_reward_screen() -> Control:
	var tree := Engine.get_main_loop() as SceneTree
	var root: Window = tree.root
	var scene: Control = RewardScreenScene.instantiate()
	root.add_child(scene)
	scene.set("_stones_btn", scene.get_node("RewardPopup/PopupPad/PopupVBox/StonesBtn"))
	scene.set("_card_reward_btn", scene.get_node("RewardPopup/PopupPad/PopupVBox/CardRewardBtn"))
	scene.set("_popup_continue", scene.get_node("RewardPopup/PopupPad/PopupVBox/PopupContinue"))
	scene.set("_card_panel", scene.get_node("CardPanel"))
	scene.set("_cards_row", scene.get_node("CardPanel/CardPanelPad/CardPanelVBox/CardsRow"))
	scene.set("_confirm_btn", scene.get_node("CardPanel/CardPanelPad/CardPanelVBox/ActionRow/ConfirmBtn"))
	scene.set("_skip_btn", scene.get_node("CardPanel/CardPanelPad/CardPanelVBox/ActionRow/SkipBtn"))
	scene.set("_action_row", scene.get_node("CardPanel/CardPanelPad/CardPanelVBox/ActionRow"))
	scene.call("_initialize_reward_screen")
	return scene


func collect_stones_and_continue(reward_screen: Control) -> void:
	reward_screen.call("_on_stones_btn_pressed")


func pick_first_reward_card(reward_screen: Control) -> String:
	reward_screen.call("_on_card_reward_btn_pressed")
	reward_screen.call("_on_card_slot_toggled", 0)
	var offered: Array = reward_screen.get("_offered_cards")
	var picked_id := ""
	if not offered.is_empty() and offered[0] is Dictionary:
		picked_id = str((offered[0] as Dictionary).get("id", ""))
	reward_screen.call("_on_confirm_btn_pressed")
	return picked_id


func skip_card_reward(reward_screen: Control) -> void:
	reward_screen.call("_on_card_reward_btn_pressed")
	reward_screen.call("_on_skip_btn_pressed")


func assert_no_pending_leaks(suite: Object, label: String) -> void:
	assert_no_battle_reward_pending(suite, label)
	suite.call("_assert_eq", GameState.pending_battle_node_type, "", "%s：无战斗节点类型 pending" % label)
	suite.call("_assert_eq", GameState.pending_battle_node_floor, 0, "%s：无战斗节点层数 pending" % label)
	suite.call("_assert_eq", GameState.pending_event_id, "", "%s：无事件 pending" % label)
	suite.call("_assert_eq", (GameState.get("pending_battle_consumable_effects") as Array).size(), 0, "%s：无下场战斗物品 pending" % label)
	suite.call("_assert_eq", GameState.get("pending_shop_discount_pct"), 0.0, "%s：无下次黑市折扣 pending" % label)
	suite.call("_assert_eq", GameState.get("pending_shop_extra_items"), 0, "%s：无下次黑市加货 pending" % label)


func assert_no_battle_reward_pending(suite: Object, label: String) -> void:
	suite.call("_assert_eq", GameState.get("pending_reward_stones_bonus"), 0, "%s：无奖励灵石 pending" % label)
	suite.call("_assert_eq", str(GameState.get("pending_reward_min_rarity")), "", "%s：无奖励稀有度 pending" % label)
