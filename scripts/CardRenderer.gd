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

var _card_data: Dictionary = {}
var _description_override: String = ""
var _art_cache: Dictionary = {}

var _template: TextureRect
var _art: TextureRect
var _ling_label: Label
var _dao_label: Label
var _name_label: Label
var _type_label: Label
var _desc_label: Label


func _ready() -> void:
	_ensure_layers()
	resized.connect(_on_resized)
	call_deferred("refresh")


func setup(card_data: Dictionary, description_override: String = "") -> void:
	_card_data = card_data
	_description_override = description_override
	_ensure_layers()
	call_deferred("refresh")


func set_card_data(card_data: Dictionary) -> void:
	_card_data = card_data
	refresh()


func set_description_override(text: String) -> void:
	_description_override = text
	refresh()


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
	_place_text_center(_name_label, str(_card_data.get("name", "")), render_size, CARD_BASE_W * 0.5, 95.0, 720.0, 110.0)
	_place_text_center(_type_label, _get_card_type_label(), render_size, CARD_BASE_W * 0.5, 1780.0, 420.0, 90.0)

	var desc_top := render_size.y * 1850.0 / CARD_BASE_H
	var desc_height := render_size.y * (2600.0 - 1850.0) / CARD_BASE_H
	var desc_pad := render_size.x * 200.0 / CARD_BASE_W
	_desc_label.position = Vector2(desc_pad, desc_top)
	_desc_label.size = Vector2(render_size.x - desc_pad * 2.0, desc_height)
	var desc := _description_override if not _description_override.is_empty() else str(_card_data.get("desc", ""))
	_desc_label.text = _wrap_card_desc_text(desc, _desc_label.size.x)


func _on_resized() -> void:
	refresh()


func _ensure_layers() -> void:
	if _template != null:
		return

	clip_contents = true
	_template = TextureRect.new()
	_template.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_template.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_template.stretch_mode = TextureRect.STRETCH_SCALE
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

	add_child(_ling_label)
	add_child(_dao_label)
	add_child(_name_label)
	add_child(_type_label)
	add_child(_desc_label)


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


func _update_label_sizes(render_size: Vector2) -> void:
	var scale_x := render_size.x / CARD_BASE_W
	_ling_label.add_theme_font_size_override("font_size", max(1, int(round(SIZE_COST * scale_x))))
	_dao_label.add_theme_font_size_override("font_size", max(1, int(round(SIZE_COST * scale_x))))
	_name_label.add_theme_font_size_override("font_size", max(1, int(round(SIZE_NAME * scale_x))))
	_type_label.add_theme_font_size_override("font_size", max(1, int(round(SIZE_TYPE * scale_x))))
	_desc_label.add_theme_font_size_override("font_size", max(1, int(round(SIZE_DESC * scale_x))))


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
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex:
			_art_cache[path] = tex
			return tex
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img:
		var tex := ImageTexture.create_from_image(img)
		_art_cache[path] = tex
		return tex
	_art_cache[path] = null
	return null


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
