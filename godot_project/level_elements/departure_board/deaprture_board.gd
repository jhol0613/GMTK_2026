extends Node2D


@onready var _destination_label := $Time4

@onready var _update_sound: AudioStreamPlayer2D = $UpdateSound

@export var _all_labels: Array[ResshanLabel] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.ticket_purchased.connect(_on_ticket_purchased)

	_update_labels(TimeManager.hour, TimeManager.minute)

func _on_ticket_purchased(
	hour: int,
	minute: int
) -> void:
	_update_labels(hour, minute)

	if _update_sound.stream != null:
		_update_sound.play()

func _update_labels(hour: int, minute: int) -> void:
	var offset = int(randf() * 3.0 + 1.0)
	for label in _all_labels:
		if randf() > 0.5:
			label.text = "<<%s>> : <<%s>>" % [hour, minute]
		else:
			label.text = "<<%s>> : <<%s>>" % [hour, posmod(minute + offset, 8)]
	_destination_label.text = "<<%s>> : <<%s>>" % [hour, minute]
