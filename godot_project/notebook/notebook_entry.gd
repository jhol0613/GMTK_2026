class_name NotebookEntry
extends HBoxContainer

signal entry_updated
signal move_requested(to_section:int)

var resshan_string:String

@onready var player_input: LineEdit = $PlayerInput

func _draw() -> void:
	if not resshan_string:
		return
	var shape: = LanguageRenderer.draw_resshan_text(
		$Resshan.position + Vector2(0, 75), resshan_string, self, true,
		80, Color.BLACK
	)
	$Resshan.custom_minimum_size.x = shape.size.x
	$Resshan.custom_minimum_size.y = shape.size.y


func add_resshan(encoded:String) -> void:
	resshan_string = encoded
	queue_redraw()


func get_note() -> String:
	return player_input.text


func _on_move_entry_pressed(to_section: int) -> void:
	move_requested.emit(to_section)
