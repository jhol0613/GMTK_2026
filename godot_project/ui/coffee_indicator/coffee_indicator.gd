extends Control

@onready var _bar: ProgressBar = $Bar


func _ready() -> void:
	TimeManager.time_scale_changed.connect(_on_time_scale_changed)
	_on_time_scale_changed(TimeManager.time_scale)


func _on_time_scale_changed(scale: float) -> void:
	visible = not is_equal_approx(scale, 1.0)
	set_process(visible)


func _process(_delta: float) -> void:
	_bar.value = TimeManager.time_scale_progress()
