extends Node2D

@export var difficulty = 0

var _initial_x = 8
var _initial_y = -580
var _buildings = 5
var _min_storeys = 2
var _storey_mult = 2
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
	$BackgroundAudio.play()
	var world = $World
	var storeys = []
	var max_storeys = 0
	for i in _buildings:
		storeys.append(_min_storeys + i * difficulty * _storey_mult)
		max_storeys = max(max_storeys, storeys[-1])
	storeys = storeys.slice(0, _buildings - 1)
	storeys.shuffle()
	storeys.insert(_buildings / 2, max_storeys)

	for i in _buildings:
		for j in storeys[i]:
			var s = _storey_scene.instantiate()
			s.position = Vector2(_initial_x + (i-2)*_storey_width, _initial_y - j*_storey_height)
			s.building_type = i + 1
			for k in 3:
				var n = randf() * difficulty
				var w = s.get_node(str("Window", k + 1))
				if n > 0.75:
					w.type = StoreyWindow.Type.Empty
				elif n > 0.5:
					w.type = StoreyWindow.Type.Obstacle
				else:
					w.type = StoreyWindow.Type.Normal
			_storey_nodes.append(s)
			world.add_child(s)
			
		var r = _roof_scene.instantiate()
		r.position = Vector2(_initial_x + (i-2)*_storey_width, _initial_y - storeys[i]*_storey_height + 50)
		r.building_type = i + 1
		_roof_nodes.append(r)
		world.add_child(r)
		
	_goal_node = _goal_scene.instantiate()
	_goal_node.position = Vector2(_initial_x, _initial_y - max_storeys*_storey_height - 230)
	_goal_node.body_entered.connect(_on_goal_reached)
	world.add_child(_goal_node)
	
	var camera = $Cat/walking_car_camera_2D
	camera.zoom = Vector2(0.5, 0.5)
	camera.limit_left = _initial_x - _buildings*_storey_width/2
	camera.limit_right = _initial_x + _buildings*_storey_width/2
	camera.limit_bottom = 0
	
	await get_tree().create_timer(2.0).timeout
	var initial_camera_position = camera.position.y
	var target_y = _goal_node.position.y - 200
	var camera_speed = (camera.position.y - target_y) / 300
	while camera.position.y > target_y:
		camera.position.y -= camera_speed
		await get_tree().create_timer(0.01).timeout
		
	await get_tree().create_timer(0.5).timeout
	$HelpAudio.play()
	await get_tree().create_timer(1.0).timeout
	camera.position.y = initial_camera_position

	_goal_node.get_node("AnimatedSprite2D").play()
	_goal_node.get_node("AnimatedSprite2D").speed_scale = 1
	$Cat.enable_input()
	$CanvasLayer/UserInterface/Timer.start()

func _on_goal_reached(body):
	if body == $Cat:
		_goal_node.get_node("AnimatedSprite2D").play("thanks")
		$ThanksAudio.play()
		$CanvasLayer/UserInterface/Timer.stop()

func _on_menu_button_pressed() -> void:
	$CanvasLayer/Transition.transition_to("res://scenes/menu/main.tscn")
