extends Node2D

signal scene_complete

@onready var _ending_audio: AudioStreamPlayer = $EndingAudio

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.stop_music()
	if _ending_audio.stream != null:
		_ending_audio.play()

	#$AnimationPlayer.animation_finished.connect(queue_free)
	#var rec_tween = create_tween()
	#rec_tween.tween_property($CanvasLayer/ColorRect, "self_modulate:a", 1.0, 2.0)
	#await rec_tween.finished
	$BadEndingPlayer.play("play_scene")
	#await $AnimationPlayer.animation_finished
	#var tween = create_tween()
	#tween.tween_property($CanvasLayer/ColorRect, "modulate:a", 0.0, 2.0)
	#await tween.finished
	
	#GameManager.load_scene(Enums.Scenes.TITLE)
