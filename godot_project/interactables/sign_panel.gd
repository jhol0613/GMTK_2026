class_name SignPanel
extends InteractionPanelBase

@onready var _title: Label = $Root/Popup/MarginContainer/Title


func show_sign(title: String) -> void:
	_title.text = title
	_open()
