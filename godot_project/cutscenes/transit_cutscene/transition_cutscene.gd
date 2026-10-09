extends Node2D


#@export var time_to_complete: float = 8
#@export var resshan_transit_time: float = 5
#@export var color: Enums.TrainColor = Enums.TrainColor.RED
#@export var start: String = "<<station.0>>"
#@export var end: String = "<<station.1>>"

var stash_data = TransitionStash.new()

@export var _start_label: ResshanLabel
@export var _end_label: ResshanLabel
@export var _line: ColorRect
@export var _train: AnimatedSprite2D

@onready var _anim_player : AnimationPlayer = $AnimationPlayer
var _colors: Array[Color] = [	Color(0,0,1,1),
								Color(0.45,0.35,0.1,1),
								Color(0.5,0.5,0.5,1),
								Color(0,1,0,1),
								Color(0.35,0.0,0.0,1),
								Color(1,0,1,1),
								Color(0.6,0,1,1),
								Color(1,0,0,1),
								Color(0,1,1,1) ]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stash_data = GameManager.level_transition_stash_data
	
	_train.play(Enums.TrainColor.find_key(stash_data.color))
	_line.modulate = _colors[stash_data.color]
	_start_label.text = stash_data.start
	_end_label.text = stash_data.end
	
	_anim_player.play(&"MoveTrain", 1, 1/stash_data.time_to_complete)
	await _anim_player.animation_finished
	
	GameManager.load_scene(stash_data.next_scene)
