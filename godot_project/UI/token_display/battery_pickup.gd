extends Node2D


func _on_dialogue_panel_option_confirmed(outcome_id: StringName) -> void:
	if outcome_id == &"GOT_BATTERY":
		Wallet.enable(true)
		visible = false
