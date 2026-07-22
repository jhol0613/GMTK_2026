extends CharacterBody2D

var direction: Vector2 = Vector2(1,1)
var speed: int = 100


func _physics_process(delta: float) -> void:
	direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	move_and_slide()


#if Input.pressed("up"):
#	velocity.x = Vector2(0, -1) * SPEED
#	
#	if direction:
#		velocity.x = direction * SPEED
#	else:
#		velocity.x = move_toward(velocity.x, 0, SPEED)
#
#	move_and_slide()
