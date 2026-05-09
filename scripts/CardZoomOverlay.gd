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
	# 1. 显式强制全屏布局，防止尺寸为 0
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = 2
	grow_vertical = 2
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 250
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	_shade = ColorRect.new()
	# 2. 内部遮罩也必须强制全屏
	_shade.anchor_right = 1.0
	_shade.anchor_bottom = 1.0
	_shade.offset_right = 0
	_shade.offset_bottom = 0
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.gui_input.connect(_on_close_input)
	
	# 3. 超高质量 Poisson Disk 采样虚化 Shader
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float blur_strength : hint_range(0.0, 15.0) = 0.0;
uniform float darken_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = vec3(0.0);
	float total_weight = 0.0;
	
	// 高强度螺旋采样，确保背景彻底模糊
	if (blur_strength > 0.01) {
		for (float i = 0.0; i < 32.0; i += 1.0) {
			float angle = i * 2.39996; // 黄金角
			float r = sqrt(i) * blur_strength * 0.001;
			vec2 offset = vec2(cos(angle), sin(angle)) * r;
			col += texture(screen_texture, uv + offset).rgb;
			total_weight += 1.0;
		}
		col /= total_weight;
	} else {
		col = texture(screen_texture, uv).rgb;
	}
	
	COLOR = vec4(mix(col, vec3(0.0), darken_amount), 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_shade.material = mat
	add_child(_shade)

	_renderer = CardRendererScript.new()
	_renderer.mouse_filter = Control.MOUSE_FILTER_STOP
	_renderer.gui_input.connect(_on_close_input)
	add_child(_renderer)

	resized.connect(_layout_card)


func show_card(card_data: Dictionary, description_override: String = "", source_rect: Rect2 = Rect2(), description_segments_override: Array = []) -> void:
	_kill_tween()
	_is_closing = false
	show()
	_source_rect = source_rect
	_target_rect = _get_target_rect()
	_renderer.setup(card_data, description_override, description_segments_override)
	
	# 初始化：无虚化，卡牌全透明
	(_shade.material as ShaderMaterial).set_shader_parameter("blur_strength", 0.0)
	(_shade.material as ShaderMaterial).set_shader_parameter("darken_amount", 0.0)
	_renderer.modulate.a = 0.0
	
	if _source_rect.size.x > 1.0 and _source_rect.size.y > 1.0:
		_renderer.position = _source_rect.position
		_renderer.size = _source_rect.size
	else:
		_renderer.position = _target_rect.get_center() - _target_rect.size * 0.2
		_renderer.size = _target_rect.size * 0.4
	_renderer.pivot_offset = _renderer.size * 0.5

	_tween = create_tween().set_parallel(true)
	var duration := 0.5 # 延长至 0.5s，真正的“慢慢放大”
	
	# 极大幅度增加虚化强度 (12.0)
	_tween.tween_property(_shade.material, "shader_parameter/blur_strength", 12.0, duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_shade.material, "shader_parameter/darken_amount", 0.45, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 卡牌缩放动画
	_tween.tween_property(_renderer, "position", _target_rect.position, duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_renderer, "size", _target_rect.size, duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_renderer, "modulate:a", 1.0, duration * 0.5)


func hide_card() -> void:
	if not visible or _is_closing:
		return
	_is_closing = true
	_kill_tween()
	
	var duration := 0.38
	var close_pos := _target_rect.get_center() - _target_rect.size * 0.4
	var close_size := _target_rect.size * 0.8
	
	if _source_rect.size.x > 1.0 and _source_rect.size.y > 1.0:
		close_pos = _source_rect.position
		close_size = _source_rect.size
	
	_tween = create_tween().set_parallel(true)
	# 还原效果
	_tween.tween_property(_shade.material, "shader_parameter/blur_strength", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(_shade.material, "shader_parameter/darken_amount", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	_tween.tween_property(_renderer, "position", close_pos, duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	_tween.tween_property(_renderer, "size", close_size, duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	_tween.tween_property(_renderer, "modulate:a", 0.0, duration * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
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
