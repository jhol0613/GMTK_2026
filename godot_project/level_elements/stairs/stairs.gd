extends StaticBody2D

@export var climb_right : bool = true
@export var size : int = 1
@export var height : int = 1

@export var upper_collider : CollisionShape2D
@export var lower_collider : CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if climb_right:
		upper_collider.apply_scale( Vector2(size,size) )
		lower_collider.apply_scale( Vector2(size,size) )
	else:
		upper_collider.apply_scale( -1 * Vector2(size,size) )
		lower_collider.apply_scale( -1 * Vector2(size,size) )
	upper_collider.position.y = height * -16


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
