extends Node2D

const PURCHASE_OUTCOME: StringName = &"bought_coffee"

@export var slow_duration_minutes: int = 2
@export var time_scale_while_active: float = 0.5

@export var normal_dialogue: Dialogue
@export var broke_dialogue: Dialogue

@onready var _dialogue_panel: DialoguePanel = $DialoguePanel
@onready var _interactable: DialogueInteractable = $DialogueInteractable


func _ready() -> void:
	_dialogue_panel.option_confirmed.connect(_on_option_confirmed)
	Wallet.tokens_changed.connect(_on_tokens_changed)
	_refresh_offer()


func _on_tokens_changed(_current: int, _maximum: int) -> void:
	_refresh_offer()


## Swap the dialogue between "you may buy" and "you cannot afford this".
func _refresh_offer() -> void:
	if Wallet.can_afford(Wallet.COFFEE_COST):
		_interactable.dialogue = normal_dialogue
		return
	_interactable.dialogue = broke_dialogue


func _on_option_confirmed(outcome_id: StringName) -> void:
	if outcome_id != PURCHASE_OUTCOME:
		return
	if not Wallet.spend(Wallet.COFFEE_COST):
		return
	TimeManager.set_time_scale(
		time_scale_while_active,
		slow_duration_minutes
	)
