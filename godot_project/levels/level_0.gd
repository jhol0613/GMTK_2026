extends LevelTemplate


var _intro_conversation_scene
var _intro_falling_scene

@onready var platform := $Platform
@onready var ui_layer := $UiOverlay
@onready var audio_controller := $LevelAudioController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	_intro_conversation_scene = preload("uid://b40aq7wt2wqcs").instantiate()
	_intro_falling_scene = preload("uid://dnm5746r17yej").instantiate()
	add_child(_intro_conversation_scene)
	_intro_conversation_scene.scene_complete.connect(_on_conversation_complete)
	_intro_falling_scene.scene_complete.connect(_on_falling_scene_complete)

func _on_conversation_complete():
	add_child(_intro_falling_scene)
	await get_tree().create_timer(2).timeout
	audio_controller.play_tripped_music()
	

func _on_falling_scene_complete():
	platform.depart_upper_train()
	ui_layer._on_notebook_button_pressed()
	await get_tree().create_timer(10).timeout
	platform.arrive_upper_train()
