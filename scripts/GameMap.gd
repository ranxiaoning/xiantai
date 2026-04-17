## GameMap.gd
extends Control

const BATTLE_SCENE := "res://scenes/Battle.tscn"

@onready var spawn_btn:   Button       = $Map/SpawnNode
@onready var battle_btn:  Button       = $Map/BattleNode
@onready var dialog_panel:PanelContainer = $DialogPanel
@onready var dialog_label:Label        = $DialogPanel/VBox/PadMargin/DialogLabel
@onready var continue_btn:Button       = $DialogPanel/VBox/ContinueBtn
@onready var connector:   Line2D       = $Map/Connector


func _ready() -> void:
	MusicManager.play("map")
	dialog_panel.hide()
	# 战斗节点在出生节点访问前不可交互
	battle_btn.disabled = not GameState.spawn_node_visited
	_refresh_node_visuals()
	Log.info("GameMap", "地图加载完成")


func _refresh_node_visuals() -> void:
	if GameState.spawn_node_visited:
		spawn_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)  # 已访问变灰
	battle_btn.disabled = not GameState.spawn_node_visited


# ── 出生节点 ──────────────────────────────────────────────────────

func _on_spawn_node_pressed() -> void:
	if GameState.spawn_node_visited:
		return
	dialog_label.text = (
		"登仙台的大门轰然洞开。\n\n"
		+ "无尽的杀戮与轮回在等待着你。\n\n"
		+ "你还记得，上一次死在这里的感觉。\n\n"
		+ "但这一次，你的剑更稳了。"
	)
	dialog_panel.show()


func _on_continue_btn_pressed() -> void:
	dialog_panel.hide()
	GameState.spawn_node_visited = true
	_refresh_node_visuals()


# ── 战斗节点 ──────────────────────────────────────────────────────

func _on_battle_node_pressed() -> void:
	GameState.pending_battle_node = "battle_node_01"
	get_tree().change_scene_to_file(BATTLE_SCENE)
