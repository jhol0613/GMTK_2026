extends Control

signal scene_complete

@onready var _intro_audio: AudioStreamPlayer = $IntroAudio
@onready var _body_audio: AudioStreamPlayer = $BodyAudio

@export var _credits: VBoxContainer
@export var _thanks: ResshanLabel

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
		GameManager.load_scene(Enums.Scenes.TITLE, Enums.TransitionStyle.FADE_WHITE)


func _on_button_pressed() -> void:
	if SaveManager.get_run_history().size() <= 1:
	#if GameManager.should_show_new_game_plus_message:
		GameManager.load_scene(Enums.Scenes.NEW_GAME_PLUS_EXPLANATION)
	else:
		GameManager.load_scene(Enums.Scenes.TITLE, Enums.TransitionStyle.FADE_WHITE)

func scroll_credits() -> void:
	var end_posit = _credits.position.y - get_viewport().size.y - _credits.size.y - 48
	var credit_tween := create_tween()
	credit_tween.tween_property(_credits,"position",Vector2(_credits.position.x, end_posit),12)


func scroll_thanks() -> void:
	var end_posit = _thanks.position.y - (get_viewport().size.y + _thanks.size.y) / 2
	var thanks_tween := create_tween()
	thanks_tween.tween_property(_thanks,"position",Vector2(_thanks.position.x, end_posit),4)
