extends AudioZone
class_name TransientZone

## One-shot zone. Plays a positional sound ONCE each time the listener enters,
## with a cooldown so quickly re-entering does not spam the sound. Use for
## stingers, trap triggers, threshold "whooshes". The stream should NOT loop.

@export var stream: AudioStream
@export var cooldown: float = 0.5   ## Minimum seconds between triggers.
@export var bus_name: StringName = &"Master"

var _player: AudioStreamPlayer3D
var _last_trigger_time: float = -1000.0

func _ready() -> void:
	super._ready()
	_player = AudioStreamPlayer3D.new()
	_player.stream = stream
	_player.bus = bus_name
	add_child(_player)
	if stream == null:
		push_warning("TransientZone '%s': no stream assigned." % name)

func _on_listener_entered(_body: Node3D) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_trigger_time < cooldown:
		return
	_last_trigger_time = now
	if _player.stream != null:
		_player.play()
