extends Node2D


@export var sprite : AnimatedSprite2D
@export var speed : float = 100
var _flying : bool = false
var _flip : bool = false
var random_turn : SceneTreeTimer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_flip = randi() & 1
	if _flip:
		sprite.flip_h = true
	
	random_turn = get_tree().create_timer(randf_range(1,10))
	random_turn.timeout.connect(_turn)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _flying:
		if _flip:
			sprite.position += Vector2( -1,-1 ) * speed * delta
			return
		sprite.position += Vector2( 1,-1 ) * speed * delta
		
	


func _turn():
	match sprite.animation:
		"look_left": sprite.play("look_right")
		"look_right": sprite.play("look_left")
	random_turn = get_tree().create_timer(randf_range(1,10))
	random_turn.timeout.connect(_turn)


func _on_area_2d_body_entered(body: Node2D) -> void:
	_flying = true
	random_turn.timeout.disconnect(_turn)
	sprite.play("fly")
	var life_timer = get_tree().create_timer(4)
	life_timer.timeout.connect(queue_free)
