extends Node2D

@export var broken : bool = false
@export var sprite : AnimatedSprite2D
@export var dialog_interactable : DialogueInteractable
@export var resshan_interactable : ResshanInteractable
@export var resshan_interactable2 : ResshanInteractable

func _ready() -> void:
	if broken:
		sprite.play( "broken" )
		dialog_interactable.queue_free()
		resshan_interactable.queue_free()
		resshan_interactable2.queue_free()
	else:
		sprite.play( "default" )
