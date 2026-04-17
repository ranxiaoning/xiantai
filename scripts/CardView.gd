## CardView.gd — 手牌中的单张卡牌显示节点
##
## 悬停时从底部中心缩放至 1.1×（立体抬起感），同时发出 hovered 信号供
## BattleScene 展示全卡预览。点击时发出 activated 信号。
extends Control

signal hovered(card_data: Dictionary, card_global_rect: Rect2)
signal unhovered
signal activated(card_data: Dictionary)

const HOVER_SCALE  := Vector2(1.1, 1.1)
const NORMAL_SCALE := Vector2.ONE
const ANIM_SECS    := 0.10

var card_data: Dictionary
var _disabled: bool = false
var _tween: Tween

@onready var _art:    TextureRect = $Art
@onready var _dimmer: ColorRect   = $Dimmer


func setup(data: Dictionary, texture: Texture2D, disabled: bool) -> void:
	card_data = data
	_disabled  = disabled
	# @onready 在 add_child 后才初始化，这里用 $ 直接访问（实例化后立即可用）
	if texture != null:
		$Art.texture = texture
	$Dimmer.visible = disabled


func _ready() -> void:
	# 从底部中心缩放，卡牌向上"抬起"而非向四周扩散
	pivot_offset = Vector2(custom_minimum_size.x * 0.5, custom_minimum_size.y)
	mouse_entered.connect(_on_entered)
	mouse_exited.connect(_on_exited)


func _on_entered() -> void:
	z_index = 10
	_animate(HOVER_SCALE)
	hovered.emit(card_data, get_global_rect())


func _on_exited() -> void:
	z_index = 0
	_animate(NORMAL_SCALE)
	unhovered.emit()


func _gui_input(event: InputEvent) -> void:
	if _disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		activated.emit(card_data)


func _animate(to_scale: Vector2) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	_tween.tween_property(self, "scale", to_scale, ANIM_SECS)
