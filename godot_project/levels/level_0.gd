extends LevelTemplate

var _intro_conversation_scene
var _intro_falling_scene
var _intro_active := true

@onready var platform := $Platform
@onready var ui_layer := $UiOverlay
@onready var _skip_intro_layer: CanvasLayer = $SkipIntroLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	if TimeManager.consume_skip_intro():
		_begin_without_intro()
		return
	_intro_conversation_scene = preload("uid://b40aq7wt2wqcs").instantiate()
	_intro_falling_scene = preload("uid://dnm5746r17yej").instantiate()
	add_child(_intro_conversation_scene)
	_intro_conversation_scene.scene_complete.connect(_on_conversation_complete)
	_intro_falling_scene.scene_complete.connect(_on_falling_scene_complete)


func _begin_without_intro() -> void:
	_intro_active = false
	_remove_skip_intro_button()
	platform.arrive_upper_train(true)


func _remove_skip_intro_button() -> void:
	if is_instance_valid(_skip_intro_layer):
		_skip_intro_layer.queue_free()


func _skip_intro() -> void:
	if not _intro_active:
		return
	_intro_active = false
	_remove_skip_intro_button()

	_free_intro_scene(_intro_conversation_scene)
	_intro_conversation_scene = null
	_free_intro_scene(_intro_falling_scene)
	_intro_falling_scene = null

	AudioManager.restore_level_music(2.0)
	if not ui_layer._notebook.visible:
		ui_layer._on_notebook_button_pressed()
	platform.arrive_upper_train(true)


func _free_intro_scene(scene) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	if scene.scene_complete.is_connected(_on_conversation_complete):
		scene.scene_complete.disconnect(_on_conversation_complete)
	if scene.scene_complete.is_connected(_on_falling_scene_complete):
		scene.scene_complete.disconnect(_on_falling_scene_complete)
	scene.queue_free()


func _on_conversation_complete():
	add_child(_intro_falling_scene)
	await get_tree().create_timer(2).timeout
	AudioManager.play_tripped_music()


func _on_falling_scene_complete():
	platform.depart_upper_train()
	ui_layer._on_notebook_button_pressed()
	await get_tree().create_timer(10).timeout
	platform.arrive_upper_train(true)
	_intro_active = false
	_remove_skip_intro_button()
