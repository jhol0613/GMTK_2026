extends Npc

@onready var _fixing_sfx: AudioStreamPlayer2D = $FixingSfx

func _ready() -> void:
	_interactable.interacted.connect(_on_dialogue_started)
	_panel.dialogue_complete.connect(_on_dialogue_complete)
	_sprite.play("fix_loop")
	_fixing_sfx.set("parameters/looping", true)
	_fixing_sfx.play()

func _on_dialogue_started():
	_fixing_sfx.stop()

func _on_dialogue_complete():
	_fixing_sfx.play()
	_sprite.play("fix_start")
	await _sprite.animation_finished
	_sprite.play("fix_loop")
	
