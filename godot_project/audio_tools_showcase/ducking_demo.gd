extends Node

## Side-chain ducking demo. An AudioEffectCompressor is placed on the Music bus
## with its Sidechain set to the SFX bus. When a sound plays on the SFX bus, the
## compressor lowers the Music bus volume, then it recovers.
##   SPACE = play the SFX (music should duck, then come back)
##
## Buses and effect are created in code so this scene is self-contained.

@export var music_stream: AudioStream
@export var sfx_stream: AudioStream
@export var threshold_db: float = -25.0
@export var ratio: float = 8.0

var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _music_idx: int
@onready var _label: Label = $UI/Label

func _ready() -> void:
	_music_idx = _ensure_bus(&"Music")
	_ensure_bus(&"SFX")

	# Compressor on the ducked bus (Music), listening to the trigger bus (SFX).
	var comp := AudioEffectCompressor.new()
	comp.sidechain = &"SFX"
	comp.threshold = threshold_db
	comp.ratio = ratio
	AudioServer.add_bus_effect(_music_idx, comp)

	_music = AudioStreamPlayer.new()
	_music.stream = music_stream
	_music.bus = &"Music"
	add_child(_music)
	_music.finished.connect(_music.play)  # loop the music for the demo
	_music.play()

	_sfx = AudioStreamPlayer.new()
	_sfx.stream = sfx_stream
	_sfx.bus = &"SFX"
	add_child(_sfx)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_sfx.play()

func _process(_delta: float) -> void:
	# Post-compression peak of the music bus: watch it dip when the SFX plays.
	var music_peak := AudioServer.get_bus_peak_volume_left_db(_music_idx, 0)
	_label.text = "SPACE = play SFX (music ducks)\nSFX playing: %s\nmusic bus peak: %.1f dB" % [_sfx.playing, music_peak]

func _ensure_bus(bus_name: StringName, send_to: StringName = &"Master") -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, send_to)
	return idx
