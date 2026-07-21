extends Node

## Keyboard test harness for BGMInteractive (native AudioStreamInteractive).
##   O = parameter GAMEENDS (go to outro at the next body end)
##   I = parameter INGAME   (keep looping the body)
##   R = restart from the intro

@onready var _bgm: BGMInteractive = $BGMInteractive
@onready var _label: Label = $UI/Label

func _ready() -> void:
	_bgm.play_bgm()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_O: _bgm.set_parameter(BGMInteractive.Parameter.GAMEENDS)
			KEY_I: _bgm.set_parameter(BGMInteractive.Parameter.INGAME)
			KEY_R: _bgm.stop_bgm(); _bgm.play_bgm()

func _process(_delta: float) -> void:
	var param_name := String(BGMInteractive.Parameter.keys()[_bgm.get_parameter()])
	_label.text = "O = gameends (-> outro at body end)   I = ingame   R = restart\nparameter: %s\nnow playing clip: %s" % [
		param_name, _bgm.get_current_clip_name()
	]
