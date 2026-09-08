extends Node2D

@onready var _interactable: Interactable = $DialogueInteractable
@onready var _blocker: CollisionShape2D = $StaticBody2D/CollisionShape2D


## Hides the battery and takes its hitbox out of the world, so it cannot be
## walked into or interacted with before it has been dropped.
func set_active(value: bool) -> void:
	visible = value
	_interactable.active = value
	_blocker.set_deferred("disabled", not value)


func _on_dialogue_panel_option_confirmed(outcome_id: StringName) -> void:
	if outcome_id == &"GOT_BATTERY":
		$PickupSound.play()
		Wallet.enable(true)
		queue_free()
