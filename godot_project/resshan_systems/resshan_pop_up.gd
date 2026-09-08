class_name ResshanPopUp
extends Control

const EMPTY_NOTE_TEXT := "(no note yet)"
const EMPTY_NOTE_COLOR := Color(0.45, 0.45, 0.45)
const NOTE_COLOR := Color(0.0018410678, 0.0018410682, 0.0018410678)
const NOTE_FONT: Font = preload("uid://k24n0d7oex7j")
const EMPTY_NOTE_FONT: Font = preload("uid://ceojd8l1vj6fd")

var _note_text := ""


func add_note(note:String) -> void:
	_note_text = note
	var label: Label = $PanelContainer/MarginContainer/Note
	var empty := note.strip_edges().is_empty()
	label.text = EMPTY_NOTE_TEXT if empty else note
	label.label_settings.font = EMPTY_NOTE_FONT if empty else NOTE_FONT
	label.label_settings.font_color = EMPTY_NOTE_COLOR if empty else NOTE_COLOR

func get_note() -> String:
	return _note_text
