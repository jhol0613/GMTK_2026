@tool
class_name ResshanLabel
extends Control

@export_multiline() var text: String:
	set(value):
		text = value
		_drawn = false
		queue_redraw()

@export var spacing: float = 15.0:
	set(value):
		spacing = value
		_drawn = false
		queue_redraw()

@export var font: Font:
	set(value):
		font = value
		_drawn = false
		queue_redraw()

@export var font_size: int = 16:
	set(value):
		font_size = value
		_drawn = false
		queue_redraw()

@export_range(0.5, 4.0, 0.1) var note_popup_scale_multiplier := 1.0

@export var wrap_text := false:
	set(value):
		wrap_text = value
		_drawn = false
		queue_redraw()

var _shapes: Array[RectangleShape2D]
var _areas: Array[ResshanInteractable]

var _drawn: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(_on_resized)


func _on_resized() -> void:
	if wrap_text:
		_drawn = false
		queue_redraw()


func _draw() -> void:
	
	var _f: Font = font
	if not font:
		_f = ThemeDB.fallback_font
	if wrap_text:
		_shapes = _draw_wrapped(_f)
	else:
		_shapes = LanguageRenderer.draw_text(text, self, spacing, "/n", _f, font_size)
	
	if _drawn:
		return
	
	for i: Node in _areas:
		i.queue_free()
	_areas.clear()

	for shape: RectangleShape2D in _shapes:
		var area := ResshanInteractable.new()
		var pos: Vector2 = shape.get_meta('text_position')
		var resshen: String = shape.get_meta('resshen_text')

		area.position = pos
		#area.position.x = 0
		#area.position.x += shape.size.x * 0.5
		area._encoded_string = LanguageRenderer.encode(resshen)
		area.size = shape.size
		area.note_popup_scale_multiplier = note_popup_scale_multiplier

		_areas.append(area)
		add_child(area)
	
	if not wrap_text:
		custom_minimum_size = LanguageRenderer.get_string_size(
			text, _f, font_size, "/n", spacing,
		)
	
	_drawn = true


func _draw_wrapped(draw_font: Font) -> Array[RectangleShape2D]:
	var shapes: Array[RectangleShape2D] = []
	var tokenizer := RegEx.new()
	tokenizer.compile("<<[^<>]+>>|\\n|[^\\S\\n]+|[^\\s<]+|<")
	var width := maxf(size.x, float(font_size))
	var line_height := ceilf(maxf(draw_font.get_height(font_size), font_size * 1.1))
	var pen := Vector2.ZERO
	for match_result in tokenizer.search_all(text.replace("/n", "\n")):
		var token := match_result.get_string()
		if token == "\n":
			pen = Vector2(0, pen.y + line_height)
			continue
		if token.strip_edges().is_empty():
			if pen.x > 0:
				pen.x += spacing
			continue
		var resshan := token.begins_with("<<") and token.ends_with(">>")
		var encoded := LanguageRenderer.encode(token) if resshan else ""
		var token_width := float(encoded.split(".").size() * font_size) if resshan else draw_font.get_string_size(token, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if pen.x > 0 and pen.x + token_width > width:
			pen = Vector2(0, pen.y + line_height)
		var pieces: Array[String] = [token]
		if token_width > width:
			pieces.clear()
			if resshan:
				pieces.assign(encoded.split("."))
			else:
				for character in token:
					pieces.append(character)
		for piece in pieces:
			var piece_width := token_width if pieces.size() == 1 else float(font_size) if resshan else draw_font.get_string_size(piece, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			if pen.x > 0 and pen.x + piece_width > width:
				pen = Vector2(0, pen.y + line_height)
			if resshan:
				var glyphs := encoded if pieces.size() == 1 else piece
				var shape := LanguageRenderer.draw_resshan_text(Vector2(pen.x, font_size - pen.y), glyphs, self, true, font_size, Color(1.0, 0.98, 0.83, 1))
				shape.set_meta("text_position", pen)
				shape.set_meta("resshen_text", token)
				shapes.append(shape)
			else:
				draw_string(draw_font, pen + Vector2(0, draw_font.get_ascent(font_size)), piece, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.98, 0.83, 1))
			pen.x += piece_width
	custom_minimum_size = Vector2(0, pen.y + line_height if not text.is_empty() else 0.0)
	return shapes
