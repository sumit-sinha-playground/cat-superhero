extends Control

var _tree_scene = "res://scenes/level_tree.tscn"
var _suburbs_scene = "res://scenes/suburbs/main.tscn"
var _buildings_scene = "res://scenes/buildings/main.tscn"

var _characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

func _on_play_button_pressed() -> void:
	$Menu/PlayButton.visible = false
	$Menu/LevelContainer.visible = true

func _on_tree_button_pressed() -> void:
	get_tree().change_scene_to_file(_tree_scene)

func _on_suburbs_button_pressed() -> void:
	get_tree().change_scene_to_file(_suburbs_scene)

func _on_buildings_button_pressed() -> void:
	$Menu/LevelContainer.visible = false
	$Menu/BuildingsContainer.visible = true
	var s = _generate_seed()
	_on_seed_edit_text_changed(s)
	$Menu/BuildingsContainer/SeedContainer/SeedEdit.text = s
	

func _on_buildings_easy_button_pressed() -> void:
	$Transition.transition_to_and_set_data(_buildings_scene, func (s): s.difficulty = 0)

func _on_buildings_normal_button_pressed() -> void:
	$Transition.transition_to_and_set_data(_buildings_scene, func (s): s.difficulty = 1)

func _on_buildings_hard_button_pressed() -> void:
	$Transition.transition_to_and_set_data(_buildings_scene, func (s): s.difficulty = 2)
	
func _on_seed_edit_text_changed(s: String) -> void:
	seed(hash(s.to_upper()))
	
func _generate_seed():
	var s = ''
	for i in 10:
		s += _characters[randi() % _characters.length()]
	return s
