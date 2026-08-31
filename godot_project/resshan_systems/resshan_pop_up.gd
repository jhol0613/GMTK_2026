class_name ResshanPopUp
extends Control

const EMPTY_NOTE_TEXT := "No Entry"

var _note_text := ""


func add_note(note:String) -> void:
	_note_text = note
	$PanelContainer/MarginContainer/Note.text = (
		EMPTY_NOTE_TEXT if note.strip_edges().is_empty() else note
	)

func get_note() -> String:
	return _note_text
