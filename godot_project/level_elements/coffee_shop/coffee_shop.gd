extends Node2D

const PURCHASE_OUTCOME: StringName = &"bought_coffee"

@export var slow_duration_minutes: int = 5
@export var time_scale_while_active: float = 0.5

@onready var _dialogue_panel: DialoguePanel = $DialoguePanel


func _ready() -> void:
	_dialogue_panel.option_confirmed.connect(_on_option_confirmed)


func _on_option_confirmed(outcome_id: StringName) -> void:
	_dialogue_panel.hide_popup.call_deferred()
	if outcome_id != PURCHASE_OUTCOME:
		return
	if not Wallet.spend(Wallet.COFFEE_COST):
		return
	TimeManager.set_time_scale(time_scale_while_active, slow_duration_minutes)
