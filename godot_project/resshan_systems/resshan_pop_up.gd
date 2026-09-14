class_name ResshanPopUp
extends Control

const EMPTY_NOTE_TEXT := "(no note yet)"
const EMPTY_NOTE_COLOR := Color(0.45, 0.45, 0.45)
const NOTE_COLOR := Color(0.0018410678, 0.0018410682, 0.0018410678)
const NOTE_FONT: Font = preload("uid://k24n0d7oex7j")
const EMPTY_NOTE_FONT: Font = preload("uid://ceojd8l1vj6fd")

@export var _panel : PanelContainer

var _note_text := ""
var og_position : Vector2

func add_note(note:String) -> void:
	og_position = position
	_note_text = note
	var label: Label = $PanelContainer/MarginContainer/Note
	var empty := note.strip_edges().is_empty()
	label.text = EMPTY_NOTE_TEXT if empty else note
	label.label_settings.font = EMPTY_NOTE_FONT if empty else NOTE_FONT
	label.label_settings.font_color = EMPTY_NOTE_COLOR if empty else NOTE_COLOR
	position = og_position



func get_note() -> String:
	return _note_text


func constrain():
	var game_window_size : Vector2 = get_viewport().get_visible_rect().size
	var buffer : Vector2 = _panel.size/2 + Vector2(2,2)
	var view_posit : Vector2 = get_global_transform_with_canvas().origin
	
	if (view_posit.x < buffer.x):
		view_posit.x += buffer.x - view_posit.x
	elif (view_posit.x > game_window_size.x - buffer.x):
		view_posit.x += game_window_size.x - buffer.x - view_posit.x
	if (view_posit.y < buffer.y):
		view_posit.y += buffer.y - view_posit.y
	elif (view_posit.y > game_window_size.y - buffer.y):
		view_posit.y += game_window_size.y - buffer.y - view_posit.y
	
	position = get_tree().get_first_node_in_group( "level" ).make_canvas_position_local(view_posit)
