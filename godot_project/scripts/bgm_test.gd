extends Node

## Keyboard test harness for BGMSequencer.
##   I = set parameter INGAME   (body keeps looping)
##   O = set parameter GAMEENDS (jump to outro at the next segment boundary)
##   R = restart from the intro

@onready var _seq: BGMSequencer = $BGMSequencer
@onready var _label: Label = $UI/Label

func _ready() -> void:
	_seq.bgm_finished.connect(_on_finished)
	_seq.play_bgm()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_I: _seq.set_parameter(BGMSequencer.Parameter.INGAME)
			KEY_O: _seq.set_parameter(BGMSequencer.Parameter.GAMEENDS)
			KEY_R: _seq.play_bgm()

func _process(_delta: float) -> void:
	var param_name := String(BGMSequencer.Parameter.keys()[_seq.get_parameter()])
	_label.text = "I = ingame   O = gameends   R = restart\nparameter: %s\nphase: %s\npos: %.2fs" % [
		param_name, _seq.get_phase_name(), _seq_pos()
	]

func _seq_pos() -> float:
	var p := _seq.get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer
	return p.get_playback_position() if p != null else 0.0

func _on_finished() -> void:
	pass
