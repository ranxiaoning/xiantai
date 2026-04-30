## CardZoomOverlay.gd
## Full-screen click-to-close card preview used by deck and pile viewers.
extends Control

const CARD_ASPECT := 2752.0 / 1536.0
const CardRendererScript = preload("res://scripts/CardRenderer.gd")

var _shade: ColorRect
var _renderer
var _tween: Tween
var _is_closing := false
var _source_rect := Rect2()
var _target_rect := Rect2()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 250
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	_shade = ColorRect.new()
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.color = Color(0.0, 0.0, 0.0, 0.68)
	_shade.gui_input.connect(_on_close_input)
	add_child(_shade)

	_renderer = CardRendererScript.new()
	_renderer.mouse_filter = Control.MOUSE_FILTER_STOP
	_renderer.gui_input.connect(_on_close_input)
	add_child(_renderer)

	resized.connect(_layout_card)


func show_card(card_data: Dictionary, description_override: String = "", source_rect: Rect2 = Rect2()) -> void:
	_kill_tween()
	_is_closing = false
	show()
	_source_rect = source_rect
	_target_rect = _get_target_rect()
	_renderer.setup(card_data, description_override)
	_shade.modulate.a = 0.0
	_renderer.modulate.a = 1.0
	if _source_rect.size.x > 1.0 and _source_rect.size.y > 1.0:
		_renderer.position = _source_rect.position
		_renderer.size = _source_rect.size
	else:
		_renderer.position = _target_rect.get_center() - _target_rect.size * 0.44
		_renderer.size = _target_rect.size * 0.88
	_renderer.pivot_offset = _renderer.size * 0.5

	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_shade, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_renderer, "position", _target_rect.position, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_renderer, "size", _target_rect.size, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func hide_card() -> void:
	if not visible or _is_closing:
		return
	_is_closing = true
	_kill_tween()
	_renderer.pivot_offset = _renderer.size * 0.5
	var close_pos := _target_rect.get_center() - _target_rect.size * 0.46
	var close_size := _target_rect.size * 0.92
	if _source_rect.size.x > 1.0 and _source_rect.size.y > 1.0:
		close_pos = _source_rect.position
		close_size = _source_rect.size
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_shade, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(_renderer, "position", close_pos, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_renderer, "size", close_size, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_renderer, "modulate:a", 0.0, 0.12).set_delay(0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_finish_hide)


func _gui_input(event: InputEvent) -> void:
	_on_close_input(event)


func _on_close_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		hide_card()
		accept_event()


func _layout_card() -> void:
	if _renderer == null:
		return
	_target_rect = _get_target_rect()
	if visible and not _is_closing:
		_renderer.position = _target_rect.position
		_renderer.size = _target_rect.size
		_renderer.pivot_offset = _renderer.size * 0.5


func _get_target_rect() -> Rect2:
	var vp := get_viewport_rect().size
	var max_h := maxf(vp.y - 72.0, 240.0)
	var max_w := maxf(vp.x - 72.0, 140.0)
	var card_h := max_h
	if card_h > max_w * CARD_ASPECT:
		card_h = max_w * CARD_ASPECT
	if card_h > 660.0:
		card_h = 660.0
	var card_w := card_h / CARD_ASPECT
	var size := Vector2(card_w, card_h)
	return Rect2((vp - size) * 0.5, size)



func _finish_hide() -> void:
	_is_closing = false
	hide()
	_renderer.scale = Vector2.ONE
	_renderer.modulate.a = 1.0
	_shade.modulate.a = 1.0
	_source_rect = Rect2()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
