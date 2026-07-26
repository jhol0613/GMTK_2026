extends Node2D


@onready var _time_label_container := $HBoxContainer/VBoxContainer
@onready var _destination_label := $HBoxContainer/VBoxContainer/DestinationLabel

var _all_labels

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_all_labels = _time_label_container.get_children()
	SignalBus.ticket_purchased.connect(_update_labels)

	_update_labels(TimeManager.hour, TimeManager.minute)

func _update_labels(hour: int, minute: int) -> void:
	var offset = int(randf() * 3.0 + 1.0)
	for label in _all_labels:
		if randf() > 0.5:
			label.text = "<<%s>> : <<%s>>" % [hour, minute]
		else:
			label.text = "<<%s>> : <<%s>>" % [hour, posmod(minute + offset, 8)]
	_destination_label.text = "<<%s>> : <<%s>>" % [hour, minute]
