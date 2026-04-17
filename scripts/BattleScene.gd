## BattleScene.gd
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const _BattleEngineScript = preload("res://scripts/BattleEngine.gd")

var _engine: RefCounted

# ── UI 节点引用 ────────────────────────────────────────────────────
@onready var enemy_name_label:   Label       = %EnemyName
@onready var enemy_hp_bar:       ProgressBar = %EnemyHPBar
@onready var enemy_hp_label:     Label       = %EnemyHPLabel
@onready var enemy_shield_label: Label       = %EnemyShieldLabel
@onready var enemy_intent_label: Label       = %IntentLabel
@onready var enemy_status_label: Label       = %EnemyStatusLabel

@onready var player_hp_bar:      ProgressBar = %HPBar
@onready var player_hp_label:    Label       = %HPLabel
@onready var player_shield_label:Label       = %ShieldLabel
@onready var ling_li_label:      Label       = %LingLiLabel
@onready var dao_hui_label:      Label       = %DaoHuiLabel
@onready var dao_xing_label:     Label       = %DaoXingLabel

@onready var hand_container:     HBoxContainer = %HandContainer
@onready var end_turn_btn:       Button      = %EndTurnBtn
@onready var skill_btn:          Button      = %SkillBtn
@onready var log_label:          Label       = %LogLabel
@onready var result_panel:       PanelContainer = %ResultPanel
@onready var result_label:       Label       = %ResultLabel
@onready var result_btn:         Button      = %ResultBtn

var _log_lines: Array[String] = []


func _ready() -> void:
	MusicManager.play("battle")
	result_panel.hide()
	_init_battle()


func _init_battle() -> void:
	var char_data := GameState.character
	var deck_ids  := GameState.deck
	var enemy_data := EnemyDatabase.get_battle_node_enemy(GameState.pending_battle_node)

	_engine = _BattleEngineScript.new()
	_engine.state_changed.connect(_on_state_changed)
	_engine.log_added.connect(_on_log_added)
	_engine.battle_ended.connect(_on_battle_ended)
	_engine.init(char_data, deck_ids, enemy_data)
	_engine.start_battle()
	_update_ui()


# ── 信号回调 ──────────────────────────────────────────────────────

func _on_state_changed() -> void:
	_update_ui()


func _on_log_added(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > 12:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


func _on_battle_ended(player_won: bool) -> void:
	end_turn_btn.disabled = true
	skill_btn.disabled    = true
	if player_won:
		result_label.text = "战斗胜利！\n\nHP 剩余：%d" % _engine.s["player_hp"]
		result_btn.text   = "返回地图"
	else:
		result_label.text = "你已倒下……\n\n但记忆留存，下次会更强。"
		result_btn.text   = "返回主菜单"
	result_panel.show()


# ── UI 刷新 ──────────────────────────────────────────────────────

func _update_ui() -> void:
	var s: Dictionary = _engine.s

	# 敌人
	enemy_name_label.text   = s["enemy_data"]["name"]
	enemy_hp_bar.max_value  = s["enemy_hp_max"]
	enemy_hp_bar.value      = s["enemy_hp"]
	enemy_hp_label.text     = "HP %d / %d" % [s["enemy_hp"], s["enemy_hp_max"]]
	enemy_shield_label.text = "护体 %d" % s["enemy_hu_ti"] if s["enemy_hu_ti"] > 0 else ""
	enemy_intent_label.text = "意图：" + s["enemy_intent_text"]
	enemy_status_label.text = _format_statuses(s["enemy_statuses"])

	# 玩家
	player_hp_bar.max_value  = s["player_hp_max"]
	player_hp_bar.value      = s["player_hp"]
	player_hp_label.text     = "HP %d / %d" % [s["player_hp"], s["player_hp_max"]]
	player_shield_label.text = "护体 %d" % s["player_hu_ti"]
	ling_li_label.text       = "灵力 %d / %d" % [s["player_ling_li"], s["player_ling_li_max"]]
	dao_hui_label.text       = "道慧 %d / %d" % [s["player_dao_hui"], s["player_dao_hui_max"]]
	dao_xing_label.text      = "道行 %d 层" % s["player_dao_xing"]

	# 按钮状态
	var is_player_turn: bool = (s["phase"] == "player")
	end_turn_btn.disabled = not is_player_turn
	skill_btn.disabled    = not _engine.can_use_skill()
	skill_btn.text        = "剑意凝神\n(道慧%d)" % s["skill_dao_hui_cost"]

	# 手牌
	_update_hand_display()


func _update_hand_display() -> void:
	# 清除旧卡
	for child in hand_container.get_children():
		child.queue_free()

	var s: Dictionary = _engine.s
	for card in s["hand"]:
		var card_btn := _make_card_button(card)
		hand_container.add_child(card_btn)


func _make_card_button(card: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 160)

	var can_play: bool = _engine.can_play_card(card)
	btn.disabled = not can_play

	# 卡牌文字布局
	var cost_color: Color = Color.WHITE if can_play else Color(0.5, 0.5, 0.5)
	btn.text = "%s\n灵%d · 道%d\n\n%s" % [
		card.get("name", "?"),
		card.get("ling_li", 0),
		card.get("dao_hui", 0),
		card.get("desc", ""),
	]

	btn.add_theme_color_override("font_color", cost_color)
	btn.pressed.connect(_on_card_pressed.bind(card))
	return btn


func _format_statuses(statuses: Dictionary) -> String:
	if statuses.is_empty():
		return ""
	var parts: Array[String] = []
	for k in statuses:
		parts.append("%s×%d" % [k, statuses[k]])
	return " ".join(parts)


# ── 按钮回调 ──────────────────────────────────────────────────────

func _on_card_pressed(card: Dictionary) -> void:
	_engine.play_card(card)


func _on_end_turn_pressed() -> void:
	_engine.end_turn()


func _on_skill_btn_pressed() -> void:
	_engine.use_hero_skill()


func _on_result_btn_pressed() -> void:
	if _engine.s["battle_won"]:
		get_tree().change_scene_to_file(GAME_MAP_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
