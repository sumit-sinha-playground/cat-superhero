extends TextureRect

@onready var _animation_player = $AnimationPlayer
@onready var _transition_audio = $TransitionAudio

func _ready() -> void:
	_animation_player.play_backwards("spin")
	await _animation_player.animation_finished
	_transition_audio.stop()

func transition_to(next_scene) -> void:
	_animation_player.play("spin")
	_transition_audio.play()
	await _animation_player.animation_finished
	get_tree().change_scene_to_file(next_scene)
