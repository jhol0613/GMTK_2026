extends Area2D
class_name Interactable

@onready var _prompt: ResshanLabel = $Prompt

var _player_in_range: bool = false


func _ready() -> void:
	if _prompt:
		_prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if _is_any_panel_open():
		return

	if event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()


## Check if any interaction panel is open, avoid double interaction
func _is_any_panel_open() -> bool:
	for panel in get_tree().get_nodes_in_group("interaction_panel"):
		if panel.has_method("is_open") and panel.is_open():
			return true
	return false


## Override in subclasses to open their own panel
func interact() -> void:
	pass


func _on_body_entered(_body: Node2D) -> void:
	_player_in_range = true
	_prompt.visible = true


func _on_body_exited(_body: Node2D) -> void:
	_player_in_range = false
	_prompt.visible = false
