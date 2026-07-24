extends Node2D

@export var pause_between_loops: float = 2.0

@export var resume_delay: float = 3.0

@onready var _ambient: AudioStreamPlayer2D = $BoothAmbient
@onready var _loop_pause_timer: Timer = $LoopPauseTimer
@onready var _resume_timer: Timer = $ResumeTimer
@onready var _dialogue_panel: InteractionPanelBase = $DialoguePanel

@export_category("BGM Ducking")
@export var bgm_duck_amount_db: float = -6.0
@export var bgm_duck_fade_time: float = 0.25
@export var bgm_release_fade_time: float = 0.8

var _interaction_active: bool = false

var _music_bus_index: int = -1
var _music_normal_db: float = 0.0
var _music_tween: Tween


func _ready() -> void:
	_music_bus_index = AudioServer.get_bus_index(&"Music")

	if _music_bus_index >= 0:
		_music_normal_db = AudioServer.get_bus_volume_db(
			_music_bus_index
		)
	else:
		push_warning("Music audio bus was not found.")

	_ambient.finished.connect(_on_ambient_finished)
	_loop_pause_timer.timeout.connect(_on_loop_pause_finished)
	_resume_timer.timeout.connect(_on_resume_timer_finished)

	_dialogue_panel.opened.connect(_on_dialogue_opened)
	_dialogue_panel.closed.connect(_on_dialogue_closed)

	_play_ambient()


func _play_ambient() -> void:
	if _interaction_active:
		return

	if not _ambient.playing:
		_ambient.play()


func _on_ambient_finished() -> void:
	if _interaction_active:
		return

	_loop_pause_timer.start(pause_between_loops)


func _on_loop_pause_finished() -> void:
	_play_ambient()


func _on_dialogue_opened() -> void:
	_interaction_active = true

	_loop_pause_timer.stop()
	_resume_timer.stop()
	_ambient.stop()

	_tween_music_bus(
		_music_normal_db + bgm_duck_amount_db,
		bgm_duck_fade_time
	)


func _on_dialogue_closed() -> void:
	_interaction_active = false

	_loop_pause_timer.stop()
	_resume_timer.start(resume_delay)

	_tween_music_bus(
		_music_normal_db,
		bgm_release_fade_time
	)


func _on_resume_timer_finished() -> void:
	_play_ambient()
	
func _set_music_bus_db(value: float) -> void:
	if _music_bus_index < 0:
		return

	AudioServer.set_bus_volume_db(
		_music_bus_index,
		value
	)


func _tween_music_bus(
	target_db: float,
	duration: float
) -> void:
	if _music_bus_index < 0:
		return

	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()

	var current_db := AudioServer.get_bus_volume_db(
		_music_bus_index
	)

	if duration <= 0.0:
		_set_music_bus_db(target_db)
		return

	_music_tween = create_tween()
	_music_tween.tween_method(
		_set_music_bus_db,
		current_db,
		target_db,
		duration
	)
