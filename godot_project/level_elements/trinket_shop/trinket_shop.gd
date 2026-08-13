extends Node2D


const PURCHASE_OUTCOME: StringName = &"sold_trinket"

@onready var _dialogue_panel: DialoguePanel = $DialoguePanel


func _ready() -> void:
	_dialogue_panel.option_confirmed.connect(_on_option_confirmed)


func _on_option_confirmed(outcome_id: StringName) -> void:
	if outcome_id == &"cancel":
		_dialogue_panel.hide_popup.call_deferred()
		return
	if outcome_id != PURCHASE_OUTCOME:
		return
	Wallet.spend(Wallet.TRINKET_COST)
