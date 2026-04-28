## CardView.gd — 手牌中的单张卡牌显示节点
##
## 悬停时从底部中心缩放至 1.1×（立体抬起感），同时发出 hovered 信号供
## BattleScene 展示全卡预览。点击时发出 activated 信号。
extends Control

signal hovered(card_data: Dictionary, card_global_rect: Rect2)
signal unhovered
signal activated(card_data: Dictionary)
signal play_blocked(card_data: Dictionary)

const HOVER_SCALE  := Vector2(1.1, 1.1)
const NORMAL_SCALE := Vector2.ONE
const ANIM_SECS    := 0.10

var card_data: Dictionary
var _disabled: bool = false
var _tween: Tween

var anim_pos: Vector2 = Vector2.ZERO
var anim_rot: float = 0.0

@onready var _art:    TextureRect = $Art
@onready var _dimmer: ColorRect   = $Dimmer


func setup(data: Dictionary, texture: Texture2D, disabled: bool) -> void:
	card_data = data
	_disabled  = disabled
	if texture != null:
		$Art.texture = texture
	$Dimmer.visible = false

func set_usable(usable: bool) -> void:
	_disabled = not usable
	$Dimmer.visible = false


func _ready() -> void:
	pivot_offset = Vector2(custom_minimum_size.x * 0.5, custom_minimum_size.y)
	mouse_entered.connect(_on_entered)
	mouse_exited.connect(_on_exited)


func _on_entered() -> void:
	z_index = 10
	var to_pos = anim_pos + Vector2(0, -20)
	_animate(HOVER_SCALE, to_pos, 0.0)
	hovered.emit(card_data, get_global_rect())


func _on_exited() -> void:
	z_index = 0
	_animate(NORMAL_SCALE, anim_pos, anim_rot)
	unhovered.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _disabled:
			play_blocked.emit(card_data)
		else:
			activated.emit(card_data)


func _animate(to_scale: Vector2, to_pos: Vector2, to_rot: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	_tween.tween_property(self, "scale", to_scale, ANIM_SECS)
	_tween.tween_property(self, "position", to_pos, ANIM_SECS)
	_tween.tween_property(self, "rotation", to_rot, ANIM_SECS)

func move_to(to_pos: Vector2, to_rot: float) -> void:
	anim_pos = to_pos
	anim_rot = to_rot
	_animate(scale, anim_pos, anim_rot)
