extends Technician
class_name Station2Technician

@export var broken_atm_interactable: Interactable
#relative to the broken atm interactable
@export var broken_atm_fix_location := Vector2(0, 10)
@export var after_broken_atm_goto := Vector2(40, 10)
@export var speed_after_atm_explosion := 25.0
@export var no_fix_dialogue: Dialogue

func _ready():
	_state = State.ACTING
	#_interactable.interacted.connect(_on_first_interaction)
	_panel.option_confirmed.connect(_on_option_confirmed)

func _on_option_confirmed(option_id: StringName):
	if option_id == &"follow_me":
		_player.movement_disabled = true
		_collision_shape.disabled = true
		await go_to(_player.trail_marker.global_position)
		_state = State.FOLLOWING
		_set_interactable(false)
		_player.movement_disabled = false
	broken_atm_interactable.active = true
	broken_atm_interactable.interacted.connect(_on_broken_atm_interacted)

func _on_first_interaction():
	_state = State.FOLLOWING
	pass

func _on_broken_atm_interacted():
	await go_to(broken_atm_interactable.global_position + \
		broken_atm_fix_location)
	_state = State.ACTING
	_sprite.play("fix_start")
	await _sprite.animation_finished
	walk_speed = speed_after_atm_explosion
	await go_to(broken_atm_interactable.global_position + \
		after_broken_atm_goto)
	_interactable.dialogue = no_fix_dialogue
	_interactable.interact()
	_collision_shape.disabled = false
	_state = State.IDLE
