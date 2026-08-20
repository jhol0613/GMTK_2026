class_name WrongTrainBoardedMessage
extends PanelContainer

@export var fade_time := 1.5
@export var life_time := 4.0

signal scene_complete

@onready var container := $CanvasLayer/PanelContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 1.0, fade_time)
	get_tree().create_timer(life_time).timeout.connect(_fade_out)

func _fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 0.0, fade_time)
	await tween.finished
	scene_complete.emit()
	queue_free()
