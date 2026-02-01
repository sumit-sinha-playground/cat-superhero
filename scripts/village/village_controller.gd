extends Node2D

@export var cat_path: NodePath = NodePath("walking_cat_character_body_2D")
@export var walk_direction: int = 1

@onready var cat = get_node_or_null(cat_path)
