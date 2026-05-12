## CardRenderer.gd
## Unified runtime renderer for card visuals.
##
## Builds a complete card from template.png + art/XX.png + data text. Callers
## provide card data and, optionally, a final description string override.
extends Control

const CARD_BASE_W := 1536.0
const CARD_BASE_H := 2752.0
const SIZE_COST := 128.0
const SIZE_NAME := 95.0
const SIZE_TYPE := 60.0
const SIZE_DESC := 88.0
const CARD_TEMPLATE := preload("res://assets/card/template.png")
const CARD_ART_SOURCE_DIR := "res://assets/card/art/"
const CARD_CORNER_RADIUS_RATIO := 0.085
const CARD_BOTTOM_CORNER_RADIUS_RATIO := 0.14

var _card_data: Dictionary = {}
var _description_override: String = ""
var _description_segments_override: Array = []
var _art_cache: Dictionary = {}
var _rounded_mask_enabled := true
var _mask_style := StyleBoxFlat.new()

var _template: TextureRect
var _art: TextureRect
var _ling_label: Label
var _dao_label: Label
var _name_label: Label
var _type_label: Label
var _desc_label: Label
var _desc_rich_label: RichTextLabel


func _ready() -> void:
	_ensure_layers()
	resized.connect(_on_resized)
	call_deferred("refresh")


func _draw() -> void:
	if not _rounded_mask_enabled:
		return
	_draw_rounded_mask()


func setup(card_data: Dictionary, description_override: String = "", description_segments_override: Array = []) -> void:
	_card_data = card_data
	_description_override = description_override
	_description_segments_override = description_segments_override
	_ensure_layers()
	call_deferred("refresh")


func set_card_data(card_data: Dictionary) -> void:
	_card_data = card_data
	refresh()


func set_description_override(text: String) -> void:
	_description_override = text
	_description_segments_override = []
	refresh()


func set_description_segments_override(segments: Array) -> void:
	_description_segments_override = segments
	_description_override = _segments_to_text(segments)
	refresh()


func set_rounded_mask_enabled(enabled: bool) -> void:
	_rounded_mask_enabled = enabled
	clip_children = CanvasItem.CLIP_CHILDREN_ONLY if enabled else CanvasItem.CLIP_CHILDREN_DISABLED
	queue_redraw()


static func get_corner_radius_for_size(render_size: Vector2) -> int:
	return maxi(1, int(round(minf(render_size.x, render_size.y) * CARD_CORNER_RADIUS_RATIO)))


static func get_bottom_corner_radius_for_size(render_size: Vector2) -> int:
	return maxi(1, int(round(minf(render_size.x, render_size.y) * CARD_BOTTOM_CORNER_RADIUS_RATIO)))


static func get_display_name(card_data: Dictionary) -> String:
	var card_name := str(card_data.get("name", ""))
	if card_data.get("is_upgraded", false):
		return card_name + "+"
	return card_name


static func resolve_upgrade_text(text: String, upgraded: bool) -> String:
	var resolved := text

	var rx_bracket := RegEx.new()
	rx_bracket.compile("(\\d+%?)\\((\\d+%?)\\)")
	var bracket_matches := rx_bracket.search_all(resolved)
	for i in range(bracket_matches.size() - 1, -1, -1):
		var m := bracket_matches[i]
		var pick := m.get_string(2) if upgraded else m.get_string(1)
		resolved = resolved.substr(0, m.get_start()) + pick + resolved.substr(m.get_end())

	var rx_equal := RegEx.new()
	rx_equal.compile("等量\\(\\+(\\d+)\\)")
	var equal_matches := rx_equal.search_all(resolved)
	for i in range(equal_matches.size() - 1, -1, -1):
		var m := equal_matches[i]
		var pick := "等量+%s" % m.get_string(1) if upgraded else "等量"
		resolved = resolved.substr(0, m.get_start()) + pick + resolved.substr(m.get_end())

	return resolved


static func resolve_description(card_data: Dictionary, description_override: String = "") -> String:
	var text := description_override if not description_override.is_empty() else str(card_data.get("desc", ""))
	return resolve_upgrade_text(text, bool(card_data.get("is_upgraded", false)))


func refresh() -> void:
	_ensure_layers()
	if _card_data.is_empty():
		return

	var render_size := size
	if render_size.x <= 0.0 or render_size.y <= 0.0:
		render_size = custom_minimum_size
	if render_size.x <= 0.0 or render_size.y <= 0.0:
		return

	_update_label_sizes(render_size)
	_template.texture = CARD_TEMPLATE
	_template.position = Vector2.ZERO
	_template.size = render_size

	var art_tex := _load_art_texture()
	_art.texture = art_tex
	_art.visible = art_tex != null
	_set_rect(_art, render_size, 215.0, 425.0, 1080.0, 1020.0)

	_place_text_center(_ling_label, str(int(_card_data.get("ling_li", 0))), render_size, 130.0, 215.0, 180.0, 150.0)
	_place_text_center(_dao_label, str(int(_card_data.get("dao_hui", 0))), render_size, 1396.0, 215.0, 180.0, 150.0)
	_name_label.add_theme_color_override("font_color", _get_name_color())
	_place_text_center(_name_label, get_display_name(_card_data), render_size, CARD_BASE_W * 0.5, 95.0, 720.0, 110.0)
	_place_text_center(_type_label, _get_card_type_label(), render_size, CARD_BASE_W * 0.5, 1780.0, 420.0, 90.0)

	var desc_top := render_size.y * 1850.0 / CARD_BASE_H
	var desc_height := render_size.y * (2600.0 - 1850.0) / CARD_BASE_H
	var desc_pad := render_size.x * 200.0 / CARD_BASE_W
	_desc_label.position = Vector2(desc_pad, desc_top)
	_desc_label.size = Vector2(render_size.x - desc_pad * 2.0, desc_height)
	_desc_rich_label.position = _desc_label.position
	_desc_rich_label.size = _desc_label.size
	_render_description()


func _on_resized() -> void:
	queue_redraw()
	refresh()


func _ensure_layers() -> void:
	if _template != null:
		return

	clip_contents = true
	clip_children = CanvasItem.CLIP_CHILDREN_ONLY if _rounded_mask_enabled else CanvasItem.CLIP_CHILDREN_DISABLED

	# 圆角 shader 直接挂在模板 TextureRect 上，TEXTURE = 卡牌框架图，UV 坐标可靠
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float corner_radius : hint_range(0.0, 256.0) = 28.0;
void fragment() {
	vec2 px  = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 pos = UV * px;
	float r  = corner_radius;
	vec2 d   = abs(pos - px * 0.5) - (px * 0.5 - r);
	float dist  = length(max(d, 0.0)) - r;
	float alpha = 1.0 - smoothstep(-1.0, 1.0, dist);
	COLOR   = texture(TEXTURE, UV);
	COLOR.a *= alpha;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader

	_template = TextureRect.new()
	_template.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_template.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_template.stretch_mode = TextureRect.STRETCH_SCALE
	_template.material = mat
	add_child(_template)

	_art = TextureRect.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_art)

	_ling_label = _make_label(9, Color.WHITE, 1, Color(0.0, 0.0, 0.0, 0.86))
	_dao_label = _make_label(9, Color.WHITE, 1, Color(0.0, 0.0, 0.0, 0.86))
	_name_label = _make_label(7, Color.WHITE, 1, Color(0.0, 0.0, 0.0, 0.78))
	_type_label = _make_label(5, _card_text_dark(), 0, Color.TRANSPARENT)
	_desc_label = _make_label(6, _card_text_dark(), 0, Color.TRANSPARENT)
	_desc_label.add_theme_constant_override("line_spacing", 1)
	_desc_rich_label = _make_description_rich_label()
	_desc_rich_label.add_theme_constant_override("line_spacing", 1)

	add_child(_ling_label)
	add_child(_dao_label)
	add_child(_name_label)
	add_child(_type_label)
	add_child(_desc_label)
	add_child(_desc_rich_label)


func _draw_rounded_mask() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var radius := get_corner_radius_for_size(size)
	var bottom_radius := get_bottom_corner_radius_for_size(size)
	_mask_style.bg_color = Color.WHITE
	_mask_style.corner_radius_top_left = radius
	_mask_style.corner_radius_top_right = radius
	_mask_style.corner_radius_bottom_right = bottom_radius
	_mask_style.corner_radius_bottom_left = bottom_radius
	draw_style_box(_mask_style, Rect2(Vector2.ZERO, size))


func _make_label(font_size: int, color: Color, outline_size: int, outline_color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", outline_size)
	return label


func _make_description_rich_label() -> RichTextLabel:
	var label := RichTextLabel.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.bbcode_enabled = false
	label.fit_content = false
	label.scroll_active = false
	label.selection_enabled = false
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.add_theme_font_size_override("normal_font_size", 6)
	label.add_theme_color_override("default_color", _card_text_dark())
	var transparent := StyleBoxEmpty.new()
	label.add_theme_stylebox_override("normal", transparent)
	label.add_theme_stylebox_override("focus", transparent)
	return label


func _update_label_sizes(render_size: Vector2) -> void:
	var scale_x := render_size.x / CARD_BASE_W
	_ling_label.add_theme_font_size_override("font_size", max(1, int(round(SIZE_COST * scale_x))))
	_dao_label.add_theme_font_size_override("font_size", max(1, int(round(SIZE_COST * scale_x))))
	_name_label.add_theme_font_size_override("font_size", max(1, int(round(SIZE_NAME * scale_x))))
	_type_label.add_theme_font_size_override("font_size", max(1, int(round(SIZE_TYPE * scale_x))))
	_desc_label.add_theme_font_size_override("font_size", max(1, int(round(SIZE_DESC * scale_x))))
	_desc_rich_label.add_theme_font_size_override("normal_font_size", max(1, int(round(SIZE_DESC * scale_x))))


func _set_rect(node: Control, render_size: Vector2, x: float, y: float, w: float, h: float) -> void:
	node.position = Vector2(render_size.x * x / CARD_BASE_W, render_size.y * y / CARD_BASE_H)
	node.size = Vector2(render_size.x * w / CARD_BASE_W, render_size.y * h / CARD_BASE_H)


func _place_text_center(label: Label, text: String, render_size: Vector2, cx: float, cy: float, w: float, h: float) -> void:
	label.text = text
	label.position = Vector2(
		render_size.x * (cx - w * 0.5) / CARD_BASE_W,
		render_size.y * (cy - h * 0.5) / CARD_BASE_H
	)
	label.size = Vector2(render_size.x * w / CARD_BASE_W, render_size.y * h / CARD_BASE_H)


func _load_art_texture() -> Texture2D:
	var id_str: String = _card_data.get("id", "")
	if id_str.is_empty():
		return null
	var path := "%s%02d.png" % [CARD_ART_SOURCE_DIR, int(id_str)]
	if _art_cache.has(path):
		return _art_cache[path]

	# 绕过 ResourceLoader / Image.load_from_file（均依赖扩展名判断格式）。
	# 直接读字节流并用 magic bytes 选择正确的解码器——兼容扩展名为 .png 但实为 JPEG 的美术资源。
	var abs_path := ProjectSettings.globalize_path(path)
	var open_path := abs_path if FileAccess.file_exists(abs_path) else path
	var file := FileAccess.open(open_path, FileAccess.READ)
	if not file:
		_art_cache[path] = null
		return null
	var data := file.get_buffer(file.get_length())
	file.close()

	if data.size() < 4:
		_art_cache[path] = null
		return null

	var img := Image.new()
	var b0 := data[0]; var b1 := data[1]; var b2 := data[2]; var b3 := data[3]
	var ok := false
	if b0 == 0xFF and b1 == 0xD8 and b2 == 0xFF:
		ok = img.load_jpg_from_buffer(data) == OK
	elif b0 == 0x89 and b1 == 0x50 and b2 == 0x4E and b3 == 0x47:
		ok = img.load_png_from_buffer(data) == OK
	elif b0 == 0x52 and b1 == 0x49 and b2 == 0x46 and b3 == 0x46:
		ok = img.load_webp_from_buffer(data) == OK
	else:
		ok = img.load_png_from_buffer(data) == OK \
			or img.load_jpg_from_buffer(data) == OK \
			or img.load_webp_from_buffer(data) == OK

	if not ok:
		_art_cache[path] = null
		return null

	var tex := ImageTexture.create_from_image(img)
	_art_cache[path] = tex
	return tex


func _get_card_type_label() -> String:
	match _card_data.get("card_type", ""):
		"attack":
			return "术法"
		"skill":
			return "秘法"
		"power":
			return "道法"
		_:
			return str(_card_data.get("type", "术法"))


func _get_name_color() -> Color:
	match _card_data.get("rarity", ""):
		"天品":
			return Color(1.0, 215.0 / 255.0, 0.0, 1.0)
		"地品":
			return Color(148.0 / 255.0, 0.0, 211.0 / 255.0, 1.0)
		"玄品":
			return Color(30.0 / 255.0, 144.0 / 255.0, 1.0, 1.0)
		"黄品":
			return Color(40.0 / 255.0, 40.0 / 255.0, 40.0 / 255.0, 1.0)
		_:
			return Color.WHITE


func _card_text_dark() -> Color:
	return Color(40.0 / 255.0, 20.0 / 255.0, 0.0, 1.0)


static func _segments_to_text(segments: Array) -> String:
	var text := ""
	for segment in segments:
		text += str(segment.get("text", ""))
	return text


func _render_description() -> void:
	_desc_rich_label.clear()
	if not _description_segments_override.is_empty():
		_desc_label.hide()
		_desc_rich_label.show()
		var text := _segments_to_text(_description_segments_override)
		var wrapped_text := _wrap_card_desc_text(text, _desc_label.size.x)
		var wrapped_segments := _apply_line_wrap_to_segments(_description_segments_override, wrapped_text)
		_desc_rich_label.position.y = _desc_label.position.y + _get_centered_desc_offset(wrapped_text)
		_desc_rich_label.size.y = maxf(1.0, _desc_label.size.y - _get_centered_desc_offset(wrapped_text))
		_desc_rich_label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		for segment in wrapped_segments:
			var color: Color = segment.get("color", _card_text_dark())
			_desc_rich_label.push_color(color)
			_desc_rich_label.add_text(str(segment.get("text", "")))
			_desc_rich_label.pop()
		_desc_rich_label.pop()
		return

	_desc_rich_label.hide()
	_desc_label.show()
	var desc := resolve_description(_card_data, _description_override)
	_desc_label.text = _wrap_card_desc_text(desc, _desc_label.size.x)


func _get_centered_desc_offset(text: String) -> float:
	var font_size := _desc_label.get_theme_font_size("font_size")
	var line_count := maxi(text.count("\n") + 1, 1)
	var line_spacing := _desc_label.get_theme_constant("line_spacing")
	var content_h := line_count * font_size + maxi(line_count - 1, 0) * line_spacing
	return maxf(0.0, (_desc_label.size.y - content_h) * 0.5)


func _apply_line_wrap_to_segments(segments: Array, wrapped_text: String) -> Array:
	var source_text := _segments_to_text(segments)
	if source_text == wrapped_text:
		return segments

	var wrapped_segments: Array = []
	var source_i := 0
	var seg_i := 0
	var seg_offset := 0
	while seg_i < segments.size() and source_i <= source_text.length():
		var wrapped_i := _segments_to_text(wrapped_segments).length()
		if wrapped_i >= wrapped_text.length():
			break
		var wrapped_ch := wrapped_text.substr(wrapped_i, 1)
		if wrapped_ch == "\n":
			wrapped_segments.append({"text": "\n", "color": _card_text_dark()})
			continue
		while seg_i < segments.size() and seg_offset >= str(segments[seg_i].get("text", "")).length():
			seg_i += 1
			seg_offset = 0
		if seg_i >= segments.size():
			break
		var seg_text := str(segments[seg_i].get("text", ""))
		var src_ch := seg_text.substr(seg_offset, 1)
		wrapped_segments.append({"text": src_ch, "color": segments[seg_i].get("color", _card_text_dark())})
		seg_offset += 1
		source_i += 1
	return _merge_adjacent_segments(wrapped_segments)


func _merge_adjacent_segments(segments: Array) -> Array:
	var merged: Array = []
	for segment in segments:
		var last_i := merged.size() - 1
		if not merged.is_empty() and merged[last_i].get("color") == segment.get("color"):
			merged[last_i]["text"] = str(merged[last_i].get("text", "")) + str(segment.get("text", ""))
		else:
			merged.append(segment.duplicate())
	return merged


func _wrap_card_desc_text(text: String, max_width: float) -> String:
	var font := _desc_label.get_theme_font("font")
	if font == null:
		return text

	var font_size := _desc_label.get_theme_font_size("font_size")
	var punc := "，。！？；、,.!?:;"
	var lines: Array[String] = []
	var cur := ""

	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var test := cur + ch
		var test_width := font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		if test_width > max_width and not cur.is_empty():
			var best := -1
			for j in range(cur.length() - 1, -1, -1):
				if punc.contains(cur.substr(j, 1)):
					best = j
					break
			if best >= 0:
				lines.append(cur.substr(0, best + 1))
				cur = cur.substr(best + 1).strip_edges(true, false) + ch
			else:
				lines.append(cur)
				cur = ch
		else:
			cur = test

	if not cur.is_empty():
		lines.append(cur)

	return "\n".join(lines)
