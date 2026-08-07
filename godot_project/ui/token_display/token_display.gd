extends HBoxContainer

## Always-visible token counter. Assign `icon_texture` once the real token art
## exists; until then a coloured square stands in for it.

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		_apply_icon()

@onready var _icon: TextureRect = $Icon
@onready var _placeholder: ColorRect = $Placeholder
@onready var _label: Label = $Count


func _ready() -> void:
	_apply_icon()
	Wallet.tokens_changed.connect(_on_tokens_changed)
	_on_tokens_changed(Wallet.tokens, Wallet.MAX_TOKENS)


func _apply_icon() -> void:
	if not is_node_ready():
		return
	_icon.texture = icon_texture
	_icon.visible = icon_texture != null
	_placeholder.visible = icon_texture == null


func _on_tokens_changed(current: int, maximum: int) -> void:
	_label.text = "%d / %d" % [current, maximum]
