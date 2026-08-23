extends Area2D

##If an entity enters this zone, their sorting layer will change. When they
##leave this zone, it will go back to what it was originally
class_name LayerTransitionZone

@export_flags_2d_physics var default_mask := 1
@export_flags_2d_physics var default_layer := 2
##This is the index entities will transition to when they enter the zone
@export var transition_z_index := 0

var original_z_index : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	original_z_index = body.z_index
	body.z_index = transition_z_index

func _on_body_exited(body: Node2D):
	body.z_index = original_z_index
