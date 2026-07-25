@tool

extends Node2D

@export var upper_train: Train
@export var play_arrival_on_ready: bool = true
@export var lower_train: Train

@export var color: Enums.TrainColor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if Engine.is_editor_hint():
		return
	if upper_train and play_arrival_on_ready:
		upper_train.play_arrival_animation()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func depart_upper_train():
	upper_train._train_depart()

func arrive_upper_train():
	upper_train.play_simple_arrival_animation()

func depart_lower_train():
	lower_train._train_depart()

func arrive_lower_train():
	lower_train.play_simple_arrival_animation()
