class_name DialogueInteractable
extends Interactable

@export var speaker: String = "NPC"
@export var lines: Array[DialogueLine] = []
@export var choices: Array[DialogueChoice] = []
@export var panel_path: NodePath
@export var minutes_cost: int = 1
@export var turn_on_sound: AudioStreamPlayer

func interact() -> void:
	if turn_on_sound != null:
		turn_on_sound.play()
		
	if panel_path.is_empty():
		return
	var panel := get_node_or_null(panel_path) as DialoguePanel
	if panel == null:
		return
	panel.show_dialogue(
		speaker, lines, choices, minutes_cost
	)
