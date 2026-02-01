extends Node2D

@export var car_scene: PackedScene
@onready var cat = $walking_cat_character_body_2D
var puppy_rescued = false
var puppy = null

func _ready():
	var puppy_scene = load("res://scenes/suburbs/puppy.tscn")
	puppy = puppy_scene.instantiate()
	puppy.position = Vector2(randf_range(5000, 8000), 950)
	add_child(puppy)
	
	# Play sad animation and connect collision signals
	var puppy_sprite = puppy.get_node("Area2D/AnimatedSprite2D")
	puppy_sprite.play("sad")
	
	var puppy_area = puppy.get_node("Area2D")
	puppy_area.body_entered.connect(_on_puppy_body_entered)

func _on_puppy_body_entered(body):
	# Check if the colliding body is the cat
	if body == cat and not puppy_rescued:
		puppy_rescued = true
		var puppy_sprite = puppy.get_node("Area2D/AnimatedSprite2D")
		puppy_sprite.animation = "happy"

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

	new_car.position.y = randf_range(900, 1350) 
	
	add_child(new_car)
