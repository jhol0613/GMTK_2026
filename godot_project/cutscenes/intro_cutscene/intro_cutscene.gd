extends Node2D

signal scene_complete

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		player.movement_disabled = true
		
	$AnimationPlayer.animation_finished.connect(queue_free)
	var rec_tween = create_tween()
	rec_tween.tween_property($CanvasLayer/ColorRect, "self_modulate:a", 1.0, 2.0)
	await rec_tween.finished
	$AnimationPlayer.play("cutscene_sequence")
	await $AnimationPlayer.animation_finished
	var tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, "modulate:a", 0.0, 2.0)
	await tween.finished
	_end_intro()


func _input(event):
	if event.is_action_pressed("skip"):
		_end_intro()

func _end_intro():
	for player in get_tree().get_nodes_in_group("player"):
		player.movement_disabled = false
	scene_complete.emit()
	queue_free()
