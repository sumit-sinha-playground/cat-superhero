extends TextureRect

@onready var _animation_player = $AnimationPlayer
@onready var _transition_audio = $TransitionAudio

func _ready() -> void:
	visible = true
	_animation_player.play_backwards("spin")
	await _animation_player.animation_finished
	_transition_audio.stop()

func transition_to(next_scene) -> void:
	transition_to_and_set_data(next_scene, func (s): s)

func transition_to_and_set_data(next_scene, data_callback: Callable) -> void:
	_animation_player.play("spin")
	_transition_audio.play()
	await _animation_player.animation_finished
	var s = load(next_scene).instantiate()
	data_callback.call(s)
	get_tree().change_scene_to_node(s)
