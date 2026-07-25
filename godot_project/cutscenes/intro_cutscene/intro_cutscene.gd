extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(queue_free)
	var rec_tween = create_tween()
	rec_tween.tween_property($CanvasLayer/ColorRect, "self_modulate:a", 1.0, 1.0)
	await rec_tween.finished
	$AnimationPlayer.play("cutscene_sequence")
	await $AnimationPlayer.animation_finished
	var tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, "modulate:a", 0.0, 2.0)
	await tween.finished
	queue_free()

func _input(event):
	if event.is_action_pressed("skip"):
		queue_free()
