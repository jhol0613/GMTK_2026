extends Node2D

@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 1.0, 0.01) var max_alpha := 0.525

var overlay: CanvasItem

var _tween: Tween


func _ready() -> void:
	if not _ensure_overlay():
		return
	_sync_source()
	var source := get_parent()
	if source is AnimatedSprite2D and overlay is AnimatedSprite2D:
		source.animation_changed.connect(_sync_animation)
		_sync_animation()
	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	var progress := 1.0 - float(TimeManager.total_seconds()) / float(total)
	set_day_progress(progress, 0.0)


func _sync_source() -> void:
	var source := get_parent()
	if source is Sprite2D and overlay is Sprite2D:
		_copy_sprite_state(source, overlay)
	elif source is AnimatedSprite2D and overlay is AnimatedSprite2D:
		_copy_animated_sprite_state(source, overlay)
	elif source is AnimatedSprite2D and overlay is Sprite2D:
		var source_sprite := source as AnimatedSprite2D
		var overlay_sprite := overlay as Sprite2D
		overlay_sprite.centered = source_sprite.centered
		overlay_sprite.offset = source_sprite.offset
		overlay_sprite.flip_h = source_sprite.flip_h
		overlay_sprite.flip_v = source_sprite.flip_v


func _copy_sprite_state(source: Sprite2D, target: Sprite2D) -> void:
	target.centered = source.centered
	target.offset = source.offset
	target.flip_h = source.flip_h
	target.flip_v = source.flip_v


func _copy_animated_sprite_state(
	source: AnimatedSprite2D,
	target: AnimatedSprite2D,
) -> void:
	target.centered = source.centered
	target.offset = source.offset
	target.flip_h = source.flip_h
	target.flip_v = source.flip_v


func _sync_animation() -> void:
	var source := get_parent() as AnimatedSprite2D
	var animated_overlay := overlay as AnimatedSprite2D
	if source == null or animated_overlay == null:
		return
	animated_overlay.play(
		&"VERTICAL"
		if String(source.animation).begins_with("VERTICAL_")
		else &"HORIZONTAL"
	)


func set_day_progress(progress: float, duration: float) -> void:
	if not _ensure_overlay():
		return
	var strength := clampf(
		inverse_lerp(start_progress, full_strength_progress, progress),
		0.0,
		1.0
	)
	var alpha := strength * max_alpha
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		overlay.modulate.a = alpha
		return
	_tween = create_tween()
	_tween.tween_property(overlay, "modulate:a", alpha, duration)


func _ensure_overlay() -> bool:
	if overlay == null:
		overlay = get_node_or_null("Overlay") as CanvasItem
	return overlay != null
