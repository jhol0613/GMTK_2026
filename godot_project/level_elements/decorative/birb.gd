extends Node2D


@export var sprite : AnimatedSprite2D
@export var speed : float = 10
var _flying : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position += Vector2( 1,-1 ) * speed * delta
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	_flying = true
	sprite.play("fly")
