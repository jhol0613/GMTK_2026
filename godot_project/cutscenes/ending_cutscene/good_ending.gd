extends Node2D

signal scene_complete

@onready var _intro_audio: AudioStreamPlayer = $IntroAudio
@onready var _body_audio: AudioStreamPlayer = $BodyAudio

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.stop_music()

	if _body_audio.stream is AudioStreamMP3:
		(_body_audio.stream as AudioStreamMP3).loop = true

	if _intro_audio.stream != null:
		_intro_audio.finished.connect(_play_body)
		_intro_audio.play()
	else:
		_play_body()

	#$AnimationPlayer.animation_finished.connect(queue_free)
	#var rec_tween = create_tween()
	#rec_tween.tween_property($CanvasLayer/ColorRect, "self_modulate:a", 1.0, 2.0)
	#await rec_tween.finished
	$GoodEndingPlayer.play("play_scene")
	#await $AnimationPlayer.animation_finished
	#var tween = create_tween()
	#tween.tween_property($CanvasLayer/ColorRect, "modulate:a", 0.0, 2.0)
	#await tween.finished
	
	#GameManager.load_scene(Enums.Scenes.TITLE)


func _play_body() -> void:
	if _body_audio.stream != null:
		_body_audio.play()
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		GameManager.load_scene(Enums.Scenes.TITLE)
