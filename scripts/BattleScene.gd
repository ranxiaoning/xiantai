## BattleScene.gd
extends Control

const GAME_MAP_SCENE := "res://scenes/GameMap.tscn"
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const _BattleEngineScript = preload("res://scripts/BattleEngine.gd")
const CardViewScene       = preload("res://scenes/CardView.tscn")

# card_id → 已生成的卡牌图片路径（目前仅映射初始两张）
const _ART_MAP := {
	"quick_sword_pi_shan": "res://assets/card/generated/05_剑气斩.png",
	"ding_xin_zhou":       "res://assets/card/generated/24_剑气护体.png",
}

# 预览尺寸（与卡牌保持相同宽高比 1536:2752 ≈ 0.558）
const PREVIEW_W := 280
const PREVIEW_H := 502

var _engine: RefCounted

# 预览覆盖层节点（直接挂在 Battle 根节点，不受 ScrollContainer 裁剪）
var _preview_root:  Control
var _preview_image: TextureRect

# ── UI 节点引用 ────────────────────────────────────────────────────
@onready var enemy_name_label:    Label          = %EnemyName
@onready var enemy_hp_bar:        ProgressBar    = %EnemyHPBar
@onready var enemy_hp_label:      Label          = %EnemyHPLabel
@onready var enemy_shield_label:  Label          = %EnemyShieldLabel
@onready var enemy_intent_label:  Label          = %IntentLabel
@onready var enemy_status_label:  Label          = %EnemyStatusLabel

@onready var player_hp_bar:       ProgressBar    = %HPBar
@onready var player_hp_label:     Label          = %HPLabel
@onready var player_shield_label: Label          = %ShieldLabel
@onready var ling_li_label:       Label          = %LingLiLabel
@onready var dao_hui_label:       Label          = %DaoHuiLabel
@onready var dao_xing_label:      Label          = %DaoXingLabel

@onready var hand_container:      HBoxContainer  = %HandContainer
@onready var end_turn_btn:        Button         = %EndTurnBtn
@onready var skill_btn:           Button         = %SkillBtn
@onready var log_label:           Label          = %LogLabel
@onready var result_panel:        PanelContainer = %ResultPanel
@onready var result_label:        Label          = %ResultLabel
@onready var result_btn:          Button         = %ResultBtn

var _log_lines: Array[String] = []


func _ready() -> void:
	MusicManager.play("battle")
	result_panel.hide()
	_build_preview_overlay()
	_init_battle()


# ── 预览覆盖层（代码构建，挂在根节点最顶层）────────────────────────

func _build_preview_overlay() -> void:
	_preview_root = Control.new()
	_preview_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_root.z_index = 20
	_preview_root.hide()
	add_child(_preview_root)

	_preview_image = TextureRect.new()
	_preview_image.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	_preview_image.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	_preview_image.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_image.size           = Vector2(PREVIEW_W, PREVIEW_H)
	_preview_root.add_child(_preview_image)


# ── 战斗初始化 ──────────────────────────────────────────────────────

func _init_battle() -> void:
	var char_data  := GameState.character
	var deck_ids   := GameState.deck
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

	enemy_name_label.text   = s["enemy_data"]["name"]
	enemy_hp_bar.max_value  = s["enemy_hp_max"]
	enemy_hp_bar.value      = s["enemy_hp"]
	enemy_hp_label.text     = "HP %d / %d" % [s["enemy_hp"], s["enemy_hp_max"]]
	enemy_shield_label.text = "护体 %d" % s["enemy_hu_ti"] if s["enemy_hu_ti"] > 0 else ""
	enemy_intent_label.text = "意图：" + s["enemy_intent_text"]
	enemy_status_label.text = _format_statuses(s["enemy_statuses"])

	player_hp_bar.max_value  = s["player_hp_max"]
	player_hp_bar.value      = s["player_hp"]
	player_hp_label.text     = "HP %d / %d" % [s["player_hp"], s["player_hp_max"]]
	player_shield_label.text = "护体 %d" % s["player_hu_ti"]
	ling_li_label.text       = "灵力 %d / %d" % [s["player_ling_li"], s["player_ling_li_max"]]
	dao_hui_label.text       = "道慧 %d / %d" % [s["player_dao_hui"], s["player_dao_hui_max"]]
	dao_xing_label.text      = "道行 %d 层" % s["player_dao_xing"]

	var is_player_turn: bool = (s["phase"] == "player")
	end_turn_btn.disabled = not is_player_turn
	skill_btn.disabled    = not _engine.can_use_skill()
	skill_btn.text        = "剑意凝神\n(道慧%d)" % s["skill_dao_hui_cost"]

	_update_hand_display()


func _update_hand_display() -> void:
	for child in hand_container.get_children():
		child.queue_free()

	var s: Dictionary = _engine.s
	for card in s["hand"]:
		var card_view := _make_card_view(card)
		hand_container.add_child(card_view)


func _make_card_view(card: Dictionary) -> Control:
	var view: Control = CardViewScene.instantiate()
	var can_play: bool = _engine.can_play_card(card)
	var tex: Texture2D = _load_card_texture(card.get("id", ""))
	view.setup(card, tex, not can_play)
	view.hovered.connect(_on_card_hovered)
	view.unhovered.connect(_on_card_unhovered)
	view.activated.connect(_on_card_activated)
	return view


# ── 卡牌图片加载 ─────────────────────────────────────────────────

func _load_card_texture(card_id: String) -> Texture2D:
	var path: String = _ART_MAP.get(card_id, "")
	if path == "":
		return null
	# 优先走 Godot 已导入资源
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	# 降级：直接从文件系统读取（PNG 尚未被 Editor 导入时）
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.load_from_file(abs_path)
	if img:
		return ImageTexture.create_from_image(img)
	push_warning("CardArt: 找不到图片 %s" % abs_path)
	return null


# ── 卡牌悬停预览 ─────────────────────────────────────────────────

func _on_card_hovered(card: Dictionary, card_rect: Rect2) -> void:
	var tex := _load_card_texture(card.get("id", ""))
	if tex == null:
		return

	_preview_image.texture = tex

	# 将预览定位在悬停卡牌正上方，超出屏幕边界时修正
	var vp     := get_viewport_rect()
	var px     := card_rect.get_center().x - PREVIEW_W * 0.5
	var py     := card_rect.position.y - PREVIEW_H - 16.0
	px = clamp(px, 4.0, vp.size.x - PREVIEW_W - 4.0)
	py = max(py, 4.0)
	_preview_image.position = Vector2(px, py)

	_preview_root.show()


func _on_card_unhovered() -> void:
	_preview_root.hide()


func _on_card_activated(card: Dictionary) -> void:
	_preview_root.hide()
	_engine.play_card(card)


# ── 格式化状态词条 ────────────────────────────────────────────────

func _format_statuses(statuses: Dictionary) -> String:
	if statuses.is_empty():
		return ""
	var parts: Array[String] = []
	for k in statuses:
		parts.append("%s×%d" % [k, statuses[k]])
	return " ".join(parts)


# ── 按钮回调 ──────────────────────────────────────────────────────

func _on_end_turn_pressed() -> void:
	_engine.end_turn()


func _on_skill_btn_pressed() -> void:
	_engine.use_hero_skill()


func _on_result_btn_pressed() -> void:
	if _engine.s["battle_won"]:
		get_tree().change_scene_to_file(GAME_MAP_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
