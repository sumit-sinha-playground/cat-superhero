extends Node2D

@export var building_type = 1;
var _nodes = {
	1: 'Roof1',
	2: 'Roof2',
	3: 'Roof3',
	4: 'Roof4',
	5: 'Roof5',
}

func _ready() -> void:
	get_node("Roof1").visible = false
	get_node(_nodes[building_type]).visible = true
