extends Node

## Parametric signal-chain demo. A Low-Pass Filter is added to a music bus in
## code, and its cutoff frequency is swept by a parameter (here toggled with F).
## This is the pattern for any parameter-driven FX: grab the effect at runtime
## and change its properties.
##   F = toggle "muffle" (e.g. going underwater): cutoff sweeps open <-> muffled.

@export var music_stream: AudioStream
@export var sweep_time: float = 0.8
@export var open_hz: float = 20000.0
@export var muffled_hz: float = 500.0

var _lpf: AudioEffectLowPassFilter
var _player: AudioStreamPlayer
var _muffled: bool = false
@onready var _label: Label = $UI/Label

func _ready() -> void:
	var bus_idx := _ensure_bus(&"MusicFX")

	# Build the signal chain: add a low-pass filter to the bus.
	_lpf = AudioEffectLowPassFilter.new()
	_lpf.cutoff_hz = open_hz
	AudioServer.add_bus_effect(bus_idx, _lpf)

	_player = AudioStreamPlayer.new()
	_player.stream = music_stream
	_player.bus = &"MusicFX"
	add_child(_player)
	_player.finished.connect(_player.play)  # loop the music for the demo
	_player.play()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		_muffled = not _muffled
		var target := muffled_hz if _muffled else open_hz
		var tw := create_tween()
		tw.tween_method(_set_cutoff, _lpf.cutoff_hz, target, sweep_time)

func _set_cutoff(hz: float) -> void:
	_lpf.cutoff_hz = hz

func _process(_delta: float) -> void:
	_label.text = "F = toggle muffle (underwater)\nmuffled: %s    cutoff: %.0f Hz" % [_muffled, _lpf.cutoff_hz]

## Create a bus routed to Master if it does not exist yet; returns its index.
func _ensure_bus(bus_name: StringName, send_to: StringName = &"Master") -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, send_to)
	return idx
