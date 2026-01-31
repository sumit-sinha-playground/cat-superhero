extends Control

func _on_play_button_pressed() -> void:
	get_node("Menu/PlayButton").visible = false
	get_node("Menu/LevelContainer").visible = true

func _on_tree_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_tree.tscn")

func _on_suburbs_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_suburbs.tscn")

func _on_buildings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/buildings/main.tscn")
