extends Node2D


@onready var dialogue_interactable := $DialogueInteractable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dialogue_interactable.interact()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
