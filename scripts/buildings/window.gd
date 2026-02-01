extends StaticBody2D

class_name StoreyWindow

enum Type {Normal, Obstacle, DelayedObstacle, Empty}

@export var type = Type.Normal
var _nodes = {
	1: ['Windows11', 'Windows12', 'Windows13'],
	2: ['Windows21', 'Windows22'],
	3: ['Windows31', 'Windows32', 'Windows33'],
	4: ['Windows41'],
	5: ['Windows51', 'Windows52', 'Windows53'],
}
var _obstacles = ['Obstacle1', 'Obstacle2', 'Obstacle3', 'Obstacle4', 'Obstacle5']
var _delayed_obstacle_index = 0
var _delayed_obstacle_entered = false
var _delayed_obstacles = ['DelayedObstacle1', 'DelayedObstacle2', 'DelayedObstacle2', 'DelayedObstacle3']
var _delayed_obstacle_audio = ['DelayedObstacleAudio1', 'DelayedObstacleAudio21',  'DelayedObstacleAudio22', 'DelayedObstacleAudio3']

func _ready() -> void:
	$Windows11.visible = false
	if type != Type.Empty:
		var available_nodes = _nodes[get_parent().building_type]
		var i = randi_range(0, available_nodes.size() - 1)
		get_node(available_nodes[i]).visible = true
	else:
		remove_child($BottomSill)
		remove_child($TopSill)
	
	if type == Type.Obstacle:
		var j = randi_range(0, _obstacles.size() - 1)
		var o = get_node(_obstacles[j])
		o.visible = true
		o.body_entered.connect(_on_obstacle_body_entered.bind(o))
		
	if type == Type.DelayedObstacle:
		$DelayedObstacleHitbox.body_entered.connect(_on_delayed_obstacle_hitbox_entered)
		_delayed_obstacle_index = randi_range(0, _delayed_obstacles.size() - 1)
		var o = get_node(_delayed_obstacles[_delayed_obstacle_index])
		o.body_entered.connect(_on_delayed_obstacle_body_entered.bind(o))
		o.body_exited.connect(_on_delayed_obstacle_body_exited)
		

func _on_obstacle_body_entered(body: Node2D, obstacle: Area2D) -> void:
	var player := body as Cat
	if not player: return
	var normal = player.global_position - obstacle.global_position
	var v = player.velocity.bounce(normal.normalized())
	if v.x == 0 and v.y == 0:
		v = Vector2(randf() - 0.5, -randf())
	player.velocity = v.normalized() * 1500

func _on_delayed_obstacle_hitbox_entered(body: Node2D) -> void:
	$DelayedObstacleHitbox.body_entered.disconnect(_on_delayed_obstacle_hitbox_entered)
	var o = get_node(_delayed_obstacles[_delayed_obstacle_index])
	get_node(_delayed_obstacle_audio[_delayed_obstacle_index]).play()
	
	await get_tree().create_timer(1.0).timeout
	
	o.visible = true
	if _delayed_obstacle_entered:
		_on_obstacle_body_entered(get_parent().get_parent().get_parent().get_node('Cat'), o)
	
	await get_tree().create_timer(5.0).timeout
	
	o.visible = false
	
	$DelayedObstacleHitbox.body_entered.connect(_on_delayed_obstacle_hitbox_entered)
	
func _on_delayed_obstacle_body_entered(body: Node2D, obstacle: Area2D) -> void:
	var player := body as Cat
	if not player: return
	_delayed_obstacle_entered = true
	if obstacle.visible: _on_obstacle_body_entered(body, obstacle)
	
func _on_delayed_obstacle_body_exited(body: Node2D) -> void:
	var player := body as Cat
	if not player: return
	_delayed_obstacle_entered = false
