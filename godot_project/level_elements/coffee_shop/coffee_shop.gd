extends Node2D

const PURCHASE_OUTCOME: StringName = &"bought_coffee"

@export var slow_duration_minutes: int = 2
@export var time_scale_while_active: float = 0.5
## Shown instead of the normal lines when the player cannot afford a coffee.
## Left empty a placeholder line is used, so the refusal always says something.
@export var broke_lines: Array[DialogueLine] = []
@export var broke_placeholder_text: String = "[placeholder] Not enough charge."

@onready var _dialogue_panel: DialoguePanel = $DialoguePanel
@onready var _interactable: DialogueInteractable = $DialogueInteractable

var _normal_lines: Array[DialogueLine] = []
var _normal_choices: Array[DialogueChoice] = []


func _ready() -> void:
	_normal_lines = _interactable.lines
	_normal_choices = _interactable.choices

	if broke_lines.is_empty():
		var placeholder := DialogueLine.new()
		placeholder.text = broke_placeholder_text
		if not _normal_lines.is_empty():
			placeholder.speaker = _normal_lines[0].speaker
			placeholder.speaker_icon = _normal_lines[0].speaker_icon
		broke_lines = [placeholder]

	_dialogue_panel.option_confirmed.connect(_on_option_confirmed)
	Wallet.tokens_changed.connect(_on_tokens_changed)
	_refresh_offer()


func _on_tokens_changed(_current: int, _maximum: int) -> void:
	_refresh_offer()


## Swap the dialogue between "you may buy" and "you cannot afford this".
func _refresh_offer() -> void:
	if Wallet.can_afford(Wallet.COFFEE_COST):
		_interactable.lines = _normal_lines
		_interactable.choices = _normal_choices
		return
	_interactable.choices = []
	_interactable.lines = broke_lines


func _on_option_confirmed(outcome_id: StringName) -> void:
	if outcome_id != PURCHASE_OUTCOME:
		return
	if not Wallet.spend(Wallet.COFFEE_COST):
		return
	TimeManager.set_time_scale(
		time_scale_while_active,
		slow_duration_minutes
	)
