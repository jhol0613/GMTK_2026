extends Control

@export var time_til_display := 2

#2 dialogue panels literally just to change text appear speed
@onready var dialogue_interactable := $DialogueInteractable1
@onready var dialogue_interactable2 := $DialogueInteractable2
@onready var dialogue_panel := $DialoguePanel
@onready var dialogue_panel2 := $DialoguePanel2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dialogue_interactable.interact()
	dialogue_panel.dialogue_complete.connect(_on_dialogue_complete)

func _on_dialogue_complete():
	dialogue_interactable2.interact()
	dialogue_panel2.dialogue_complete.connect(_on_dialogue2_complete)

func _on_dialogue2_complete():
	GameManager.load_scene(Enums.Scenes.TITLE, Enums.TransitionStyle.FADE_BLACK, 4.0)
