class_name LanguageRenderer
extends Node2D


static func draw_text(text: String, node:CanvasItem) -> void:
	var char_pos: Vector2 = Vector2.ZERO
	var arr: PackedStringArray = text.split(" ")
	for str:String in arr:
		if str.contains("<<"):
			char_pos.x += draw_resshan_text(char_pos, str, node)
			continue
		node.draw_string(ThemeDB.fallback_font, char_pos, str)
		char_pos.x += ThemeDB.fallback_font.get_string_size(str).x + 15


static func draw_resshan_text(pos:Vector2,str:String, node:CanvasItem) -> float:
	var arr: PackedStringArray = encode(str).split('.')
	pos.y -= 16
	for indx:String in arr:
		var char_rec: = Rect2(pos, Vector2(16,16))
		var src_rect: = Rect2(str_to_var(indx) * 8, 0, 8,8)
		node.draw_texture_rect_region(
			preload("res://resshan_alphabet/resshan_placeholder.png"),
			char_rec, src_rect
		)
		pos.x += 16
	return arr.size() * 16 + 15

static func encode(str:String) -> String:
	return preload("res://resshan_alphabet/vocab.json").data[str.capitalize()]
