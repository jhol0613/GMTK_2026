extends Node2D
class_name ATM

@export var broken : bool = false
@export var sprite : AnimatedSprite2D
@export var dialog_interactable : DialogueInteractable
@export var resshan_interactable : ResshanInteractable
@export var resshan_interactable2 : ResshanInteractable

@onready var _lightning_origin : Marker2D = $RefillLightningOrigin

func _ready() -> void:
	if broken:
		sprite.play( "broken" )
		dialog_interactable.active = false
		resshan_interactable.queue_free()
		resshan_interactable2.queue_free()
		dialog_interactable.turn_on_sound = null
	else:
		sprite.play( "default" )
		if dialog_interactable != null:
			dialog_interactable.interacted.connect( _on_interacted )

func explode() -> void:
	sprite.play("explode")
	#numerator is desired frame number
	var time_until_shake = 4.0/sprite.sprite_frames.get_animation_speed("explode")
	await get_tree().create_timer(time_until_shake).timeout
	var camera = get_tree().get_first_node_in_group("cameras") as ShakeCamera
	if camera:
		camera.apply_shake()
	await sprite.animation_finished
	dialog_interactable.active = false

func _on_interacted() -> void:
	if broken:
		return
	Wallet.refill(_lightning_origin.global_position)
