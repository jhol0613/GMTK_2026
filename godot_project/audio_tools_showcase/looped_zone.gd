extends AudioZone
class_name LoopedZone

## Ambient loop zone. A positional, continuously looping sound fades IN when the
## listener enters and fades OUT when they leave. Use for beds like rain, a
## forest, machine hum. Assign a LOOPING stream (enable "Loop" in the Import tab).

@export var stream: AudioStream
@export var fade_time: float = 1.0
@export var full_volume_db: float = 0.0
@export var silent_volume_db: float = -60.0
@export var bus_name: StringName = &"Master"

var _player: AudioStreamPlayer3D
var _tween: Tween

func _ready() -> void:
	super._ready()
	_player = AudioStreamPlayer3D.new()
	_player.stream = stream
	_player.bus = bus_name
	_player.volume_db = silent_volume_db  # Loops silently until the listener arrives.
	add_child(_player)
	if stream != null:
		_player.play()
	else:
		push_warning("LoopedZone '%s': no stream assigned." % name)

func _on_listener_entered(_body: Node3D) -> void:
	_fade_to(full_volume_db)

func _on_listener_exited(_body: Node3D) -> void:
	_fade_to(silent_volume_db)

func _fade_to(target_db: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", target_db, fade_time)
