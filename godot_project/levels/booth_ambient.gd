extends Node2D

@export var pause_between_loops: float = 2.4

@export var resume_delay: float = 3.0

@onready var _ambient: AudioStreamPlayer2D = $BoothAmbient
@onready var _loop_pause_timer: Timer = $LoopPauseTimer
@onready var _resume_timer: Timer = $ResumeTimer
@onready var _dialogue_panel: InteractionPanelBase = $DialoguePanel

var _interaction_active: bool = false


func _ready() -> void:
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


func _on_dialogue_closed() -> void:
	_interaction_active = false

	_loop_pause_timer.stop()
	_resume_timer.start(resume_delay)


func _on_resume_timer_finished() -> void:
	_play_ambient()
