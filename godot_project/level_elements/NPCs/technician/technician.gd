extends Npc
class_name Technician

## Animations during which the fixing sound should be heard.
const FIXING_ANIMS: Array[StringName] = [&"fix_loop", &"fix_start"]

@onready var _fixing_sfx: AudioStreamPlayer2D = $FixingSfx


func _ready():
	super._ready()
	_state = State.ACTING
	setup_fixing_sfx()


## Called from _ready, and separately by subclasses that do not call super.
func setup_fixing_sfx() -> void:
	_sprite.animation_changed.connect(_on_fixing_anim_changed)
	_fixing_sfx.finished.connect(_on_fixing_sfx_finished)
	_on_fixing_anim_changed()


func _on_fixing_anim_changed() -> void:
	if _sprite.animation in FIXING_ANIMS:
		if not _fixing_sfx.playing:
			_fixing_sfx.play()
	else:
		_fixing_sfx.stop()


## fix_loop is continuous; fix_start is a one-shot lead-in to the explosion.
func _on_fixing_sfx_finished() -> void:
	if _sprite.animation == &"fix_loop":
		_fixing_sfx.play()
