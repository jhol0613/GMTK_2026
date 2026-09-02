extends Technician
class_name Station2Technician

@export var atm: ATM
@export var atm_guy: ATMGuy
#relative to the broken atm interactable
@export_group("Animation Sequence")
@export var broken_atm_fix_location := Vector2(0, 10)
@export var after_broken_atm_goto := Vector2(40, 10)
@export var stand_after_atm_explosion := 1.5
@export var walk_after_standing := 1.5
@export var speed_after_atm_explosion := 25.0
@export var no_fix_dialogue: Dialogue

func _ready():
	#super._ready()
	_state = State.ACTING
	#_interactable.interacted.connect(_on_first_interaction)
	_panel.option_confirmed.connect(_on_option_confirmed)
	setup_fixing_sfx()

##Parent function has you starting patrol, which we don't want to do
func _on_panel_closed():
	pass

func _on_option_confirmed(option_id: StringName):
	if option_id == &"follow_me":
		_player.movement_disabled = true
		_collision_shape.disabled = true
		atm_guy.visible = false
		await go_to(_player.trail_marker.global_position)
		_state = State.FOLLOWING
		_set_interactable(false)
		_player.movement_disabled = false
	atm.dialog_interactable.active = true
	atm.dialog_interactable.interacted.connect(_on_broken_atm_interacted)

func _on_broken_atm_interacted():
	atm.dialog_interactable.interacted.disconnect(_on_broken_atm_interacted)
	await go_to(atm.dialog_interactable.global_position + \
		broken_atm_fix_location)
	_state = State.ACTING
	_sprite.play("fix_start")
	_set_interactable(false)
	await _sprite.animation_finished
	await atm.explode()
	await get_tree().create_timer(stand_after_atm_explosion).timeout
	_sprite.play("stand_up")
	await _sprite.animation_finished
	await get_tree().create_timer(walk_after_standing).timeout
	walk_speed = speed_after_atm_explosion
	await go_to(atm.dialog_interactable.global_position + \
		after_broken_atm_goto)
	_interactable.dialogue = no_fix_dialogue
	_interactable.interact()
	_collision_shape.disabled = false
	_state = State.IDLE
