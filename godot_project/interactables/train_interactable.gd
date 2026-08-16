class_name TrainInteractable
extends Interactable

@export var l_or_r: String

@onready var train: Train = get_parent() as Train


func interact() -> void:
	if train == null:
		return
	train.try_board(self, l_or_r)
