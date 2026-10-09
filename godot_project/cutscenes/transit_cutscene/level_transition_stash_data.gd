class_name TransitionStash
extends Resource

@export var time_to_complete: float = 8
@export var resshan_transit_time: float = 5
@export var color: Enums.TrainColor = Enums.TrainColor.RED
@export var start: String = "<<station.0>>"
@export var end: String = "<<station.1>>"
@export var next_scene: Enums.Scenes = Enums.Scenes.LEVEL_1

func _init( _ttc := 8.0, _rtt := 5.0, _clr := Enums.TrainColor.RED, _st := "<<station.0>>", _en := "<<station.1>>", _ns := Enums.Scenes.LEVEL_1 ) -> void:
	time_to_complete = _ttc
	resshan_transit_time = _rtt
	color = _clr
	start = _st
	end = _en
	next_scene = _ns
