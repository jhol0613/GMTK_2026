extends Node
class_name BGMInteractive

## Wrapper around Godot's native AudioStreamInteractive for an
## intro -> body(loop) -> outro BGM. Built in code from four clips so all
## transitions are sample-accurate (handled by the engine).
##
##   set_parameter(INGAME)   : the body keeps looping (default).
##   set_parameter(GAMEENDS) : switch to the outro. The engine waits until the
##                             current body segment ENDS, then transitions, so
##                             the switch lands on a musical boundary.
##
## The body loops as TWO segments that auto-advance into each other
## (BodyA -> BodyB -> BodyA ...). We do NOT loop a single clip into itself:
## that path is buggy in current Godot, and a self-looping clip never reaches
## its END, which would block the "transition out on END" behaviour. Ping-pong
## between two clips avoids both problems and gives a finer transition boundary.
##
## Transitions use TransitionFromTime = END, which needs no BPM metadata, so
## plain WAV clips work. Keep the clips' Import Loop Mode = Disabled.

enum Parameter { INGAME, GAMEENDS }

@export var intro_stream: AudioStream
@export var body_a_stream: AudioStream
@export var body_b_stream: AudioStream
@export var outro_stream: AudioStream
@export var bus_name: StringName = &"Master"

const INTRO := 0
const BODY_A := 1
const BODY_B := 2
const OUTRO := 3

var _player: AudioStreamPlayer
var _interactive: AudioStreamInteractive
var _param: Parameter = Parameter.INGAME

func _ready() -> void:
	_interactive = AudioStreamInteractive.new()
	_interactive.clip_count = 4

	_setup_clip(INTRO, &"Intro", intro_stream, BODY_A)
	_setup_clip(BODY_A, &"BodyA", body_a_stream, BODY_B)
	_setup_clip(BODY_B, &"BodyB", body_b_stream, BODY_A)  # ping-pong back

	_interactive.set_clip_name(OUTRO, &"Outro")
	_interactive.set_clip_stream(OUTRO, outro_stream)
	_interactive.set_clip_auto_advance(OUTRO, AudioStreamInteractive.AUTO_ADVANCE_DISABLED)

	_interactive.initial_clip = INTRO

	# Auto-advance transitions (fire at each clip's END, no BPM needed).
	_add_end_transition(INTRO, BODY_A)
	_add_end_transition(BODY_A, BODY_B)
	_add_end_transition(BODY_B, BODY_A)
	# From ANY clip to the outro, at the end of the current clip.
	_add_end_transition(AudioStreamInteractive.CLIP_ANY, OUTRO)

	_player = AudioStreamPlayer.new()
	_player.stream = _interactive
	_player.bus = bus_name
	add_child(_player)

	if intro_stream == null or body_a_stream == null or body_b_stream == null or outro_stream == null:
		push_warning("BGMInteractive: one or more clip streams are not assigned.")

func _setup_clip(index: int, clip_name: StringName, stream: AudioStream, next_clip: int) -> void:
	_interactive.set_clip_name(index, clip_name)
	_interactive.set_clip_stream(index, stream)
	_interactive.set_clip_auto_advance(index, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	_interactive.set_clip_auto_advance_next_clip(index, next_clip)

func _add_end_transition(from_clip: int, to_clip: int) -> void:
	_interactive.add_transition(from_clip, to_clip,
		AudioStreamInteractive.TRANSITION_FROM_TIME_END,
		AudioStreamInteractive.TRANSITION_TO_TIME_START,
		AudioStreamInteractive.FADE_DISABLED, 0.0)

## Start (or restart) from the intro.
func play_bgm() -> void:
	_param = Parameter.INGAME
	_player.play()

func stop_bgm() -> void:
	_player.stop()

## INGAME = keep looping the body. GAMEENDS = go to the outro at the next body end.
func set_parameter(p: Parameter) -> void:
	_param = p
	if p == Parameter.GAMEENDS:
		var pb := _player.get_stream_playback() as AudioStreamPlaybackInteractive
		if pb != null:
			pb.switch_to_clip(OUTRO)

func get_parameter() -> Parameter:
	return _param

func get_current_clip_name() -> String:
	var pb := _player.get_stream_playback() as AudioStreamPlaybackInteractive
	if pb == null:
		return "-"
	var idx := pb.get_current_clip_index()
	return String(_interactive.get_clip_name(idx)) if idx >= 0 else "-"
