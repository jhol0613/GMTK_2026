@tool
class_name TrainPlatform
extends Node2D

@export var upper_train: Train
#@export var play_arrival_on_ready: bool = true
@export var lower_train: Train
@export var station_number: int = 0:
	set(value):
		station_number = value
		if is_inside_tree():
			_apply_station_number_to_signs()
@export var platform_number: int = 0

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	_apply_station_number_to_signs()

func _ready() -> void:
	if upper_train:
		upper_train.platform_number = platform_number
	if lower_train:
		lower_train.platform_number = platform_number
	#if Engine.is_editor_hint():
		#return
	#if upper_train and play_arrival_on_ready:
		#upper_train.play_arrival_animation()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _apply_station_number_to_signs() -> void:
	for child in get_children():
		if "station_number" in child:
			child.station_number = station_number
