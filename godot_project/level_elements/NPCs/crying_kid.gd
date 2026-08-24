extends Npc

@export var dialogue_interactable: DialogueInteractable
@export var choice_bank: Dictionary[Enums.TrainColor, DialogueChoice]
@export var crying_dialogue: Dialogue
@export var happy_dialogue: Dialogue

@onready var _happy = false

var _previous_purchased_color : Enums.TrainColor

func _ready():
	dialogue_interactable.dialogue = crying_dialogue

func _on_dialogue_interactable_interacted() -> void:
	var _choices = dialogue_interactable.dialogue.choices
	_choices.clear()
	for key in choice_bank.keys():
		var color_str = str(Enums.TrainColor.find_key(key))
		if Inventory.has_item(("mask_" + color_str)):
			_choices.append(choice_bank[key])
