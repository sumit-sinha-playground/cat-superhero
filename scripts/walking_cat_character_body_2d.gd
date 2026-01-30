extends CharacterBody2D

@export var speed: float = 800.0
@export var jump_velocity: float = -800.0

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Updated to match your screenshot name exactly
@onready var anim = $walking_cat_animation_2D

func _physics_process(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Handle Jump (Space Bar)
	# "ui_accept" is mapped to Space by default in Godot
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		anim.play("jump")

	# 3. Get Movement Input (Left/Right Arrows)
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * speed
		anim.flip_h = direction < 0
		
		# Only play walk if we are touching the ground
		if is_on_floor():
			anim.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		
		# Only play idle if we are touching the ground
		if is_on_floor():
			anim.play("idle")

	# 4. Air Animation logic
	# If we are falling and not currently playing the jump animation
	if not is_on_floor() and velocity.y > 0:
		anim.play("jump") # Or a "fall" animation if you have one

	move_and_slide()
