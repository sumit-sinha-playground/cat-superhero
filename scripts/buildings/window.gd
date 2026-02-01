extends StaticBody2D

class_name StoreyWindow

enum Type {Normal, Obstacle, Empty}

@export var type = Type.Normal
var _nodes = {
	1: ['Windows11', 'Windows12', 'Windows13'],
	2: ['Windows21', 'Windows22'],
	3: ['Windows31', 'Windows32', 'Windows33'],
	4: ['Windows41'],
	5: ['Windows51', 'Windows52', 'Windows53'],
}
var _obstacles = ['Obstacle1', 'Obstacle2', 'Obstacle3', 'Obstacle4', 'Obstacle5']

func _ready() -> void:
	get_node("Windows11").visible = false
	if type != Type.Empty:
		var available_nodes = _nodes[get_parent().building_type]
		var i = randi_range(0, available_nodes.size() - 1)
		get_node(available_nodes[i]).visible = true
	else:
		remove_child(get_node("BottomSill"))
		remove_child(get_node("TopSill"))
	
	if type == Type.Obstacle:
		var j = randi_range(0, _obstacles.size() - 1)
		var o = get_node(_obstacles[j])
		o.visible = true
		o.body_entered.connect(_on_obstacle_body_entered.bind(o))

func _on_obstacle_body_entered(body: Node2D, obstacle: Area2D) -> void:
	var player := body as Cat
	if not player:
		return
	var normal = player.global_position - obstacle.global_position
	player.velocity = player.velocity.bounce(normal.normalized()).normalized() * 1500
