extends Npc

@export_group("Dialogue Templates")
@export var choice_bank: Dictionary[Enums.TrainColor, DialogueChoice]
@export var initial_dialogue: Dialogue
@export var repeat_dialogue: Dialogue
@export var nevermind_choice: DialogueChoice
@export var give_item_choice_text: String
@export var received_item_response_text: String
@export var received_item_response_portrait: CompressedTexture2D
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
		var item = Inventory.get_item("mask_" + color_str.to_lower())
		if item:
			choice_bank[key].player_text = give_item_choice_text % [item.item_name]
			#choice_bank[key].reply.text = received_item_response_text
			#choice_bank[key].reply.speaker_icon = received_item_response_portrait
			_choices.append(choice_bank[key])

func _on_option_confirmed(option_id: StringName):
	if option_id == &"NONE":
		return
	Inventory.remove_item(Inventory.get_item(option_id))
	_happy = true
	repeat_dialogue.lines[0].text = \
		repeat_dialogue_text % ["<<" + option_id.to_lower() + ">>"]
	dialogue_interactable.dialogue = repeat_dialogue
	mask.play(option_id)
	
