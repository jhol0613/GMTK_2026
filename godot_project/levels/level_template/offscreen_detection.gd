extends Area2D

@export var right : CollisionShape2D
@export var left : CollisionShape2D
@export var top : CollisionShape2D
@export var bottom : CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	var direction : Vector2 = Vector2(0,0)
	var own_shape : CollisionShape2D
	match local_shape_index:
		0: #right
			direction = Vector2(-1,0)
			own_shape = right
		1: #left
			direction = Vector2(1,0)
			own_shape = left
		2: #top
			direction = Vector2(0,1)
			own_shape = top
		3: #bottom
			direction = Vector2(0,-1)
			own_shape = bottom
	
	var owner_id : int = area.shape_find_owner(area_shape_index)
	var other : CollisionShape2D = area.shape_owner_get_owner(owner_id)
	
	var fuck : ResshanPopUp = other.owner
	print(fuck.get_global_transform_with_canvas())
	
	if other.owner.position: other.owner.position += direction
	
