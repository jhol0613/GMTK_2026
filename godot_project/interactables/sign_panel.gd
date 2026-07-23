class_name SignPanel
extends InteractionPanelBase

@onready var _title: Label = $Root/Popup/MarginContainer/Title


func show_sign(title: String, minutes: int = 1) -> void:
	_title.text = title
	_open(minutes)
