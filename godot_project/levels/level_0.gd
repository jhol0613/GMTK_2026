extends LevelTemplate

var _intro_conversation_scene
var _intro_falling_scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	_intro_conversation_scene = preload("uid://b40aq7wt2wqcs").instantiate()
	_intro_falling_scene = preload("uid://dnm5746r17yej").instantiate()
	add_child(_intro_conversation_scene)
	_intro_conversation_scene.scene_complete.connect(_on_conversation_complete)
	
func _on_conversation_complete():
	add_child(_intro_falling_scene)
