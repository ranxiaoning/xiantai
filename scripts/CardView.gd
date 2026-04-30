## CardView.gd — 手牌中的单张卡牌显示节点
##
## Owns card interaction, hover animation, and disabled state. Visual rendering
## is delegated to CardRenderer so every card surface uses one implementation.
extends Control

signal hovered(card_data: Dictionary, card_global_rect: Rect2)
signal unhovered
signal activated(card_data: Dictionary)
signal play_blocked(card_data: Dictionary)

const HOVER_SCALE  := Vector2(1.06, 1.06)
const NORMAL_SCALE := Vector2.ONE
const ANIM_SECS    := 0.18
const CardRendererScript = preload("res://scripts/CardRenderer.gd")

var card_data: Dictionary
var _disabled: bool = false
var _hover_motion_enabled: bool = true
var _tween: Tween

var anim_pos: Vector2 = Vector2.ZERO
var anim_rot: float = 0.0

@onready var _art: TextureRect = $Art
@onready var _panel: Panel = $Panel
@onready var _dimmer: ColorRect = $Dimmer
var _renderer


func setup(data: Dictionary, _texture: Texture2D, disabled: bool) -> void:
	card_data = data
	_disabled = disabled
	_ensure_renderer()
	_renderer.setup(card_data)
	_dimmer.visible = false


func set_usable(usable: bool) -> void:
	_disabled = not usable
	_dimmer.visible = false


func set_hover_motion_enabled(enabled: bool) -> void:
	_hover_motion_enabled = enabled


func _ready() -> void:
	pivot_offset = Vector2(custom_minimum_size.x * 0.5, custom_minimum_size.y)
	mouse_entered.connect(_on_entered)
	mouse_exited.connect(_on_exited)
	_ensure_renderer()


func _on_entered() -> void:
	if not _hover_motion_enabled:
		return
	z_index = 10
	var to_pos = anim_pos + Vector2(0, -14)
	_animate(HOVER_SCALE, to_pos, 0.0)
	hovered.emit(card_data, get_global_rect())


func _on_exited() -> void:
	if not _hover_motion_enabled:
		return
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
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "scale", to_scale, ANIM_SECS)
	_tween.tween_property(self, "position", to_pos, ANIM_SECS)
	_tween.tween_property(self, "rotation", to_rot, ANIM_SECS)


func move_to(to_pos: Vector2, to_rot: float) -> void:
	anim_pos = to_pos
	anim_rot = to_rot
	_animate(scale, anim_pos, anim_rot)


func _ensure_renderer() -> void:
	if _renderer != null:
		return
	if _art == null:
		_art = $Art
	if _panel == null:
		_panel = $Panel
	if _dimmer == null:
		_dimmer = $Dimmer

	clip_contents = true
	_art.hide()
	_panel.hide()

	_renderer = CardRendererScript.new()
	_renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_renderer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_renderer)
	move_child(_renderer, _dimmer.get_index())
