class_name MapPanel
extends InteractionPanelBase

@onready var _title: Label = $Root/Popup/MarginContainer/VBox/Title
@onready var _map_image: TextureRect = $Root/Popup/MarginContainer/VBox/MapImage


func show_map(title: String, texture: Texture2D = null, minutes: int = 1) -> void:
	_title.text = title
	_map_image.texture = texture
	_map_image.visible = texture != null
	_open(minutes)
