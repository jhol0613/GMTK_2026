extends Node

## Control harness for a HAND-BUILT AudioStreamInteractive on the $Player node.
## You build the interactive stream in the editor (4 clips: intro, bodyA, bodyB,
## outro). This script only drives it. The outro is targeted by INDEX, so the
## clip name in the editor does not matter.
##   O = gameends (switch to the outro clip)
##   R = restart from the start

const OUTRO_CLIP := 3  ## The 4th clip in the list is the outro.

@onready var _player: AudioStreamPlayer = $Player
@onready var _label: Label = $UI/Label

func _ready() -> void:
	_player.play()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_O: _switch_to(OUTRO_CLIP)
			KEY_R: _player.stop(); _player.play()

func _switch_to(clip_index: int) -> void:
	var pb := _player.get_stream_playback() as AudioStreamPlaybackInteractive
	if pb != null:
		pb.switch_to_clip(clip_index)

func _process(_delta: float) -> void:
	_label.text = "O = gameends (-> Outro)   R = restart\nnow playing clip: %s" % _current_clip()

func _current_clip() -> String:
	var pb := _player.get_stream_playback() as AudioStreamPlaybackInteractive
	var stream := _player.stream as AudioStreamInteractive
	if pb == null or stream == null:
		return "-"
	var idx := pb.get_current_clip_index()
	return String(stream.get_clip_name(idx)) if idx >= 0 else "-"
