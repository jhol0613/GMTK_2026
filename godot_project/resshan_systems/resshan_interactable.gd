class_name ResshanInteractable
extends Area2D


@export var _string: String = ''
var _encoded_string: String = ''

func _ready() -> void:
	if not _string.is_empty():
		_encoded_string = LanguageRenderer.encode(_string)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			SignalBus.resshan_clicked.emit(_encoded_string)
