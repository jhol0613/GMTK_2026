extends Control

const HOUR_PER_DAY: int = 8

@onready var label: ResshanLabel = $Label
@onready var highlight: Panel = $Highlight
@onready var timer: Timer = $Timer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

## Countdown starts here and ticks down towards 0:0
@export var start_hour: int = HOUR_PER_DAY
@export var start_minute: int = 0

var tween: Tween


func _ready() -> void:
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.sync_from_ui(start_hour, start_minute)
	_update_label(TimeManager.hour, TimeManager.minute)

	if TimeManager.consume_flash():
		_flash_timer()

	highlight.visible = false


func _on_time_changed(hour: int, minute: int) -> void:
	_update_label(hour, minute)
	sfx_player.play()

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(self, "scale:x", 1.2, 0.2)
	tween.parallel().tween_property(self, "scale:y", 1.2, 0.2)

	tween.tween_property(self, "scale:x", 1.0, 0.2)
	tween.parallel().tween_property(self, "scale:y", 1.0, 0.2)


func _update_label(hour: int, minute: int) -> void:
	label.text = "<<%s>> : <<%s>>" % [hour, minute]


func _flash_timer(flashes: int = 3, interval: float = 0.5) -> void:
	for i in flashes:
		label.modulate = Color.RED
		await get_tree().create_timer(interval).timeout
		label.modulate = Color.WHITE
		await get_tree().create_timer(interval).timeout
