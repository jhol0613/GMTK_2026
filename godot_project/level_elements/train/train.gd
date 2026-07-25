@tool

extends Node2D

class_name Train

@export var next_scene: Enums.Scenes = Enums.Scenes.LEVEL_1

# Animation parameters
@export var depart_offset: Vector2 = Vector2(800, 0)
@export var depart_duration: float = 1.5
@export var arrival_offset: Vector2 = Vector2(-800, 0)
@export var arrival_duration: float = 1.5

@export var incorrect_penalty_minutes: int = 5
@export var reload_scene: Enums.Scenes = Enums.Scenes.LEVEL_0
## The delay before the train arrives at the platform after missing the deadline
@export var missed_rearrive_delay: float = 8.0
## If true, this train leaves on its own when a matching ticket's deadline passes
@export var departs_on_missed_deadline: bool = true

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

@onready var original_position = position

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_no_ticket_light.visible = false
	_boarded_player_l.visible = false
	_boarded_player_r.visible = false
	TimeManager.time_changed.connect(_on_time_changed)
	Inventory.inventory_changed.connect(_on_inventory_changed)


func try_board(interactable: TrainInteractable, l_or_r: String) -> void:
	_l_or_r = l_or_r
	if _boarding:
		return

	var ticket: TicketData = Inventory.get_ticket()
	match interactable.evaluate_board(ticket):
		Enums.BoardResult.REJECTED:
			await _flash_reject(_no_ticket_light)
			return
		Enums.BoardResult.TOO_LATE:
			await _missed_departure_sequence()
			return
		Enums.BoardResult.WRONG_TRAIN:
			await _wrong_train_sequence()
			return
		Enums.BoardResult.SUCCESS:
			await _boarding_sequence()


func _on_time_changed(_hour: int, _minute: int) -> void:
	if not departs_on_missed_deadline:
		return
	if _boarding or _missed_departure:
		return
	var ticket: TicketData = Inventory.get_ticket()
	if ticket == null or not _matches_ticket(ticket):
		return
	if TimeManager.has_at_least(ticket.departure_hours, ticket.departure_minutes, ticket.departure_seconds):
		return
	_missed_departure = true
	_missed_departure_sequence()


func _on_inventory_changed() -> void:
	_missed_departure = false


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
	
	TimeManager.stash_before_reload(incorrect_penalty_minutes)

	GameManager.load_scene(reload_scene)
	_boarding = false


## Leaves without the player when the ticket deadline is missed.
func _missed_departure_sequence() -> void:
	if _boarding:
		return
	_boarding = true
	_missed_departure = true
	_set_interactables_enabled(false)

	await _train_depart()
	await get_tree().create_timer(missed_rearrive_delay).timeout
	await play_simple_arrival_animation()

	_set_interactables_enabled(true)
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
	_boarded_player_l.visible = true

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", stop_position, arrival_duration)
	await tween.finished

	animation_player.play("doors_open")
	await animation_player.animation_finished

	# inside train to platform
	_boarded_player_l.visible = false
	if player_disembark_marker:
		player.global_position = player_disembark_marker.global_position
	player.visible = true
	animation_player.play("doors_close")
	await animation_player.animation_finished
	player.set_physics_process(true)

## Play arrival animation without moving player
func play_simple_arrival_animation() -> void:
	var stop_position: Vector2 = original_position
	position = stop_position + arrival_offset
		
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", stop_position, arrival_duration)
	await tween.finished
	
#---------------------------------------------------------
# Helper functions
#---------------------------------------------------------
func _set_player_active(active: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.visible = active
	player.set_physics_process(active)


func _matches_ticket(ticket: TicketData) -> bool:
	return train_interactable_l.id == ticket.id or train_interactable_r.id == ticket.id


## Sets the interactables to enabled or disabled
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


func _run_boarding_and_departure() -> void:
	_set_player_active(false)
	await _open_doors()
	if _l_or_r == "l":
		_boarded_player_l.visible = true
	else:
		_boarded_player_r.visible = true
	await _close_doors()
	await _train_depart()
