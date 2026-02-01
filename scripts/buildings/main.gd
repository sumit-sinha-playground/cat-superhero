extends Node2D

@export var difficulty = 2

var _initial_x = 8
var _initial_y = -580
var _buildings = 5
var _windows = 3
var _min_storeys = 2
var _storey_mult = 2
var _storey_nodes = []
var _storey_width = 986
var _storey_height = 512
var _roof_nodes = []
var _goal_node: Area2D = null

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
	storeys.insert(int(float(_buildings) / 2), max_storeys)

	var map = []
	for i in max_storeys:
		map.append([])
		for j in _buildings:
			for k in _windows:
				map[-1].append(storeys[j] < i)

	_dfs(map, int(float(_buildings * _windows) / 2), map.size() - 1)

	for i in _buildings:
		for j in storeys[i]:
			var s = _storey_scene.instantiate()
			s.position = Vector2(_initial_x + (i-2)*_storey_width, _initial_y - j*_storey_height)
			s.building_type = i + 1
			for k in 3:
				var n = randf() * difficulty
				var w = s.get_node(str("Window", k + 1))
				var is_on_critical_path = map[j][i * _windows + k]
				if not is_on_critical_path and n > 0.75:
					w.type = StoreyWindow.Type.Empty
				elif not is_on_critical_path and n > 0.5:
					w.type = StoreyWindow.Type.Obstacle
				elif is_on_critical_path and n > 0.75:
					w.type = StoreyWindow.Type.DelayedObstacle
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
	camera.limit_left = _initial_x - int(float(_buildings * _storey_width) / 2)
	camera.limit_right = _initial_x + int(float(_buildings * _storey_width) / 2)
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
	if body is Cat:
		_goal_node.get_node("AnimatedSprite2D").play("thanks")
		$ThanksAudio.play()
		$CanvasLayer/UserInterface/Timer.stop()

func _on_menu_button_pressed() -> void:
	$CanvasLayer/Transition.transition_to("res://scenes/menu/main.tscn")

func _dfs(map, x: int, y: int):
	if x < 0 or x >= map[0].size() or y < 0 or y >= map.size() or map[y][x]:
		return false
	map[y][x] = true
	if y == 0:
		return true

	var directions = [
		Vector2(-1, 0),
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(0, -1),
		Vector2(0, -1),
		Vector2(0, -1),
	]
	directions.shuffle()
	for d in directions:
		if _dfs(map, x + d.x, y + d.y):
			return true
	map[y][x] = false
	return false
