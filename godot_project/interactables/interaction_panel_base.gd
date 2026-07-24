extends CanvasLayer
class_name InteractionPanelBase

signal closed

@onready var _root: Control = $Root

var _is_open: bool = false


func _ready() -> void:
	add_to_group("interaction_panel")
	_root.visible = false
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func hide_popup() -> void:
	if not _is_open:
		return
	_root.visible = false
	_is_open = false
	closed.emit()


func is_open() -> bool:
	return _is_open


func _open(minutes: int = 1) -> void:
	# If the CanvasLayer is invisible, the Root will not be visible either.
	visible = true
	_root.visible = true
	_is_open = true
	SignalBus.minutes_passed.emit(minutes)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event.is_action_pressed("interact"):
		_on_interact_while_open()
		get_viewport().set_input_as_handled()


## Override in subclasses to handle interaction while the panel is open
func _on_interact_while_open() -> void:
	hide_popup()
