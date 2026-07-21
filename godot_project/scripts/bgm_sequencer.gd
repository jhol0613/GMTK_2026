extends Node
class_name BGMSequencer

## Horizontal-resequencing BGM tool. One audio file is split into three regions
## by time: INTRO -> BODY -> OUTRO.
##
##   parameter = INGAME   : play the intro once, then loop the BODY forever.
##   parameter = GAMEENDS : let the CURRENT body segment finish, then jump to
##                          the OUTRO (plays once, then stops).
##
## "Segments" are transition-safe boundaries inside the body. When gameends is
## requested mid-body, the switch to the outro waits for the next segment marker
## (or the body end) so it lands on a musical beat instead of cutting a phrase.
##
## Times are in SECONDS (read them off your DAW). Godot has no visual waveform
## marker editor, so markers live as a timestamp array in the Inspector.
##
## IMPORTANT: set the file's Import "Loop Mode" to *Disabled* — this node does
## the looping itself.

signal bgm_finished

enum Parameter { INGAME, GAMEENDS }

@export var stream: AudioStream

@export_group("Regions (seconds)")
@export var intro_end: float = 2.0   ## Body starts here (also the body loop-back point).
@export var body_end: float = 6.0    ## Outro starts here (also the body loop end).
## Extra transition points inside the body. gameends waits for the next of these
## (or body_end) before jumping to the outro. Empty = only transition at body_end.
@export var segment_markers: PackedFloat32Array = PackedFloat32Array()

@export_group("Mix")
@export var switch_fade: float = 0.04  ## Tiny fade on the outro jump to hide the seek click.
@export var bus_name: StringName = &"Master"

enum _Phase { STOPPED, INTRO, BODY, OUTRO }

var _player: AudioStreamPlayer
var _param: Parameter = Parameter.INGAME
var _phase: int = _Phase.STOPPED
var _pending_outro: bool = false
var _last_pos: float = 0.0

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	_player.bus = bus_name
	add_child(_player)
	set_process(false)
	if stream == null:
		push_warning("BGMSequencer: no stream assigned.")

## Start (or restart) the BGM from the intro.
func play_bgm() -> void:
	if _player.stream == null:
		return
	_param = Parameter.INGAME
	_pending_outro = false
	_phase = _Phase.INTRO
	_player.play(0.0)
	_last_pos = 0.0
	set_process(true)

func stop_bgm() -> void:
	_player.stop()
	_phase = _Phase.STOPPED
	set_process(false)

## Change the game parameter. Requesting GAMEENDS while the body is playing
## schedules the outro for the next segment boundary.
func set_parameter(p: Parameter) -> void:
	_param = p
	if p == Parameter.GAMEENDS and _phase == _Phase.BODY:
		_pending_outro = true

func get_parameter() -> Parameter:
	return _param

func get_phase_name() -> String:
	return String(_Phase.keys()[_phase])

func _process(_delta: float) -> void:
	if _phase == _Phase.STOPPED:
		return
	var pos := _player.get_playback_position()

	# Intro flows straight into the body (same file, no seek needed).
	if _phase == _Phase.INTRO and pos >= intro_end:
		_phase = _Phase.BODY

	if _phase == _Phase.BODY:
		if _pending_outro:
			# Jump to the outro once we cross the next segment boundary.
			if _crossed_boundary(_last_pos, pos):
				_jump_to(body_end, true)
				_phase = _Phase.OUTRO
				_pending_outro = false
		elif pos >= body_end:
			# Seamless-ish body loop (plain seek, no fade to avoid pumping).
			_jump_to(intro_end, false)

	elif _phase == _Phase.OUTRO:
		if not _player.playing:
			_phase = _Phase.STOPPED
			set_process(false)
			bgm_finished.emit()
			return

	_last_pos = _player.get_playback_position()

## True if a segment boundary (any marker, or body_end) lies in (prev, now].
func _crossed_boundary(prev: float, now: float) -> bool:
	var points := Array(segment_markers)
	points.append(body_end)
	for b in points:
		if prev < b and now >= b:
			return true
	return false

func _jump_to(t: float, with_fade: bool) -> void:
	if with_fade and switch_fade > 0.0:
		_player.volume_db = -40.0
		_player.seek(t)
		var tw := create_tween()
		tw.tween_property(_player, "volume_db", 0.0, switch_fade)
	else:
		_player.seek(t)
	_last_pos = t
