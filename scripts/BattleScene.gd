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

# 资源不足提示 toast
var _toast_tween:  Tween
var _toast_root:   Control
var _toast_label:  Label

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

@onready var hand_container:      Control        = %HandContainer
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
	_build_toast_layer()
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


# ── Toast 提示层 ─────────────────────────────────────────────────────

func _build_toast_layer() -> void:
	_toast_root = Control.new()
	_toast_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_root.z_index = 25
	_toast_root.hide()
	add_child(_toast_root)

	_toast_label = Label.new()
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 26)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.15))
	_toast_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_toast_label.add_theme_constant_override("shadow_offset_x", 2)
	_toast_label.add_theme_constant_override("shadow_offset_y", 2)
	_toast_label.add_theme_constant_override("shadow_outline_size", 2)
	_toast_label.anchor_left   = 0.0
	_toast_label.anchor_right  = 1.0
	_toast_label.anchor_top    = 0.48
	_toast_label.anchor_bottom = 0.48
	_toast_label.offset_bottom = 40
	_toast_label.grow_vertical = Control.GROW_DIRECTION_END
	_toast_root.add_child(_toast_label)


func _show_toast(text: String) -> void:
	if _toast_tween:
		_toast_tween.kill()
	_toast_label.text = text
	_toast_root.modulate.a = 1.0
	_toast_root.show()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(0.8)
	_toast_tween.tween_property(_toast_root, "modulate:a", 0.0, 0.35)
	_toast_tween.tween_callback(_toast_root.hide)


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
	var s: Dictionary = _engine.s
	var hand_data = s["hand"]
	var current_children = hand_container.get_children()
	
	var available_children = []
	for child in current_children:
		available_children.append(child)
		
	var new_children = []
	
	# 添加新卡并更新全量卡的状态
	for i in range(hand_data.size()):
		var c_data = hand_data[i]
		var view = null
		# 寻址
		for j in range(available_children.size()):
			var child = available_children[j]
			if child.has_method("set_usable") and child.card_data == c_data:
				view = child
				available_children.remove_at(j)
				break
				
		if view == null:
			view = _make_card_view(c_data)
			hand_container.add_child(view)
			view.position = Vector2(hand_container.size.x / 2.0, hand_container.size.y + 200) # 初始在底端中心飞入
			
		view.set_usable(_engine.can_play_card(c_data))
		new_children.append(view)

	# 移除没有匹配到手牌的老卡片
	for child in available_children:
		var t = create_tween()
		t.tween_property(child, "position", child.position + Vector2(0, -100), 0.2)
		t.tween_property(child, "modulate:a", 0.0, 0.2)
		t.tween_callback(child.queue_free)

	# 执行丝滑扇形布局
	if new_children.is_empty():
		return
		
	var count = new_children.size()
	var max_w = hand_container.size.x
	if max_w < 100:
		max_w = 900.0 # 强制初始fallback保证计算正确，避免启动时全部重叠
		
	var card_w = 100.0  # CardView custom_minimum_size
	var sep = 8.0
	
	if count > 5:
		var visual_max = 532.0 
		sep = (visual_max - count * card_w) / (count - 1.0)
		
	var total_w = count * card_w + (count - 1) * sep
	var start_x = (max_w - total_w) / 2.0
	var center_i = (count - 1) / 2.0
	
	for i in range(count):
		var view = new_children[i]
		var t_pos = Vector2(start_x + i * (card_w + sep), 40)
		view.move_to(t_pos, 0.0)


func _make_card_view(card: Dictionary) -> Control:
	var view: Control = CardViewScene.instantiate()
	var can_play: bool = _engine.can_play_card(card)
	var tex: Texture2D = _load_card_texture(card)
	view.setup(card, tex, not can_play)
	view.hovered.connect(_on_card_hovered)
	view.unhovered.connect(_on_card_unhovered)
	view.activated.connect(_on_card_activated)
	view.play_blocked.connect(_on_card_play_blocked)
	return view


# ── 卡牌图片加载 ─────────────────────────────────────────────────

func _load_card_texture(card: Dictionary) -> Texture2D:
	var path: String = _ART_MAP.get(str(card.get("id", "")), "")
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
	var tex := _load_card_texture(card)
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


func _on_card_play_blocked(card: Dictionary) -> void:
	var reason: String = _engine.get_play_block_reason(card)
	if not reason.is_empty():
		_show_toast(reason)


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
