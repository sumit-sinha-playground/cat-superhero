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
	world.add_child(_goal_node)
	
	var camera = $Cat/walking_car_camera_2D
	camera.limit_left = _initial_x - _buildings*_storey_width/2
	camera.limit_right = _initial_x + _buildings*_storey_width/2
	camera.limit_bottom = 0


func _on_menu_button_pressed() -> void:
	$CanvasLayer/Transition.transition_to("res://scenes/menu/main.tscn")
