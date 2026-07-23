class_name LanguageRenderer
extends Node2D


# It's for the "str" variables. str() is a keyword, so it's fine
@warning_ignore_start('shadowed_global_identifier')
## This function should only be called in the _draw() function of the node
## It returns Array[RectangleShape2D] which contains data 
## to build ResshanInteractable
static func draw_text(text: String, node:CanvasItem) -> Array[RectangleShape2D]:
	var shapes: Array[RectangleShape2D]
	var char_pos: Vector2 = Vector2.ZERO
	var arr: PackedStringArray = text.split(" ")
	
	for str:String in arr:
		if str.contains("<<"):
			var shape: = draw_resshan_text(char_pos, str, node)
			shape.set_meta('resshen_text', str)
			shape.set_meta('text_position', char_pos)
			shapes.append(shape)
			char_pos.x += shape.size.x + 15
			continue
		
		node.draw_string(ThemeDB.fallback_font, char_pos, str)
		char_pos.x += ThemeDB.fallback_font.get_string_size(str).x + 15
	
	return shapes

## Returned RectableShape2D is the size of the entire Resshan word
static func draw_resshan_text(pos:Vector2,str:String, node:CanvasItem, encoded: = false) -> RectangleShape2D:
	var arr: PackedStringArray = []
	if not encoded:
		arr = encode(str).split('.')
	else:
		arr = str.split('.')
	
	pos.y -= 16
	for indx:String in arr:
		var char_rec: = Rect2(pos, Vector2(16,16))
		var src_rect: = Rect2(str_to_var(indx) * 8, 0, 8,8)
		node.draw_texture_rect_region(
			preload("uid://ihhqr2q1fxal"),
			char_rec, src_rect
		)
		pos.x += 16
	var shape: = RectangleShape2D.new()
	shape.size.x = arr.size() * 16
	shape.size.y = 16
	return shape

## Turns <<***>> Resshen format into *.*.*.*... encoded format
static func encode(str:String) -> String:
	return preload("res://resshan_systems/vocab.json").data[str.capitalize()]
