@tool

extends Node2D

class_name Train

@export var next_scene: Enums.Scenes = Enums.Scenes.LEVEL_1
@export var reload_scene: Enums.Scenes = Enums.Scenes.LEVEL_0
@export var level_clear_time_cost_minutes: int = 5
@export var direction: Enums.TrainDirection
##this is just the string to display on the departure board and has no game impact
@export var destination := "??"
##The platform script will override this at runtime
var platform_number := 0

@export_group("Audio")
@export var pulling_in_sound: AudioStream
@export var pulling_in_no_doors_sound: AudioStream
@export var pulling_out_sound: AudioStream
@export var pulling_out_no_doors_sound: AudioStream

# Animation parameters
@export_group("Animation")
##The offset distance of the train from the platform on arrival and departure
##for North/South trains
@export var arrival_distance_vertical := 4800.0
##The offset distance of the train from the platform on arrival and departure
##for East/West trains
@export var arrival_distance_horizontal := 4800.0
var depart_offset: Vector2
@export var depart_duration: float = 3.0
var arrival_offset: Vector2
@export var arrival_duration: float = 3.0
## Player walk speed while boarding or exiting the train.
@export var board_walk_speed: float = 80.0
## Extra downward camera nudge while the player walks out of the train.
@export var disembark_camera_offset_y: float = 0.0
@export var player_start_offset_horizontal := Vector2(0,0)
@export var player_start_offset_vertaical := Vector2(0,0)

@export_group('Gameplay')

@export var incorrect_penalty_minutes: int = 5
## Time cost for trying to board with no ticket / wrong ticket for this train
@export var no_ticket_penalty_minutes: int = 3
## The delay before the train arrives at the platform after missing the deadline
@export var missed_rearrive_delay: float = 8.0
## If true, this train leaves on its own when a matching ticket's deadline passes
#@export var departs_on_missed_deadline: bool = true


@export_group('Visual')
@export var sprite: AnimatedSprite2D
@export var color := Enums.TrainColor.BROWN:
	# Ensure that index of animation names matches the order of the Enums
	set(new_color):
		color = new_color
		if sprite:
			sprite.play(Enums.TrainColor.find_key(color))

@export_group('Debug')
##If true, always evaluates to wrong train
@export var bypass_ticket_requirement := true

@onready var _no_ticket_light: Sprite2D = $TrainSprite/NoTicketLight
@onready var _boarded_player_l: Sprite2D = $BoardedPlayerL
@onready var _boarded_player_r: Sprite2D = $BoardedPlayerR
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var train_interactable_l: TrainInteractable = $TrainInteractableL
@onready var train_interactable_r: TrainInteractable = $TrainInteractableR
@onready var _pulling_in_player: AudioStreamPlayer2D = $PullingInPlayer2D
@onready var _pulling_out_player: AudioStreamPlayer2D = $PullingOutPlayer2D

var _boarding: bool = false
#var _missed_departure: bool = false
var _l_or_r: String

@onready var player_disembark_marker: Marker2D = $PlayerDisembarkMarker
@onready var player_embark_marker: Marker2D = $PlayerEmbarkMarker

@onready var original_position = position


func _ready() -> void:
	add_to_group("trains")
	if Engine.is_editor_hint():
		return
	_no_ticket_light.visible = false
	_boarded_player_l.visible = false
	_boarded_player_r.visible = false
	#TimeManager.time_changed.connect(_on_time_changed)
	#Inventory.inventory_changed.connect(_on_inventory_changed)
	play_bobbing()

	for i: AnimatedSprite2D in $TrainSprite/HoverSparcles.get_children():
		i.frame = randi() % 2
		i.play(&"", 0.5)
		
	arrival_offset = _get_arrival_offset_vector()
	depart_offset = _get_departure_offset_vector()

func try_board(l_or_r: String) -> void:
	_l_or_r = l_or_r
	if _boarding:
		return

	var ticket: TicketData = Inventory.get_ticket()
	print("board result: ", evaluate_board(ticket))
	match evaluate_board(ticket):
		Enums.BoardResult.REJECTED:
			_boarding = true
			AudioManager.play_wrong_ticket_sfx()
			TimeManager.apply_penalty(no_ticket_penalty_minutes)
			await _flash_reject(_no_ticket_light)
			_boarding = false
			return
		#Enums.BoardResult.TOO_LATE:
			#await _missed_departure_sequence()
			#return
		Enums.BoardResult.WRONG_TRAIN:
			await _wrong_train_sequence()
			return
		Enums.BoardResult.SUCCESS:
			await _boarding_sequence()

## Evaluates whether the player can board the train
func evaluate_board(ticket: TicketData) -> Enums.BoardResult:
	if bypass_ticket_requirement:
		return Enums.BoardResult.WRONG_TRAIN
	# No ticket, or ticket is for a different train.
	if (ticket == null or not _matches_ticket(ticket)):
		return Enums.BoardResult.REJECTED
	# Ticket matches this train, but is on the wrong line for the level.
	if not _is_correct_line(ticket):
		return Enums.BoardResult.WRONG_TRAIN
	#if not _is_on_time(ticket):
		#return Enums.BoardResult.TOO_LATE
	return Enums.BoardResult.SUCCESS

#func _on_time_changed(_hour: int, _minute: int, _second: int) -> void:
	#if not departs_on_missed_deadline:
		#return
	#if _boarding or _missed_departure:
		#return
	#var ticket: TicketData = Inventory.get_ticket()
	#if ticket == null or not _matches_ticket(ticket):
		#return
	#
	#if TimeManager.has_at_least(
		#ticket.departure_hours,
		#ticket.departure_minutes,
		#ticket.departure_seconds,
	#):
		#return
	#_missed_departure = true
	## Should probably be renamed into just "departure_sequence" with schedule system 🚩
	#_missed_departure_sequence()

func _matches_ticket(ticket: TicketData) -> bool:
	return (
		direction == ticket.direction and 
		color == ticket.train_line
	)

## Checks if the ticket is on this level's correct line
func _is_correct_line(ticket: TicketData) -> bool:
	var level := get_tree().current_scene as LevelTemplate
	if level == null:
		return true
	return (
		ticket.train_line == level.correct_train_line and
		ticket.direction == level.correct_train_direction
	)

#func _is_on_time(ticket: TicketData) -> bool:
	#return TimeManager.has_at_least(ticket.departure_hours, 
		#ticket.departure_minutes, ticket.departure_seconds)

#func _on_inventory_changed() -> void:
	## If the player buys a still-valid matching ticket, reset the missed departure flag
	#var ticket: TicketData = Inventory.get_ticket()
	#if ticket == null or not _matches_ticket(ticket):
		#return
	#if not TimeManager.has_at_least(
		#ticket.departure_hours,
		#ticket.departure_minutes,
		#ticket.departure_seconds,
	#):
		#return
	#_missed_departure = false


func _boarding_sequence() -> void:
	_boarding = true
	await _run_boarding_and_departure(true)

	TimeManager.advance_minutes(level_clear_time_cost_minutes)
	GameManager.load_scene(next_scene)
	_boarding = false


func _wrong_train_sequence() -> void:
	_boarding = true
	await _run_boarding_and_departure(true)
	GameManager.play_scene_concurrently(Enums.Scenes.WRONG_TRAIN)
	await get_tree().create_timer(5).timeout

	TimeManager.stash_before_reload(incorrect_penalty_minutes)

	GameManager.load_scene(reload_scene)
	_boarding = false


#func _missed_departure_sequence() -> void:
	#if _boarding:
		#return
	#_boarding = true
	#_missed_departure = true # Maybe remove when switching to schedule 🚩
	#_set_interactables_enabled(false)
	#SignalBus.missed_train.emit()
#
	## await train_depart() # Currently removed since schedule will handle this
	#await get_tree().create_timer(missed_rearrive_delay).timeout
	#await play_arrival_animation(false)
#
	#_set_interactables_enabled(true)
	#_boarding = false


## Flashes a light on and off for a given number of times
func _flash_reject(light: Sprite2D, flashes: int = 3, interval: float = 0.5) -> void:
	SignalBus.no_ticket.emit()
	for i in flashes:
		light.visible = true
		await get_tree().create_timer(interval).timeout
		light.visible = false
		await get_tree().create_timer(interval).timeout


func train_depart(play_pulling_out_sfx = false) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if play_pulling_out_sfx:
		play_pulling_out(true)

	tween.tween_property(self, "position", position + depart_offset, depart_duration)

	await tween.finished

func call_train() -> void:
	print("train called")
	play_arrival_animation(false)

func play_arrival_animation(include_player = true) -> void:
	print("playing arrival animation")
	animation_player.play("RESET")

	var stop_position: Vector2 = original_position
	position = stop_position + arrival_offset

	var player := get_tree().get_first_node_in_group("player") as PlayerCharacter
	if include_player and player:
		player.global_position = player_disembark_marker.global_position - arrival_offset
		play_pulling_in()
		player.set_active(false)
	else:
		play_pulling_in(true)

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", stop_position, arrival_duration)
	await tween.finished

	if not include_player or not player:
		play_bobbing()
		return
	
	_boarded_player_l.visible = true
	await _open_doors()
	_boarded_player_l.visible = false

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
	
	player.set_active(true)
	
	train_depart()
	#play_bobbing()

func play_bobbing() -> void:
	animation_player.play("bobbing")

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


func _run_boarding_and_departure(should_play_pulling_out: bool = false) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.movement_disabled = true
		player.set_physics_process(false)
		player.visible = true

	# 与开门动画同时开始播放
	if should_play_pulling_out:
		play_pulling_out()

	await _open_doors()

	var board_marker: Sprite2D = _boarded_player_l if _l_or_r == "l" else _boarded_player_r
	if player and player_embark_marker and player.has_method("walk_to"):
		await player.walk_to(_embark_global_position(), board_walk_speed, true)

	if player:
		player.visible = false
	board_marker.visible = true
	SignalBus.ticket_consumed.emit()

	await _close_doors()
	await train_depart()

	if should_play_pulling_out:
		await wait_for_pulling_out()

	var ticket := Inventory.get_ticket()
	if ticket != null:
		Inventory.remove_item(ticket)


func play_pulling_in(no_doors: bool = false) -> void:
	var stream := pulling_in_no_doors_sound if no_doors else pulling_in_sound
	_play_train_sound(_pulling_in_player, stream)


func play_pulling_out(no_doors: bool = false) -> void:
	var stream := pulling_out_no_doors_sound if no_doors else pulling_out_sound
	_play_train_sound(_pulling_out_player, stream)


func wait_for_pulling_in() -> void:
	while _pulling_in_player.playing:
		await get_tree().process_frame


func wait_for_pulling_out() -> void:
	while _pulling_out_player.playing:
		await get_tree().process_frame


func stop_train_audio() -> void:
	_pulling_in_player.stop()
	_pulling_out_player.stop()


func _play_train_sound(player: AudioStreamPlayer2D, stream: AudioStream) -> void:
	if stream == null:
		return
	if player.playing and player.stream == stream:
		return
	player.stop()
	player.stream = stream
	player.play()

func _get_arrival_offset_vector() -> Vector2:
	match direction:
		Enums.TrainDirection.NORTH:
			return Vector2(0, arrival_distance_vertical)
		Enums.TrainDirection.SOUTH:
			return Vector2(0, -1.0 * arrival_distance_vertical)
		Enums.TrainDirection.EAST:
			return Vector2(-1.0 * arrival_distance_horizontal, 0)
		Enums.TrainDirection.WEST:
			return Vector2(arrival_distance_horizontal, 0)
		_:
			return Vector2(0,0)

func _get_departure_offset_vector() -> Vector2:
	return _get_arrival_offset_vector() * -1.0
