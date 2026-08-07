extends Node2D

class_name LevelTemplate

@export var correct_line: StringName = &"red_east"
@export var wrong_train_line: DialogueLine
@export var missed_train_line: DialogueLine
@export var dialogue_panel_scene: PackedScene

@export_category("Level Music")

@export_enum("Level 0", "Level 1")
var level_music_track: int = AudioManager.MusicTrack.LEVEL_0

@export var play_train_intro_before_music: bool = false
@export var music_fade_in_duration: float = 2.0

var _dialogue_playing: bool = false


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

	SignalBus.missed_train.connect(_on_missed_train)

	if TimeManager.consume_wrong_train_dialogue():
		call_deferred("_play_wrong_train_dialogue")


func _on_missed_train() -> void:
	_play_character_dialogue(missed_train_line)


func _play_wrong_train_dialogue() -> void:
	await get_tree().create_timer(1.5).timeout
	await _play_character_dialogue(wrong_train_line)


func _play_character_dialogue(line: DialogueLine) -> void:
	if line == null or dialogue_panel_scene == null or _dialogue_playing:
		return
	_dialogue_playing = true
	var panel := dialogue_panel_scene.instantiate() as DialoguePanel
	add_child(panel)
	await get_tree().process_frame
	if not is_instance_valid(panel):
		_dialogue_playing = false
		return
	var lines: Array[DialogueLine] = [line]
	var choices: Array[DialogueChoice] = []
	panel.show_dialogue("You", lines, choices, 0)
	await panel.dialogue_complete
	if is_instance_valid(panel):
		panel.queue_free()
	_dialogue_playing = false
