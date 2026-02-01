extends Node2D

@export var cat_path: NodePath = NodePath("walking_cat_character_body_2D")
@export var walk_direction: int = 1

@onready var cat = get_node_or_null(cat_path)

func _process(delta: float) -> void:
	if not cat:
		return
	var spd = 400
	if "speed" in cat:
		spd = cat.speed
 
	cat.velocity.x = spd * walk_direction
	
	var anim = cat.get_node_or_null("walking_cat_animation_2D")
	if anim and cat.is_on_floor():
		anim.play("walk")
		anim.flip_h = walk_direction < 0
