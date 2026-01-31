extends CharacterBody2D

@export var speed: float = 800.0
@export var jump_velocity: float = -800.0

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Node References (Matched to your .tscn unique names)
@onready var anim = $walking_cat_animation_2D
@onready var sfx_idle = $SfxIdle
@onready var sfx_jump = $SfxJump
@onready var sfx_run = $SfxRun

func _physics_process(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Handle Jump (Space Bar)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		anim.play("jump")
		sfx_jump.play() # Play jump once

	# 3. Get Movement Input (Left/Right)
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * speed
		anim.flip_h = direction < 0
		
		if is_on_floor():
			anim.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		if is_on_floor():
			anim.play("idle")

	# 4. Air Animation logic
	if not is_on_floor() and velocity.y > 0:
		anim.play("jump")

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
