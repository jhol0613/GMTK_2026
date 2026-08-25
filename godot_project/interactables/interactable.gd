extends Area2D
class_name Interactable

signal interacted

@onready var _prompt: ResshanLabel = $Prompt
@export var _arrow: AnimatedSprite2D
@export var has_arrow: bool = true

var _player_in_range: bool = false


func _ready() -> void:
	if _prompt:
		_prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if _is_world_interaction_blocked():
		return
	if _is_any_panel_open():
		return

	if event.is_action_pressed("interact"):
		interacted.emit()
		interact()
		get_viewport().set_input_as_handled()


## Check if any interaction panel is open, avoid double interaction
func _is_any_panel_open() -> bool:
	for panel in get_tree().get_nodes_in_group("interaction_panel"):
		if panel.has_method("is_open") and panel.is_open():
			return true
	return false


func _is_world_interaction_blocked() -> bool:
	var focused_control := get_viewport().gui_get_focus_owner()
	if focused_control is LineEdit or focused_control is TextEdit:
		return true

	for blocker in get_tree().get_nodes_in_group("world_interaction_blocker"):
		if blocker is CanvasItem and blocker.is_visible_in_tree():
			return true

	return false


## Override in subclasses to open their own panel
func interact() -> void:
	pass


func _on_body_entered(_body: Node2D) -> void:
	_player_in_range = true
	_prompt.visible = true
	_arrow.visible = false


func _on_body_exited(_body: Node2D) -> void:
	_player_in_range = false
	_prompt.visible = false
	_arrow.visible = has_arrow
