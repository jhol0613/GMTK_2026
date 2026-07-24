extends Node

@export var train_start_delay: float = 0.0

@export var bgm_start_delay: float = 3.0

@export var bgm_play_duration: float = -1.0

@onready var _train_intro: AudioStreamPlayer =  $TrainInto
@onready var _bgm: AudioStreamPlayer = $BGM

@export var bgm_fade_in_duration: float = 4.0
@export var bgm_target_volume_db: float = -4.0


func _ready() -> void:
	_play_level_timeline()


func _play_level_timeline() -> void:
	if train_start_delay > 0.0:
		await get_tree().create_timer(train_start_delay).timeout

	play_train_intro()

	await _train_intro.finished
	play_bgm()

	if bgm_play_duration > 0.0:
		await get_tree().create_timer(bgm_play_duration).timeout
		await fade_out_bgm(2.0)


func play_train_intro() -> void:
	_train_intro.play()


func stop_train_intro() -> void:
	_train_intro.stop()


func play_bgm() -> void:
	if _bgm.playing:
		return

	_bgm.volume_db = -40.0
	_bgm.play()

	var tween := create_tween()
	tween.tween_property(
		_bgm,
		"volume_db",
		bgm_target_volume_db,
		bgm_fade_in_duration
	)


func pause_bgm() -> void:
	_bgm.stream_paused = true


func resume_bgm() -> void:
	_bgm.stream_paused = false


func stop_bgm() -> void:
	_bgm.stop()


func fade_out_bgm(duration: float = 2.0) -> void:
	if not _bgm.playing:
		return

	var original_volume := _bgm.volume_db
	var tween := create_tween()

	tween.tween_property(
		_bgm,
		"volume_db",
		-40.0,
		duration
	)

	await tween.finished

	_bgm.stop()
	_bgm.volume_db = original_volume
