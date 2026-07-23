class_name ResshanInteractable
extends Area2D


signal text_clicked(str:String)


@export var _string: String = ''
var _encoded_string: String = ''

func _ready() -> void:
	if not _string.is_empty():
		_encoded_string = LanguageRenderer.encode(_string)

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			text_clicked.emit(_encoded_string)
