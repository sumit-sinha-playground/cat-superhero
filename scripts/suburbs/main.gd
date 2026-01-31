extends Node2D

@export var car_scene: PackedScene
@onready var cat = $walking_cat_character_body_2D

func _on_car_timer_timeout():
	var new_car = car_scene.instantiate()
	var spawn_in_front = randf() > 0.5
	var offset = 1200
	
	if spawn_in_front:
		new_car.position.x = cat.position.x + offset
		new_car.direction = -1
	else:
		new_car.position.x = cat.position.x - offset
		new_car.direction = 1

	new_car.position.y = 1350 
	
	add_child(new_car)
