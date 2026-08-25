extends Npc

@export var choice_bank: Dictionary[Enums.TrainColor, DialogueChoice]
@export var nevermind_choice: DialogueChoice
@export var initial_dialogue: Dialogue
@export var repeat_dialogue: Dialogue
##Text without the specific color
@export var repeat_dialogue_text: String

@onready var dialogue_interactable := $DialogueInteractable
@onready var panel := $DialoguePanel
@onready var mask := $Sprite/Mask

@onready var _happy = false

func _ready():
	panel.option_confirmed.connect(_on_option_confirmed)
	dialogue_interactable.dialogue = initial_dialogue

func _on_dialogue_interactable_interacted() -> void:
	var _choices : Array[DialogueChoice] = dialogue_interactable.dialogue.choices
	_choices.clear()
	_choices.append(nevermind_choice)
	for key in choice_bank.keys():
		var color_str = str(Enums.TrainColor.find_key(key))
		if Inventory.has_item("mask_" + color_str.to_lower()):
			_choices.append(choice_bank[key])

func _on_option_confirmed(option_id: StringName):
	if option_id == &"NONE":
		return
	_happy = true
	repeat_dialogue.lines[0].text = \
		repeat_dialogue_text % ["<<" + option_id.to_lower() + ">>"]
	dialogue_interactable.dialogue = repeat_dialogue
	mask.play(option_id)
	
