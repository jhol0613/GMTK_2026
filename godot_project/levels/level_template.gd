extends Node2D

class_name LevelTemplate

@export var correct_line: StringName = &"red_east"

@export_category("Level Music")

@export_enum("Level 0", "Level 1")
var level_music_track: int = AudioManager.MusicTrack.LEVEL_0

@export var play_train_intro_before_music: bool = false
@export var music_fade_in_duration: float = 2.0

func _ready() -> void:
	# sync the camera to the player
	var player: CharacterBody2D = $Player
	var camera: Camera2D = $Camera2D
	var remote_transform: RemoteTransform2D = player.get_node("RemoteTransform2D")
	remote_transform.remote_path = remote_transform.get_path_to(camera)
	
	AudioManager.start_level_music(
		level_music_track,
		play_train_intro_before_music,
		music_fade_in_duration
	)
