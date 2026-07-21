extends Node
class_name MusicManager


enum State { CALM, TENSION, COMBAT }

@export_group("Streams")
@export var calm_stream: AudioStream
@export var tension_stream: AudioStream
@export var combat_stream: AudioStream

@export_group("Mix")
@export var fade_time: float = 1.5           ## Crossfade length in seconds.
@export var full_volume_db: float = 0.0      ## Volume of the active track.
@export var silent_volume_db: float = -60.0  ## Volume of inactive tracks.
@export var bus_name: StringName = &"Master" ## Audio bus for all tracks.

var _players: Dictionary = {}   # State -> AudioStreamPlayer
var _tweens: Dictionary = {}    # State -> Tween
var _current_state: State = State.CALM

func _ready() -> void:
	_create_player(State.CALM, calm_stream)
	_create_player(State.TENSION, tension_stream)
	_create_player(State.COMBAT, combat_stream)
	# Everything starts muted and in sync; bring up the starting state instantly.
	_apply_volume(_current_state, full_volume_db, 0.0)

func _create_player(state: State, stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.name = "Track_" + State.keys()[state]
	player.bus = bus_name
	player.volume_db = silent_volume_db
	player.stream = stream
	add_child(player)
	_players[state] = player
	if stream != null:
		player.play()
	else:
		push_warning("MusicManager: no stream assigned for state %s." % State.keys()[state])

## Switch to a new music state. Safe to call repeatedly; no-op calls are ignored.
func set_state(new_state: State) -> void:
	if new_state == _current_state:
		return
	var previous := _current_state
	_current_state = new_state
	_apply_volume(previous, silent_volume_db, fade_time)
	_apply_volume(new_state, full_volume_db, fade_time)

func get_state() -> State:
	return _current_state

func _apply_volume(state: State, target_db: float, time: float) -> void:
	var player: AudioStreamPlayer = _players.get(state)
	if player == null:
		return
	var existing: Tween = _tweens.get(state)
	if existing != null and existing.is_valid():
		existing.kill()
	if time <= 0.0:
		player.volume_db = target_db
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, time)
	_tweens[state] = tween
