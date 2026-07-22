extends CanvasLayer

@onready var _root: Control = $Root
@onready var _title: Label = $Root/Popup/MarginContainer/Title

var _is_open: bool = false

func _ready():
	_root.visible = false


func show_popup(title: String) -> void:
	_title.text = title
	_root.visible = true
	_is_open = true

func hide_popup() -> void:
	_root.visible = false
	_is_open = false

func is_open() -> bool:
	return _is_open

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event.is_action_pressed("interact"):
		hide_popup()
		get_viewport().set_input_as_handled()