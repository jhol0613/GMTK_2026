class_name SignPanel
extends InteractionPanelBase

@onready var _title: Label = $Root/Popup/MarginContainer/Title
@onready var _close_button: TextureButton = $Root/CloseButton


func show_sign(title: String, minutes: int = 1) -> void:
	set_compact(false, 0.0)
	_title.text = title
	_open(minutes)

func _ready() -> void:
	super._ready()
	dismissible = true


func _on_close_button_pressed() -> void:
	hide_popup()
