@tool

extends Node2D

@export var arrival_train: Train
@export var play_arrival_on_ready: bool = true
@export var lower_train: Train


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if arrival_train and play_arrival_on_ready:
		arrival_train.play_arrival_animation()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
