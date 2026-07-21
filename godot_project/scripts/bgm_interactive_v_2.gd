class_name Looper
extends Node

signal point_reached

@export var audio_node: AudioStreamPlayer
@export var looping_points: Array[float] = []

## Track will loop from this point to the next one
var active_point: int = 0 :
	set(value):
		if value + 1 >= looping_points.size():
			return
		active_point = value

func _process(delta: float) -> void:
	if not audio_node and audio_node.playing:
		return
	var pos: = audio_node.get_playback_position() + AudioServer.get_time_since_last_mix()
	
	# It is assumed that active point will never be the same as the size
	if pos >= looping_points[active_point + 1]:
		audio_node.seek(looping_points[active_point])
		point_reached.emit()

func switch_point(point:int) -> void:
	active_point = point

func play() -> void:
	audio_node.play(looping_points[active_point])
