extends Npc

@export_group("Dialogue Templates")
@export var choice_bank: Dictionary[Enums.TrainColor, DialogueChoice]
@export var initial_dialogue: Dialogue
@export var repeat_dialogue: Dialogue
@export var nevermind_choice: DialogueChoice
@export var give_item_choice_text: String
@export var happy_repeat_text: String
@export var sad_repeat_text: String
@export var happy_portrait: Texture2D
@export var sad_portrait: Texture2D

@export_group("Audio")
@export var cry_clips: Array[AudioStream] = []
@export_range(1.0, 1.5, 0.01) var cry_pitch_variation := 1.1
@export var cry_gap_min := 0.0
@export var cry_gap_max := 1.6

@export_group("Animation")
@export var happy_time = 5.0
@export var dropped_mask_offset := Vector2(0.0, 10.0)
@export var mask_drop_delay := 1.0

var _mask_original_position
var _happy = false
var _previous_outcome_id: StringName

@onready var dialogue_interactable := $DialogueInteractable
@onready var panel := $DialoguePanel
@onready var mask := $Sprite/Mask
@onready var _cry_player: AudioStreamPlayer2D = $CryLoop
@onready var _laugh_player: AudioStreamPlayer2D = $Laugh
@onready var _drop_player: AudioStreamPlayer2D = $MumbleAndDrop

var _crying := true
var _mask_generation := 0


var happy_timer: SceneTreeTimer

func _ready():
	panel.option_confirmed.connect(_on_option_confirmed)
	dialogue_interactable.dialogue = initial_dialogue
	_state = State.ACTING
	_mask_original_position = mask.position
	_cry_player.stream = _build_cry_randomizer()
	_cry_player.finished.connect(_queue_next_sob)
	_sob()


func _build_cry_randomizer() -> AudioStreamRandomizer:
	var randomizer := AudioStreamRandomizer.new()
	randomizer.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
	randomizer.random_pitch = cry_pitch_variation
	for clip in cry_clips:
		randomizer.add_stream(-1, clip)
	return randomizer


func _sob() -> void:
	if _sprite.animation == &"throw":
		_sprite.play("idle")
	if _crying and not cry_clips.is_empty():
		_cry_player.play()


func _queue_next_sob() -> void:
	if not _crying:
		return
	await get_tree().create_timer(randf_range(cry_gap_min, cry_gap_max)).timeout
	_sob()

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
	_crying = false
	_mask_generation += 1
	_cry_player.stop()
	if _laugh_player.stream != null:
		_laugh_player.play()
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
	var generation := _mask_generation
	repeat_dialogue.lines[0].speaker_icon = sad_portrait
	repeat_dialogue.lines[0].text = \
		"%s <<trinketmask>> <<angry>> <<i>> <<buy>> next <<trinketmask>>" % ["<<" + outcome_id.to_lower() + ">>"]
	happy_timer.timeout.disconnect(_on_no_longer_happy)
	if _drop_player.stream != null:
		_drop_player.play()
	if mask_drop_delay > 0.0:
		await get_tree().create_timer(mask_drop_delay).timeout
	_sprite.play("throw")
	mask.position = _mask_original_position + dropped_mask_offset
	if _drop_player.playing:
		await _drop_player.finished
	if generation != _mask_generation:
		return
	_crying = true
	_queue_next_sob()
