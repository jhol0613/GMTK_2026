extends Node2D


#@export var time_to_complete: float = 8
#@export var resshan_transit_time: float = 5
#@export var color: Enums.TrainColor = Enums.TrainColor.RED
#@export var start: String = "<<station.0>>"
#@export var end: String = "<<station.1>>"

var stash_data: TransitionStash

@export var _start_label: ResshanLabel
@export var _end_label: ResshanLabel
@export var _line: ColorRect
@export var _train: AnimatedSprite2D
@export var _timer: Countdown


@onready var _anim_player : AnimationPlayer = $AnimationPlayer
const _colors: Array[Color] = [	Color(0,0,1,1),
								Color(0.45,0.35,0.1,1),
								Color(0.5,0.5,0.5,1),
								Color(0,1,0,1),
								Color(0.35,0.0,0.0,1),
								Color(1,0,1,1),
								Color(0.6,0,1,1),
								Color(1,0,0,1),
								Color(0,1,1,1),
								Color(1,1,0,1) ]
var _seconds: int
var _interval: float
var _time_up: bool = false

func _ready() -> void:
	stash_data = GameManager.level_transition_stash_data
	
	_seconds = stash_data.resshan_transit_time * 8.0
	_train.play(Enums.TrainColor.find_key(stash_data.color))
	_line.modulate = _colors[stash_data.color]
	_start_label.text = stash_data.start
	_end_label.text = stash_data.end
	
	_anim_player.play(&"move_train", 1, 1/stash_data.time_to_complete)
	
	_interval = stash_data.time_to_complete / _seconds
	_tick()
	

func _tick():
	if _seconds > 0 and TimeManager.total_seconds() > 0:
		TimeManager.advance()
		await get_tree().create_timer(_interval).timeout
		_seconds -= 1
		_tick()
	elif TimeManager.total_seconds() == 0:
		_anim_player.stop(true)
		_anim_player.play(&"time_up")
		_timer._play_sound = true
		_timer.tick_second()
		await _anim_player.animation_finished
		GameManager.load_scene(Enums.Scenes.BAD_ENDING)
	elif _seconds <= 0:
		GameManager.load_scene(stash_data.next_scene)
	
