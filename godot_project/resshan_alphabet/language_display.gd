@tool
class_name ResshanLabel2D
extends Node2D


@export_multiline() var string:String :
	set(value):
		string = value
		queue_redraw()


var _shapes: Array[RectangleShape2D]
var _areas: Array[ResshanInteractable]


func _draw() -> void:
	_shapes = LanguageRenderer.draw_text(string, self)
	for i:Node in _areas:
		i.queue_free()
	
	for shape: RectangleShape2D in _shapes:
		var area: = ResshanInteractable.new()
		var collision_shape: = CollisionShape2D.new()
		var pos:Vector2 = shape.get_meta('text_position')
		var encoded:String = shape.get_meta('encoded_text')
		
		area.position = pos
		area.position.y -= 8
		area.position.x += shape.size.x * 0.5
		area._encoded_string = encoded
		collision_shape.shape = shape
		area.add_child(collision_shape)
		
		_areas.append(area)
		add_child(area)
