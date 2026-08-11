@tool

extends Node2D

class_name Train

@export var next_scene: Enums.Scenes = Enums.Scenes.LEVEL_1
@export var reload_scene: Enums.Scenes = Enums.Scenes.LEVEL_0
@export var level_clear_time_cost_minutes: int = 5

# Animation parameters
@export var depart_offset: Vector2 = Vector2(800, 0)
@export var depart_duration: float = 1.5
@export var arrival_offset: Vector2 = Vector2(-800, 0)
@export var arrival_duration: float = 1.5

@export var incorrect_penalty_minutes: int = 5
## Time cost for trying to board with no ticket / wrong ticket for this train
@export var no_ticket_penalty_minutes: int = 3
## The delay before the train arrives at the platform after missing the deadline
@export var missed_rearrive_delay: float = 8.0
## If true, this train leaves on its own when a matching ticket's deadline passes
@export var departs_on_missed_deadline: bool = true
## Ticket id this train accepts (e.g. red_east / red_west).
@export var ticket_id: StringName = &"red_east"
## Player walk speed while boarding or exiting the train.
@export var board_walk_speed: float = 80.0
## Extra downward camera nudge while the player walks out of the train.
@export var disembark_camera_offset_y: float = 0.0

@export var sprite: AnimatedSprite2D
@export var color := Enums.TrainColor.BROWN:
	# Ensure that index of animation names matches the order of the Enums
	set(new_color):
		color = new_color
		if sprite:
			sprite.play(Enums.TrainColor.find_key(color))

@onready var _no_ticket_light: Sprite2D = $NoTicketLight
@onready var _boarded_player_l: Sprite2D = $BoardedPlayerL
@onready var _boarded_player_r: Sprite2D = $BoardedPlayerR
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var train_interactable_l: TrainInteractable = $TrainInteractableL
@onready var train_interactable_r: TrainInteractable = $TrainInteractableR

var _boarding: bool = false
var _missed_departure: bool = false
var _l_or_r: String

@onready var player_disembark_marker: Marker2D = $PlayerDisembarkMarker
@onready var player_embark_marker: Marker2D = $PlayerEmbarkMarker

@onready var original_position = position


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_no_ticket_light.visible = false
	_boarded_player_l.visible = false
	_boarded_player_r.visible = false
	TimeManager.time_changed.connect(_on_time_changed)
	Inventory.inventory_changed.connect(_on_inventory_changed)
	play_bobbing()

	for i: AnimatedSprite2D in $TrainSprite/HoverSparcles.get_children():
		i.frame = randi() % 2
		i.play(&"", 0.5)


func try_board(interactable: TrainInteractable, l_or_r: String) -> void:
	_l_or_r = l_or_r
	if _boarding:
		return

	var ticket: TicketData = Inventory.get_ticket()
	print("board result: ", interactable.evaluate_board(ticket))
	match interactable.evaluate_board(ticket):
		Enums.BoardResult.REJECTED:
			_boarding = true
			AudioManager.play_wrong_ticket_sfx()
			TimeManager.apply_penalty(no_ticket_penalty_minutes)
			await _flash_reject(_no_ticket_light)
			_boarding = false
			return
		Enums.BoardResult.TOO_LATE:
			await _missed_departure_sequence()
			return
		Enums.BoardResult.WRONG_TRAIN:
			SignalBus.ticket_consumed.emit()
			await _wrong_train_sequence()
			return
		Enums.BoardResult.SUCCESS:
			SignalBus.ticket_consumed.emit()
			await _boarding_sequence()


func _on_time_changed(_hour: int, _minute: int, _second: int) -> void:
	if not departs_on_missed_deadline:
		return
	if _boarding or _missed_departure:
		return
	var ticket: TicketData = Inventory.get_ticket()
	if ticket == null or not _matches_ticket(ticket):
		return
	if TimeManager.has_at_least(
		ticket.departure_hours,
		ticket.departure_minutes,
		ticket.departure_seconds,
	):
		return
	_missed_departure = true
	_missed_departure_sequence()


func _on_inventory_changed() -> void:
	# If the player buys a still-valid matching ticket, reset the missed departure flag
	var ticket: TicketData = Inventory.get_ticket()
	if ticket == null or not _matches_ticket(ticket):
		return
	if not TimeManager.has_at_least(
		ticket.departure_hours,
		ticket.departure_minutes,
		ticket.departure_seconds,
	):
		return
	_missed_departure = false


func _boarding_sequence() -> void:
	_boarding = true
	await _run_boarding_and_departure(true)

	TimeManager.advance_minutes(level_clear_time_cost_minutes)
	GameManager.load_scene(next_scene)
	_boarding = false


func _wrong_train_sequence() -> void:
	_boarding = true
	await _run_boarding_and_departure(true)

	TimeManager.stash_before_reload(incorrect_penalty_minutes)

	GameManager.load_scene(reload_scene)
	_boarding = false


func _missed_departure_sequence() -> void:
	if _boarding:
		return
	_boarding = true
	_missed_departure = true
	_set_interactables_enabled(false)
	SignalBus.missed_train.emit()

	await _train_depart()
	await get_tree().create_timer(missed_rearrive_delay).timeout
	await play_simple_arrival_animation()

	_set_interactables_enabled(true)
	_boarding = false


## Flashes a light on and off for a given number of times
func _flash_reject(light: Sprite2D, flashes: int = 3, interval: float = 0.5) -> void:
	SignalBus.no_ticket.emit()
	for i in flashes:
		light.visible = true
		await get_tree().create_timer(interval).timeout
		light.visible = false
		await get_tree().create_timer(interval).timeout


func _train_depart() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)

	tween.tween_property(self, "position", position + depart_offset, depart_duration)

	await tween.finished


func play_arrival_animation() -> void:
	animation_player.play("RESET")
	AudioManager.play_train_pulling_in()
	var player := get_tree().get_first_node_in_group("player")
	_set_player_active(false)

	var stop_position: Vector2 = position
	position = stop_position + arrival_offset
	_boarded_player_l.visible = true

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", stop_position, arrival_duration)
	await tween.finished

	await _open_doors()

	_boarded_player_l.visible = false
	if player:
		var remote: RemoteTransform2D = player.get_node_or_null("RemoteTransform2D")
		var remote_rest := Vector2.ZERO
		var start_global: Vector2 = (
			player_embark_marker.global_position
			if player_embark_marker
			else player.global_position
		)
		if remote:
			remote_rest = remote.position
			# Keep the camera at platform height so snapping into the seat doesn't jump up.
			var seat_to_platform_y := 0.0
			if player_disembark_marker:
				seat_to_platform_y = (
					player_disembark_marker.global_position.y - start_global.y
				)
			remote.position.y = remote_rest.y + seat_to_platform_y + disembark_camera_offset_y

		player.global_position = start_global
		player.visible = true
		if player_disembark_marker and player.has_method("walk_to"):
			if remote:
				var walk_duration : float = (
					player.global_position.distance_to(player_disembark_marker.global_position)
					/ board_walk_speed
				)
				var cam_tween := create_tween()
				cam_tween.tween_property(remote, "position", remote_rest, walk_duration)
			await player.walk_to(
				player_disembark_marker.global_position,
				board_walk_speed,
			)
		elif remote:
			remote.position = remote_rest

	await _close_doors()
	_set_player_active(true)
	play_bobbing()


func play_simple_arrival_animation(use_level_0_first_sound: bool = false) -> void:
	animation_player.play("RESET")
	if use_level_0_first_sound:
		AudioManager.play_level_0_first_train_in()
	else:
		AudioManager.play_train_pulling_in()
	var stop_position: Vector2 = original_position
	position = stop_position + arrival_offset

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", stop_position, arrival_duration)
	await tween.finished
	play_bobbing()


func play_bobbing() -> void:
	animation_player.play("bobbing")


func _set_player_active(active: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.visible = active
	player.movement_disabled = not active
	player.set_physics_process(active)


func _matches_ticket(ticket: TicketData) -> bool:
	return ticket_id.to_lower() == ticket.id.to_lower()


func _set_interactables_enabled(enabled: bool) -> void:
	for interactable in [train_interactable_l, train_interactable_r]:
		if interactable == null:
			continue
		interactable.set_deferred("monitoring", enabled)
		interactable.set_deferred("monitorable", enabled)
		interactable.visible = enabled


func _open_doors() -> void:
	animation_player.play("doors_open")
	await animation_player.animation_finished


func _close_doors() -> void:
	animation_player.play("doors_close")
	await animation_player.animation_finished


## Embark marker for the door being used (mirrored to the right side when boarding R).
func _embark_global_position() -> Vector2:
	var local := player_embark_marker.position
	if _l_or_r == "r":
		local.x = -local.x
	return to_global(local)


func _run_boarding_and_departure(play_pulling_out: bool = false) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.movement_disabled = true
		player.set_physics_process(false)
		player.visible = true

	# 与开门动画同时开始播放
	if play_pulling_out:
		AudioManager.play_train_pulling_out()

	await _open_doors()

	var board_marker: Sprite2D = _boarded_player_l if _l_or_r == "l" else _boarded_player_r
	if player and player_embark_marker and player.has_method("walk_to"):
		await player.walk_to(_embark_global_position(), board_walk_speed, true)

	if player:
		player.visible = false
	board_marker.visible = true

	await _close_doors()
	await _train_depart()

	if play_pulling_out:
		await AudioManager.wait_for_train_sfx()
