@tool

extends Node2D

class_name Train

@export var next_scene: Enums.Scenes = Enums.Scenes.LEVEL_1

# Animation parameters
@export var depart_offset: Vector2 = Vector2(800, 0)
@export var depart_duration: float = 1.5
@export var arrival_offset: Vector2 = Vector2(-800, 0)
@export var arrival_duration: float = 1.5
# TODO: use actual marker instead of hardcoded value
@export var player_disembark_marker: Vector2 = Vector2(55, -51)

@export var incorrect_penalty_minutes: int = 5
@export var reload_scene: Enums.Scenes = Enums.Scenes.LEVEL_0

@export var sprite: AnimatedSprite2D
@export var color := Enums.TrainColor.BROWN:
	# Ensure that index of animation names matches the order of the Enums
	set(new_color):
		color = new_color
		if sprite:
			sprite.play(Enums.TrainColor.find_key(color))

@onready var _no_ticket_light: Sprite2D = $NoTicketLight
@onready var _boarded_player: Sprite2D = $BoardedPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _boarding: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_no_ticket_light.visible = false
	_boarded_player.visible = false


func try_board(interactable: TrainInteractable) -> void:
	if _boarding:
		return

	var ticket: TicketData = Inventory.get_ticket()
	match interactable.evaluate_board(ticket):
		Enums.BoardResult.REJECTED:
			await _flash_reject(_no_ticket_light)
			return
		Enums.BoardResult.WRONG_TRAIN:
			await _wrong_train_sequence()
			return
		Enums.BoardResult.SUCCESS:
			await _boarding_sequence()


func _boarding_sequence() -> void:
	_boarding = true

	_set_player_active(false)
	await _run_boarding_and_departure()

	GameManager.load_scene(next_scene)
	_boarding = false


func _wrong_train_sequence() -> void:
	_boarding = true

	_set_player_active(false)
	await _run_boarding_and_departure()
	
	_apply_penalty()

	GameManager.load_scene(reload_scene)
	_boarding = false


## Flashes a light on and off for a given number of times
func _flash_reject(light: Sprite2D, flashes: int = 3, interval: float = 0.5) -> void:
	for i in flashes:
		light.visible = true
		await get_tree().create_timer(interval).timeout
		light.visible = false
		await get_tree().create_timer(interval).timeout


func _train_depart() -> void:
	var tween := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", position + depart_offset, depart_duration)
	await tween.finished


## Plays the arrival animation on scene start
func play_arrival_animation() -> void:
	var player := get_tree().get_first_node_in_group("player")
	player.visible = false
	player.set_physics_process(false)

	var stop_position: Vector2 = position
	position = stop_position + arrival_offset
	_boarded_player.visible = true

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", stop_position, arrival_duration)
	await tween.finished

	animation_player.play("doors_open")
	await animation_player.animation_finished

	# inside train to platform
	_boarded_player.visible = false
	if player_disembark_marker:
		player.global_position = player_disembark_marker
	player.visible = true
	animation_player.play("doors_close")
	await animation_player.animation_finished
	player.set_physics_process(true)


#---------------------------------------------------------
# Helper functions
#---------------------------------------------------------
func _set_player_active(active: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.visible = active
	player.set_physics_process(active)


func _apply_penalty() -> void:
	var time_node: Control = get_tree().get_first_node_in_group("time")
	if time_node:
		GameManager.stash_time_before_reload(
			time_node.rhour,
			time_node.rminute,
			incorrect_penalty_minutes,
		)


func _open_doors() -> void:
	animation_player.play("doors_open")
	await animation_player.animation_finished


func _close_doors() -> void:
	animation_player.play("doors_close")
	await animation_player.animation_finished


func _run_boarding_and_departure() -> void:
	_set_player_active(false)
	await _open_doors()
	_boarded_player.visible = true
	await _close_doors()
	await _train_depart()
