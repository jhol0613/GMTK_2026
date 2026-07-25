extends Node2D

class_name LevelTemplate

## The only destination that lets the player leave this level.
@export var correct_destination: String = ""

func _ready() -> void:
	# sync the camera to the player
	var player: CharacterBody2D = $Player
	var camera: Camera2D = $Camera2D
	var remote_transform: RemoteTransform2D = player.get_node("RemoteTransform2D")
	remote_transform.remote_path = remote_transform.get_path_to(camera)
