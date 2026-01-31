extends TextureRect

func _ready() -> void:
	$AnimationPlayer.play_backwards("spin")

func transition_to(next_scene) -> void:
	var anim_player = $AnimationPlayer
	anim_player.play("spin")
	await anim_player.animation_finished
	get_tree().change_scene_to_file(next_scene)
