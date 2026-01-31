extends Node2D

var _initial_x = 8
var _initial_y = -580
var _buildings = 5
var _storeys = 2
var _storey_nodes = []
var _storey_width = 986
var _storey_height = 512
var _roof_nodes = []
var _goal_node = null

var _storey_scene = load("res://scenes/buildings/storey.tscn")
var _roof_scene = load("res://scenes/buildings/roof.tscn")
var _goal_scene = load("res://scenes/buildings/goal.tscn")

func _ready() -> void:
	$Cat.disable_input()
	var world = $World
	for i in _buildings:
		for j in _storeys:
			var s = _storey_scene.instantiate()
			s.position = Vector2(_initial_x + (i-2)*_storey_width, _initial_y - j*_storey_height)
			s.building_type = i + 1
			_storey_nodes.append(s)
			world.add_child(s)
			
		var r = _roof_scene.instantiate()
		r.position = Vector2(_initial_x + (i-2)*_storey_width, _initial_y - _storeys*_storey_height + 50)
		r.building_type = i + 1
		_roof_nodes.append(r)
		world.add_child(r)
		
	_goal_node = _goal_scene.instantiate()
	_goal_node.position = Vector2(_initial_x, _initial_y - _storeys*_storey_height - 230)
	_goal_node.body_entered.connect(_on_goal_reached)
	world.add_child(_goal_node)
	
	var camera = $Cat/walking_car_camera_2D
	camera.zoom = Vector2(0.5, 0.5)
	camera.limit_left = _initial_x - _buildings*_storey_width/2
	camera.limit_right = _initial_x + _buildings*_storey_width/2
	camera.limit_bottom = 0
	
	await get_tree().create_timer(2.0).timeout
	var initial_camera_position = camera.position.y
	while camera.position.y > _goal_node.position.y:
		camera.position.y -= 10
		await get_tree().create_timer(0.01).timeout
		
	await get_tree().create_timer(0.5).timeout
	$HelpAudio.play()
	await get_tree().create_timer(1.0).timeout
	camera.position.y = initial_camera_position

	$Cat.enable_input()
	$CanvasLayer/UserInterface/Timer.start()

func _on_goal_reached(body):
	if body == $Cat:
		$ThanksAudio.play()
		$CanvasLayer/UserInterface/Timer.stop()

func _on_menu_button_pressed() -> void:
	$CanvasLayer/Transition.transition_to("res://scenes/menu/main.tscn")
