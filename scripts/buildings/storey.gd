extends Node2D

@export var building_type = 1;
var _nodes = {
	1: 'Storey1',
	2: 'Storey2',
	3: 'Storey3',
	4: 'Storey4',
	5: 'Storey5',
}

func _ready() -> void:
	get_node("Storey1").visible = false
	get_node(_nodes[building_type]).visible = true
