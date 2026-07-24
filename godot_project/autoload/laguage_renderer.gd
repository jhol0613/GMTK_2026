class_name LanguageRenderer
extends Node2D

const DEFAULT_SPACING: = 15.0
const DEFAULT_PARAGRAPH_SEPARATOR: = "\n"
const DEFAULT_FONT_SIZE: int = 16

# It's for the "str" variables. str() is a keyword, so it's fine
@warning_ignore_start('shadowed_global_identifier')
## This function should only be called in the _draw() function of the Control
## It returns Array of RectangleShape2D which contains data 
## to build ResshanInteractable
static func draw_text(
	text: String, 
	node: Control,
	spacing: float = DEFAULT_SPACING,
	separator: String = DEFAULT_PARAGRAPH_SEPARATOR,
	font: = ThemeDB.fallback_font,
	font_size: = DEFAULT_FONT_SIZE,
) -> Array[RectangleShape2D]:
	
	var shapes: Array[RectangleShape2D]
	var char_pos: Vector2 = Vector2(0, font_size)
	var arr: PackedStringArray = text.split(" ")
	
	for str:String in arr:
		if str == separator:
			char_pos.y += 16
			char_pos.x = 0
			continue
		if str.contains("<<") and str.contains(">>"):
			var shape: = draw_resshan_text(char_pos, str, node, false, font_size)
			shape.set_meta('resshen_text', str)
			shape.set_meta('text_position', char_pos)
			shapes.append(shape)
			char_pos.x += shape.size.x + spacing
			continue
		
		node.draw_string(font, char_pos, str, 0, -1, font_size)
		char_pos.x += font.get_string_size(str, 0, -1, font_size).x + spacing
	
	return shapes

## Returned RectableShape2D is the size of the entire Resshan word
static func draw_resshan_text(
	pos:Vector2,
	str:String,
	node:CanvasItem,
	encoded: = false,
	font_size: = DEFAULT_FONT_SIZE,
	
	) -> RectangleShape2D:
		
	var arr: PackedStringArray = []
	if not encoded:
		arr = encode(str).split('.')
	else:
		arr = str.split('.')
	
	pos.y -= font_size
	for indx:String in arr:
		var char_rec: = Rect2(pos, Vector2(font_size,font_size))
		var i:int = str_to_var(indx)
		@warning_ignore("integer_division")
		var src_rect: = Rect2(i % 10 * 8, int(i/10) * 8, 8,8)
		node.draw_texture_rect_region(
			preload("uid://bb6n1hnvxcvej"),
			char_rec, src_rect
		)
		pos.x += font_size
	var shape: = RectangleShape2D.new()
	shape.size.x = arr.size() * font_size
	shape.size.y = font_size
	return shape

## Turns <<***>> Resshen format into *.*.*.*... encoded format
static func encode(str:String) -> String:
	return preload("res://resshan_systems/vocab.json").data[str.capitalize()]

static func get_string_size() -> Vector2:
	return Vector2()
