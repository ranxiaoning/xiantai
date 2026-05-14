## TestRewardScreen.gd
## 白盒测试：锁定战斗奖励选卡页的卡槽尺寸、间距与升级预览复选框命中区域。
extends RefCounted

const RewardScreenScene := preload("res://scenes/RewardScreen.tscn")

const CARD_W := 186.0
const CARD_H := 333.0
const CARD_SEPARATION := 170

var _pass_count: int = 0
var _fail_count: int = 0
var _lines: Array[String] = []
var _cur: String = ""


func run_all() -> Dictionary:
	_lines.append("\n[ TestRewardScreen ]")

	_t("test_reward_cards_have_fixed_non_overlapping_slots")
	_t("test_action_row_is_bottom_bar")
	_t("test_upgrade_checkbox_bottom_left_and_not_inside_card_panel")
	_t("test_upgrade_toggle_rebuilds_without_duplicate_slots")
	_t("test_pending_reward_stone_bonus_applies_and_clears")
	_t("test_pending_reward_min_rarity_applies_and_clears")

	_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])
	return {"pass": _pass_count, "fail": _fail_count, "lines": _lines}


func test_reward_cards_have_fixed_non_overlapping_slots() -> void:
	var scene := _make_open_reward_screen()
	var row: HBoxContainer = scene.get_node("CardPanel/CardPanelPad/CardPanelVBox/CardsRow")

	_assert_eq(row.get_child_count(), 3, "奖励选卡：固定显示3个卡槽")
	_assert_eq(row.get_theme_constant("separation"), CARD_SEPARATION, "奖励选卡：卡槽间距为%d，三张牌左右拉开" % CARD_SEPARATION)
	_assert_eq(row.size_flags_vertical, Control.SIZE_SHRINK_CENTER, "奖励选卡：卡牌行不吃满垂直空间，整体位置靠中上")

	for wrapper in row.get_children():
		var wrapper_size: Vector2 = wrapper.custom_minimum_size
		_assert_approx(wrapper_size.x, CARD_W, "奖励选卡：卡槽宽度固定为%.0f" % CARD_W)
		_assert_approx(wrapper_size.y, CARD_H, "奖励选卡：卡槽高度固定")
		_assert_eq(wrapper.size_flags_horizontal, Control.SIZE_SHRINK_CENTER, "奖励选卡：卡槽水平不被容器拉伸")
		_assert_eq(wrapper.size_flags_vertical, Control.SIZE_SHRINK_CENTER, "奖励选卡：卡槽垂直不被容器拉伸")

		_assert_eq(wrapper.get_child_count(), 1, "奖励选卡：卡牌外部不再追加名称 Label")
		var btn: Button = wrapper.get_child(0)
		var card_view: Control = btn.get_child(0)
		_assert_approx(btn.custom_minimum_size.x, CARD_W, "奖励选卡：按钮宽度固定为卡牌宽")
		_assert_approx(btn.custom_minimum_size.y, CARD_H, "奖励选卡：按钮高度固定为卡牌高")
		_assert_eq(card_view.mouse_filter, Control.MOUSE_FILTER_IGNORE, "奖励选卡：CardView 不拦截按钮点击")
		_assert_approx(card_view.custom_minimum_size.x, CARD_W, "奖励选卡：CardView 宽度固定")
		_assert_approx(card_view.custom_minimum_size.y, CARD_H, "奖励选卡：CardView 高度固定")

	scene.free()


func test_action_row_is_bottom_bar() -> void:
	var scene := _make_open_reward_screen()
	var action_row: HBoxContainer = scene.get("_action_row")

	_assert_true(action_row.visible, "奖励选卡：打开选卡页后显示底部按钮栏")
	_assert_true(action_row.get_parent() == scene, "奖励选卡：确定/跳过挂在根节点底部，不覆盖卡牌布局")
	_assert_approx(action_row.anchor_left, 0.5, "奖励选卡：按钮栏水平居中")
	_assert_approx(action_row.anchor_top, 1.0, "奖励选卡：按钮栏锚定底部")
	_assert_approx(action_row.offset_top, -112.0, "奖励选卡：按钮栏放到卡牌下方")
	_assert_eq(action_row.get_theme_constant("separation"), 28, "奖励选卡：底部按钮间距固定")

	scene.free()


func test_upgrade_checkbox_bottom_left_and_not_inside_card_panel() -> void:
	var scene := _make_open_reward_screen()
	var check: CheckBox = scene.get("_upgrade_check")

	_assert_true(check != null, "奖励选卡：存在查看升级复选框")
	_assert_true(check.visible, "奖励选卡：打开选卡页后显示查看升级")
	_assert_true(check.get_parent() == scene, "奖励选卡：查看升级挂在根节点，不参与卡牌面板布局")
	_assert_eq(check.mouse_filter, Control.MOUSE_FILTER_STOP, "奖励选卡：查看升级只拦截自身区域点击")
	_assert_true(check.get_theme_icon("unchecked") != null, "奖励选卡：查看升级未勾选框使用白色边框图标")
	_assert_true(check.get_theme_icon("checked") != null, "奖励选卡：查看升级勾选框使用白色边框图标")
	_assert_approx(check.anchor_left, 0.0, "奖励选卡：查看升级锚定左侧")
	_assert_approx(check.anchor_top, 1.0, "奖励选卡：查看升级锚定底部")
	_assert_approx(check.offset_left, 36.0, "奖励选卡：查看升级位于左下角")
	_assert_approx(check.offset_top, -78.0, "奖励选卡：查看升级位于左下角")

	scene.free()


func test_upgrade_toggle_rebuilds_without_duplicate_slots() -> void:
	var scene := _make_open_reward_screen()
	var row: HBoxContainer = scene.get_node("CardPanel/CardPanelPad/CardPanelVBox/CardsRow")

	scene.call("_on_upgrade_check_toggled", true)
	_assert_eq(row.get_child_count(), 3, "奖励选卡：切换查看升级后仍只有3个卡槽")
	_assert_eq(scene.get("_selected_idx"), -1, "奖励选卡：切换查看升级会清除当前选择")
	var confirm_btn: Button = scene.get("_confirm_btn")
	_assert_true(confirm_btn.disabled, "奖励选卡：切换查看升级后确认按钮禁用")

	scene.free()


func test_pending_reward_stone_bonus_applies_and_clears() -> void:
	GameState.start_run("chen_tian_feng")
	GameState.pending_battle_node_type = "normal"
	GameState.set("pending_reward_stones_bonus", 20)
	GameState.set("pending_reward_min_rarity", "")
	var scene := _make_ready_reward_screen()

	_assert_eq(scene.get("_stone_gain"), 50, "奖励页：下次奖励灵石加成并入结算")
	_assert_eq(GameState.get("pending_reward_stones_bonus"), 0, "奖励页：领取前已清空下次灵石加成")

	scene.free()


func test_pending_reward_min_rarity_applies_and_clears() -> void:
	seed(20260512)
	GameState.start_run("chen_tian_feng")
	GameState.pending_battle_node_type = "normal"
	GameState.set("pending_reward_stones_bonus", 0)
	GameState.set("pending_reward_min_rarity", "地品")
	var scene := _make_ready_reward_screen()
	var offered: Array = scene.get("_offered_cards")
	var has_floor := false
	for card in offered:
		if card is Dictionary and _rarity_rank(str(card.get("rarity", "黄品"))) >= _rarity_rank("地品"):
			has_floor = true
			break

	_assert_eq(str(scene.get("_reward_min_rarity")), "地品", "奖励页：记录本次卡牌奖励最低稀有度")
	_assert_true(has_floor, "奖励页：至少出现 1 张达到保底稀有度的卡")
	_assert_eq(str(GameState.get("pending_reward_min_rarity")), "", "奖励页：清空下次卡牌奖励稀有度保底")

	scene.free()


func _make_open_reward_screen() -> Control:
	var tree := Engine.get_main_loop() as SceneTree
	var root: Window = tree.root
	var scene: Control = RewardScreenScene.instantiate()
	root.add_child(scene)

	scene.set("_card_panel", scene.get_node("CardPanel"))
	scene.set("_cards_row", scene.get_node("CardPanel/CardPanelPad/CardPanelVBox/CardsRow"))
	scene.set("_confirm_btn", scene.get_node("CardPanel/CardPanelPad/CardPanelVBox/ActionRow/ConfirmBtn"))
	scene.set("_skip_btn", scene.get_node("CardPanel/CardPanelPad/CardPanelVBox/ActionRow/SkipBtn"))
	scene.set("_action_row", scene.get_node("CardPanel/CardPanelPad/CardPanelVBox/ActionRow"))
	scene.set("_card_reward_btn", scene.get_node("RewardPopup/PopupPad/PopupVBox/CardRewardBtn"))
	var offered: Array[Dictionary] = [
		CardDatabase.get_card(5),
		CardDatabase.get_card(1),
		CardDatabase.get_card(2),
	]
	scene.set("_offered_cards", offered)
	scene.set("_slots_built", false)
	scene.call("_prepare_action_row_bottom_bar")
	scene.call("_build_upgrade_preview_check")
	scene.call("_on_card_reward_btn_pressed")
	return scene


func _make_ready_reward_screen() -> Control:
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


func _rarity_rank(rarity: String) -> int:
	match rarity:
		"玄品": return 1
		"地品": return 2
		"天品": return 3
		_: return 0


func _t(method: String) -> void:
	_cur = method
	call(method)


func _assert_true(value: bool, label: String) -> void:
	if value:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s" % label)


func _assert_eq(a, b, label: String) -> void:
	if a == b:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 期望 %s，实际 %s" % [label, str(b), str(a)])


func _assert_approx(a: float, b: float, label: String, eps: float = 0.01) -> void:
	if absf(a - b) <= eps:
		_pass_count += 1
		_lines.append("  ✓ %s" % label)
	else:
		_fail_count += 1
		_lines.append("  ✗ %s  ← 期望 %.2f，实际 %.2f" % [label, b, a])
