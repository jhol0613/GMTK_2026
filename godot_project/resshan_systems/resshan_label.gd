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

var _shapes: Array[RectangleShape2D]
var _areas: Array[ResshanInteractable]

var _drawn: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	
	var _f: Font = font
	if not font:
		_f = ThemeDB.fallback_font
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

		_areas.append(area)
		add_child(area)
	
	custom_minimum_size = LanguageRenderer.get_string_size(
		text,
		ThemeDB.fallback_font,
		font_size,
		"/n",
		spacing,
	)
	
	_drawn = true
