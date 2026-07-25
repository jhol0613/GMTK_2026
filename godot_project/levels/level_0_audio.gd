extends Node


@export var train_start_delay: float = 0.0

@export var bgm_start_delay: float = 0.0

@export var bgm_play_duration: float = -1.0

@export var bgm_fade_in_duration: float = 1.0
@export var bgm_target_volume_db: float = -4.0

@onready var _train_intro: AudioStreamPlayer = $TrainIntro
@onready var _bgm: AudioStreamPlayer = $BGM
@onready var _tripped: AudioStreamPlayer = $Tripped

@export_category("Notebook Music")
@export var notebook_bgm_target_db: float = -4.0
@export var notebook_crossfade_duration: float = 2.0

@onready var _notebook_bgm: AudioStreamPlayer = $NotebookBGM

var _notebook_is_open: bool = false
var _crossfade_tween: Tween

const SILENT_DB: float = -40.0



func _ready() -> void:
	_notebook_bgm.volume_db = SILENT_DB

	SignalBus.notebook_opened.connect(
		_on_notebook_opened
	)
	SignalBus.notebook_closed.connect(
		_on_notebook_closed
	)

	_play_level_timeline()


func _play_level_timeline() -> void:
	play_bgm()

	if bgm_play_duration > 0.0:
		await get_tree().create_timer(bgm_play_duration).timeout
		await fade_out_bgm(2.0)

func play_tripped_music() -> void:
	_bgm.stop()
	_tripped.play()

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
	
func _crossfade_music(
	main_target_db: float,
	notebook_target_db: float
) -> void:
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.set_trans(Tween.TRANS_SINE)
	_crossfade_tween.set_ease(Tween.EASE_IN_OUT)

	_crossfade_tween.tween_property(
		_bgm,
		"volume_db",
		main_target_db,
		notebook_crossfade_duration
	)

	_crossfade_tween.tween_property(
		_notebook_bgm,
		"volume_db",
		notebook_target_db,
		notebook_crossfade_duration
	)
	
func _on_notebook_opened() -> void:
	if _notebook_is_open:
		return

	_notebook_is_open = true

	if not _notebook_bgm.playing:
		_notebook_bgm.volume_db = SILENT_DB
		_notebook_bgm.play()

	_crossfade_music(
		SILENT_DB,
		notebook_bgm_target_db
	)
	
func _on_notebook_closed() -> void:
	if not _notebook_is_open:
		return

	_notebook_is_open = false

	_crossfade_music(
		bgm_target_volume_db,
		SILENT_DB
	)
func skip_intro_to_bgm() -> void:
	_tripped.stop()
	
	if _bgm.playing:
		_bgm.stop()
		
	play_bgm()
