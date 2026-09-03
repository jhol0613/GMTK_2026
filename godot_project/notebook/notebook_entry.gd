class_name NotebookEntry
extends HBoxContainer

signal entry_updated
signal move_requested(to_section:int)
signal reordered

var resshan_string:String
var _dragging := false
var _drag_preview: NotebookEntry
var _drag_x := 0.0

@onready var player_input: LineEdit = $PlayerInput


func _ready() -> void:
	set_process(false)
	$Resshan.set_drag_forwarding(_get_entry_drag_data, _can_drop_entry, _drop_entry)
	player_input.set_drag_forwarding(_get_no_drag_data, _can_drop_entry, _drop_entry)


func _process(_delta: float) -> void:
	if is_instance_valid(_drag_preview):
		_drag_preview.position.x = _drag_x - get_viewport().get_mouse_position().x - size.x * 0.5

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


func _get_drag_data(_position: Vector2) -> Variant:
	return _get_entry_drag_data(Vector2.ZERO)


func _get_entry_drag_data(_position: Vector2) -> Variant:
	var preview := duplicate() as NotebookEntry
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = size
	preview.position = -size * 0.5
	preview.size = size
	preview.modulate.a = 0.8
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.resshan_string = resshan_string
	preview.get_node("PlayerInput").text = player_input.text
	holder.add_child(preview)
	set_drag_preview(holder)
	_drag_preview = preview
	_drag_x = (get_global_transform_with_canvas() * Vector2(size.x * 0.5, 0.0)).x
	_dragging = true
	modulate.a = 0.35
	set_process(true)
	return self


func _get_no_drag_data(_position: Vector2) -> Variant:
	return null


func _can_drop_data(position: Vector2, data: Variant) -> bool:
	return _can_drop_entry(position, data)


func _can_drop_entry(_position: Vector2, data: Variant) -> bool:
	var valid: bool = data is NotebookEntry and data != self and data.get_parent() == get_parent()
	if valid:
		_get_page().show_drop_indicator(self, _position.y > size.y * 0.5)
	return valid


func _drop_data(position: Vector2, data: Variant) -> void:
	_drop_entry(position, data)


func _drop_entry(position: Vector2, data: Variant) -> void:
	var target := get_index() + int(position.y > size.y * 0.5)
	if data.get_index() < target:
		target -= 1
	get_parent().move_child(data, target)
	_get_page().hide_drop_indicator()
	reordered.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragging:
		_dragging = false
		_drag_preview = null
		modulate.a = 1.0
		set_process(false)
		_get_page().hide_drop_indicator()


func _get_page() -> NotebookPage:
	return get_parent().get_parent() as NotebookPage


func _on_move_entry_pressed(to_section: int) -> void:
	move_requested.emit(to_section)
