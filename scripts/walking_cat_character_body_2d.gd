extends CharacterBody2D

class_name Cat

@export var speed: float = 800.0
@export var jump_velocity: float = -800.0
@export var input_enabled = true
@export var player2 = false

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Node References (Matched to your .tscn unique names)
@onready var anim = $walking_cat_animation_2D
@onready var sfx_idle = $SfxIdle
@onready var sfx_jump = $SfxJump
@onready var sfx_run = $SfxRun

func _ready():
	add_to_group("cat")
	
func _get_player_string(s):
	if player2:
		return str(s, "_p2")
	return s

func _physics_process(delta):
	if not visible: return
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Handle Jump (Space Bar)
	if input_enabled and Input.is_action_just_pressed(_get_player_string("move_up")) and is_on_floor():
		velocity.y = jump_velocity
		sfx_jump.play() # Play jump once

	# 3. Get Movement Input (Left/Right)
	var direction = Input.get_axis(_get_player_string("move_left"), _get_player_string("move_right"))
	
	if input_enabled and direction:
		velocity.x = move_toward(velocity.x, direction * speed, delta * speed)
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, delta * speed)

	# 4. Air Animation logic
	if not is_on_floor():
		anim.play(_get_player_string("jump"))
	elif input_enabled and direction:
		anim.play(_get_player_string("walk"))
	else:
		anim.play(_get_player_string("idle"))

	# 5. Apply movement
	move_and_slide()
	
	# 6. Handle Sound States
	manage_audio(direction)

func manage_audio(direction: float):
	if is_on_floor():
		if direction != 0:
			if not sfx_run.playing:
				sfx_run.play()

			if sfx_idle.playing:
				sfx_idle.stop()
		else:
			if not sfx_idle.playing:
				sfx_idle.play()

			if sfx_run.playing:
				sfx_run.stop()
	else:
		if sfx_run.playing:
			sfx_run.stop()
		if sfx_idle.playing:
			sfx_idle.stop()
