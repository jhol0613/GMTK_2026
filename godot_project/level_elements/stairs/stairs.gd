extends Area2D

class_name Stairs

# If true, going right on the stairs moves the character up, and going left moves down
@export var climb_right : bool = true

var overlaps : Array[CharacterBody2D]


func _physics_process(delta: float) -> void:
		for body in overlaps:
			body.velocity.y += body.velocity.x


func _on_body_entered(body: Node2D) -> void:
	if body is not CharacterBody2D:
		return
	overlaps.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body not in overlaps:
		return
	overlaps.remove_at( overlaps.rfind( body ) )
