extends Node2D

@export_subgroup("Scenes")
@export var scene_dict: Dictionary[Enums.Scenes, PackedScene]
## Scenes must explicitly set pause enabled to true
@export var pause_enabled := false

@export_subgroup("Animation")
@export var default_fade_out_time := 1.0
@export var default_fade_in_time := 1.0

@onready var _transition_out_time = default_fade_out_time
@onready var _transition_in_time = default_fade_in_time

@onready var _pause_layer: CanvasLayer

var restore_time: bool = false
var restore_hour: int = 0
var restore_minute: int = 0
var flash_timer: bool = false


func load_scene(scene: Enums.Scenes, transition_style = Enums.TransitionStyle.FADEINOUT, transition_in_time = default_fade_in_time,
	transition_out_time = default_fade_out_time):

	_transition_out_time = transition_out_time
	_transition_in_time = transition_in_time

	pause_enabled = false

	match transition_style:
		Enums.TransitionStyle.FADEINOUT:
			_fadeout(scene)
		Enums.TransitionStyle.NONE:
			_load_scene(scene)

func pause_game():
	if pause_enabled:
		get_tree().paused = true
		_pause_layer = CanvasLayer.new()
		_pause_layer.layer = 10
		get_tree().current_scene.add_child(_pause_layer)
		_pause_layer.add_child(scene_dict.get(Enums.Scenes.PAUSE).instantiate())

func unpause_game():
	get_tree().paused = false
	_pause_layer.queue_free()

func _load_scene(scene_to_load: Enums.Scenes):
	get_tree().call_deferred("change_scene_to_packed", scene_dict.get(scene_to_load))

func _fadeout(next_scene: Enums.Scenes):
	var fadeout_rect = _build_fadeout_rect(0)
	get_tree().current_scene.add_child(fadeout_rect)
	var tween = create_tween()
	tween.tween_property(fadeout_rect, "modulate:a", 1.0, _transition_out_time)
	tween.tween_callback(_load_scene_fadein.bind(next_scene))

func _fadein():
	get_tree().disconnect("tree_changed", _fadein)
	var fadeout_rect = _build_fadeout_rect(1)
	get_tree().current_scene.add_child(fadeout_rect)
	var tween = create_tween()
	tween.tween_property(fadeout_rect, "modulate:a", 0.0, _transition_in_time)
	tween.tween_callback(_remove_fadeout_rect.bind(fadeout_rect))

func _load_scene_fadein(scene_to_load: Enums.Scenes):
	get_tree().change_scene_to_packed(scene_dict.get(scene_to_load))
	get_tree().connect("tree_changed", _fadein)

func _remove_fadeout_rect(rect: ColorRect):
	get_tree().current_scene.remove_child(rect)

func _build_fadeout_rect(alpha: float) -> ColorRect:
	var fadeout_rect = ColorRect.new()
	fadeout_rect.size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	fadeout_rect.color = Color(0, 0, 0, 1)
	fadeout_rect.modulate.a = alpha
	fadeout_rect.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	fadeout_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return fadeout_rect

func stash_time_before_reload(hour: int, minute: int, penalty_minutes: int) -> void:
	restore_hour = hour
	restore_minute = minute + penalty_minutes

	while restore_minute >= 8:
		restore_hour += 1
		restore_minute -= 8

	restore_time = true
	flash_timer = true