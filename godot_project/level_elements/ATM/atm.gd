extends Node2D

@export var broken : bool = false
@export var sprite : AnimatedSprite2D
@export var dialog_interactable : DialogueInteractable
@export var resshan_interactable : ResshanInteractable
@export var resshan_interactable2 : ResshanInteractable

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


func _on_interacted() -> void:
	if broken:
		return
	Wallet.refill()
