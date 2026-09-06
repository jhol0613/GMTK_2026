extends Node2D


@onready var dialogue_interactable := $DialogueInteractable
@onready var dialogue_panel := $CanvasLayer/DialoguePanel

signal scene_complete

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dialogue_interactable.interact()
	dialogue_panel.dialogue_complete.connect(_on_dialogue_complete)
	

func _on_dialogue_complete():
	scene_complete.emit()
	#queue_free()
