class_name DialogueInteractable
extends Interactable

@export var speaker: String = "NPC"
@export var lines: PackedStringArray = ["Hello!"]
@export var panel_path: NodePath


func interact() -> void:
	if panel_path.is_empty():
		return
	var panel := get_node_or_null(panel_path) as DialoguePanel
	if panel == null:
		return
	panel.show_dialogue(speaker, lines)
