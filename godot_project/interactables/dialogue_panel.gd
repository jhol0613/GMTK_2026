class_name DialoguePanel
extends InteractionPanelBase

@onready var _speaker: Label = $Root/Popup/MarginContainer/VBox/Speaker
@onready var _body: Label = $Root/Popup/MarginContainer/VBox/Body

var _lines: PackedStringArray = []
var _index: int = 0


func show_dialogue(speaker: String, lines: PackedStringArray) -> void:
	_speaker.text = speaker
	_lines = lines
	_index = 0
	_update_body()
	_open()


func _update_body() -> void:
	if _lines.is_empty():
		_body.text = ""
		return
	_body.text = _lines[_index]


func _on_interact_while_open() -> void:
	if _index < _lines.size() - 1:
		_index += 1
		_update_body()
	else:
		hide_popup()
