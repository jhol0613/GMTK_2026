class_name DialogueInteractable
extends Interactable

@export var speaker: String = "NPC"
@export var lines: PackedStringArray = ["Hello!"]
@export var panel_path: NodePath
@export var option_a: String = "yes"
@export var option_b: String = "no"
@export var correct_option: int = 0
@export var reward: String = "train ticket" # TODO: Add reward item
@export var success_line: String = "take this train ticket"
@export var failure_line: String = "go away"


func interact() -> void:
	if panel_path.is_empty():
		return
	var panel := get_node_or_null(panel_path) as DialoguePanel
	if panel == null:
		return
	panel.show_dialogue(
		speaker, lines, option_a, option_b, correct_option, reward, success_line, failure_line
	)
