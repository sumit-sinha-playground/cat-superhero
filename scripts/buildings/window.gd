extends StaticBody2D

var _nodes = {
	1: ['Windows11', 'Windows12', 'Windows13'],
	2: ['Windows21', 'Windows22'],
	3: ['Windows31', 'Windows32', 'Windows33'],
	4: ['Windows41'],
	5: ['Windows51', 'Windows52', 'Windows53'],
}

func _ready() -> void:
	get_node("Windows11").visible = false
	var available_nodes = _nodes[get_parent().building_type]
	var rng = RandomNumberGenerator.new()
	var i = rng.randi_range(0, available_nodes.size() - 1)
	get_node(available_nodes[i]).visible = true
