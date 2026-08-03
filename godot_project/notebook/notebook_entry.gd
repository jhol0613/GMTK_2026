class_name NotebookEntry
extends HBoxContainer

signal entry_updated

var _resshan_string:String

@onready var player_input: LineEdit = $PlayerInput

func _draw() -> void:
	if not _resshan_string:
		return
	var shape: = LanguageRenderer.draw_resshan_text(
		$Resshan.position + Vector2(0, 75), _resshan_string, self, true,
		80, Color.BLACK
	)
	$Resshan.custom_minimum_size.x = shape.size.x
	$Resshan.custom_minimum_size.y = shape.size.y


func add_resshan(encoded:String) -> void:
	_resshan_string = encoded
	queue_redraw()


func get_note() -> String:
	return player_input.text


func _on_player_input_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		get_viewport().set_input_as_handled()


#func _on_resshan_gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if not event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			#queue_free()
