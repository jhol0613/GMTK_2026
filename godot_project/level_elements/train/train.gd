@tool

extends Node2D

class_name Train

@export var next_scene: Enums.Scenes = Enums.Scenes.LEVEL_1
@export var depart_offset: Vector2 = Vector2(800, 0)
@export var depart_duration: float = 1.5
@export var sprite : AnimatedSprite2D
@export var color := Enums.TrainColor.BROWN :
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
	if ticket == null or not interactable.can_board(ticket):
		await _flash_reject(_no_ticket_light)
		return
	
	await _boarding_sequence()

func _boarding_sequence() -> void:
	_boarding = true

	# Disable player input
	var player:= get_tree().get_first_node_in_group("player")
	player.visible = false
	player.set_physics_process(false)

	animation_player.play("doors_open")
	await animation_player.animation_finished
	
	_boarded_player.visible = true

	animation_player.play("doors_close")
	await animation_player.animation_finished
	
	await _train_depart()
	GameManager.load_scene(next_scene)
	_boarding = false

# Flashes a light on and off for a given number of times
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
