class_name NotebookEntry
extends HBoxContainer

var _resshan_string:String

func _draw() -> void:
	if not _resshan_string:
		return
	var shape: = LanguageRenderer.draw_resshan_text(
		$Resshan.position + Vector2(0,24), _resshan_string, self, true,
		20, Color.BLACK
	)
	$Resshan.custom_minimum_size.x = shape.size.x


func add_resshan(encoded:String) -> void:
	_resshan_string = encoded
	queue_redraw()


func get_note() -> String:
	return $PlayerInput.text


func _on_resshan_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			queue_free()
