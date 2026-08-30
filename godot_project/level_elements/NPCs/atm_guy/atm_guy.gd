extends Node2D
class_name ATMGuy

@onready var dialogue_interactable := $DialogueInteractable

func _ready():
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	dialogue_interactable.active = visible
