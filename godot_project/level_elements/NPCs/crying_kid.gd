extends Npc

@export_group("Dialogue Templates")
@export var choice_bank: Dictionary[Enums.TrainColor, DialogueChoice]
@export var initial_dialogue: Dialogue
@export var repeat_dialogue: Dialogue
@export var nevermind_choice: DialogueChoice
@export var give_item_choice_text: String
@export var happy_repeat_text: String
#%s <<trinketmask>> <<thankyou>>
@export var sad_repeat_text: String
#%s <<trinketmask>> <<angry>> <<i>> <<buy>> next <<trinketmask>>
@export var happy_portrait: Texture2D
@export var sad_portrait: Texture2D

@export_group("Animation")
##Kid will start crying after this amount of time (in Resshan seconds)
@export var happy_time = 5.0
@export var dropped_mask_offset := Vector2(0.0, 10.0)

var _mask_original_position
var _happy = false
var _previous_outcome_id: StringName

@onready var dialogue_interactable := $DialogueInteractable
@onready var panel := $DialoguePanel
@onready var mask := $Sprite/Mask


var happy_timer: SceneTreeTimer

func _ready():
	panel.option_confirmed.connect(_on_option_confirmed)
	dialogue_interactable.dialogue = initial_dialogue
	##Overrides normal NPC behavior
	_state = State.ACTING
	_mask_original_position = mask.position

func _on_dialogue_interactable_interacted() -> void:
	var _choices : Array[DialogueChoice] = dialogue_interactable.dialogue.choices
	_choices.clear()
	_choices.append(nevermind_choice)
	if  happy_timer and happy_timer.timeout.is_connected(_on_no_longer_happy):
		happy_timer.timeout.disconnect(_on_no_longer_happy)
	for key in choice_bank.keys():
		var color_str = str(Enums.TrainColor.find_key(key))
		var item = Inventory.get_item("mask_" + color_str.to_lower())
		if item:
			choice_bank[key].player_text = give_item_choice_text % [item.item_name]
			_choices.append(choice_bank[key])

func _on_option_confirmed(outcome_id: StringName):
	if outcome_id == &"NONE":
		if _happy:
			happy_timer = get_tree().create_timer(happy_time)
			happy_timer.timeout.connect(_on_no_longer_happy.bind(_previous_outcome_id))
		return
	if happy_timer and happy_timer.timeout.is_connected(_on_no_longer_happy):
		happy_timer.timeout.disconnect(_on_no_longer_happy)
	_happy = true
	Inventory.remove_item(Inventory.get_item("mask_" + outcome_id.to_lower()))
	repeat_dialogue.lines[0].text = \
		"%s <<trinketmask>> <<thankyou>>" % ["<<" + outcome_id.to_lower() + ">>"]
	repeat_dialogue.lines[0].speaker_icon = happy_portrait
	dialogue_interactable.dialogue = repeat_dialogue
	happy_timer = get_tree().create_timer(happy_time)
	happy_timer.timeout.connect(_on_no_longer_happy.bind(outcome_id))
	_previous_outcome_id = outcome_id
	_sprite.play("happy")
	mask.position = _mask_original_position
	mask.visible = true
	mask.play(outcome_id)

func _on_no_longer_happy(outcome_id: StringName):
	_sprite.play("idle")
	repeat_dialogue.lines[0].speaker_icon = sad_portrait
	repeat_dialogue.lines[0].text = \
		sad_repeat_text % ["<<" + outcome_id.to_lower() + ">>"]
	happy_timer.timeout.disconnect(_on_no_longer_happy)
	mask.position += dropped_mask_offset
