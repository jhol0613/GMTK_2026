extends Control

## Placeholder readout for the "time is running slow" coffee buff. Swap the
## ColorRect for real art once it exists.

@onready var _label: Label = $Label


func _ready() -> void:
	TimeManager.time_scale_changed.connect(_on_time_scale_changed)
	_on_time_scale_changed(TimeManager.time_scale)


func _on_time_scale_changed(scale: float) -> void:
	visible = not is_equal_approx(scale, 1.0)
	if visible:
		_label.text = "COFFEE x%.1f" % scale
