extends Node2D

const ALLOWED_GROUNDS = [1, 10, 11, 12]
const ROCK_TYPES = [1, 2] 

const PUPPY_SCENE = preload("res://scenes/village/puppy.tscn")
const RAT_SCENE = preload("res://scenes/village/rat.tscn") 

@export var puppy_spawn_x: int = 10000 

@export_group("Generation Settings")
@export var tile_width: int = 0
@export var rock_spawn_chance: float = 0.05 
@export var rock_scale: float = 1.0
@export var floor_offset: int = 0 
@export var min_rock_spacing: int = 300 
@export var start_x: int = -1000
@export var end_x: int = 11000

@export_group("Rat Settings")
@export var rat_spawn_chance: float = 0.1
@export var rat_speed: float = 200.0
@export var rat_scale: float = 2.0 # Scaled up to be visible against 64px tiles

@export_group("Boundaries")
@export var left_limit: int = -300
@export var right_limit: int = 10200

@export_group("Stall Settings")
@export var stall_scale: float = 1.0
@export var elevation_change: int = 64 

@export_group("Visuals")
@export var use_background: bool = true
@export var background_parallax: float = 0.3
# Set bottom_margin to 0 to keep the floor at the absolute bottom
@export var bottom_margin: int = 0

var textures = {} 
var rock_textures = {} 
var tiles = []
var rocks = [] 
var stalls = [] 
# Stores dictionaries: { "area": Area2D, "dir": int (-1 or 1), "sprite": AnimatedSprite2D }
var active_rats = [] 

var last_rock_x: float = -INF
var last_stall_count: int = 0 
var stall_texture: Texture2D = null
var current_floor_y: int = 0 
var parallax_bg: ParallaxBackground = null
var _fallback_texture: Texture2D = null

var right_floor_y: int = 0
var right_ground_id: int = 1

var puppy_spawned: bool = false
var puppy_node: Node2D = null 

func _ready():
	randomize()
	_load_resources()
	_update_floor_y()
	
	right_floor_y = current_floor_y
	right_ground_id = 1
	last_stall_count = 0
	active_rats.clear()
	
	if tile_width <= 0:
		_auto_detect_tile_width()

	if use_background:
		_init_infinite_background()
	
	# 1. Generate the fixed range
	_force_generate_range(start_x, end_x)
	
	# 2. Setup boundary walls
	_add_boundary_wall(left_limit, Vector2.RIGHT)
	_add_boundary_wall(right_limit, Vector2.LEFT)
	
	# 3. Small delay for stability
	await get_tree().create_timer(0.5).timeout
	
	# 4. Camera Setup & Intro
	_setup_camera_limits()
	_run_intro_camera_sequence()

func _physics_process(delta: float) -> void:
	# Handle Rat Movement
	for rat_data in active_rats:
		var area = rat_data["area"]
		var dir = rat_data["dir"]
		var sprite = rat_data["sprite"]
		
		# Move
		area.position.x += dir * rat_speed * delta
		
		# Update Visuals
		if sprite:
			# If dir is -1 (Left), flip_h should be true (assuming texture faces right by default)
			# Looking at your texture names, standard is usually right-facing.
			# If texture is left-facing by default, adjust logic. 
			# Assuming standard Right-facing sprites:
			sprite.flip_h = (dir > 0) 
			if sprite.animation != "walk":
				sprite.play("walk")

func _update_floor_y() -> void:
	# This sets the y-coordinate to the bottom of the viewport
	current_floor_y = int(get_viewport_rect().size.y - bottom_margin)

func _setup_camera_limits() -> void:
	var player = get_node_or_null("../walking_cat_character_body_2D")
	if not player: return
	var camera = player.get_node_or_null("walking_car_camera_2D")
	if not camera: return
	
	# Force the camera to stop at the floor level
	camera.limit_bottom = current_floor_y
	# Set limits for the sides as well
	camera.limit_left = left_limit
	camera.limit_right = right_limit

func _force_generate_range(min_x: int, max_x: int) -> void:
	var current_x = min_x
	while current_x <= max_x:
		_add_tile(current_x)
		
		# Determine if we need to force stalls (Start or End of map)
		var forced_stalls = -1
		if current_x == min_x:
			forced_stalls = 10
		elif current_x + tile_width > max_x:
			forced_stalls = 10
			
		_try_spawn_decor(current_x, right_floor_y, forced_stalls)
		current_x += tile_width

func _add_boundary_wall(x_pos: int, normal_dir: Vector2) -> void:
	var wall = StaticBody2D.new()
	wall.position = Vector2(x_pos, current_floor_y)
	var collision = CollisionShape2D.new()
	var shape = WorldBoundaryShape2D.new()
	shape.normal = normal_dir
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)

func _run_intro_camera_sequence() -> void:
	var player = await _get_player()
	
	_configure_player_jump_height(player)
	
	var camera = player.get_node_or_null("walking_car_camera_2D")
	
	if not camera: return
	player.set_physics_process(false)
	
	if not puppy_node: 
		player.set_physics_process(true)
		return

	var original_position = camera.position
	var original_limit_bottom = camera.limit_bottom
	
	camera.top_level = true 
	camera.global_position = player.global_position
	# Disable limits during the cinematic for smooth movement
	camera.limit_bottom = 100000 

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", puppy_node.global_position, 3.5)
	tween.tween_interval(1.5) 
	tween.tween_property(camera, "global_position", player.global_position, 2.0)
	
	tween.tween_callback(func():
		camera.top_level = false
		camera.position = original_position
		camera.limit_bottom = original_limit_bottom
		player.set_physics_process(true)
	)

func _get_player() -> Node2D:
	var p = get_node_or_null("../walking_cat_character_body_2D")
	while not p:
		await get_tree().process_frame
		p = get_node_or_null("../walking_cat_character_body_2D")
	return p

func _configure_player_jump_height(player: Node2D) -> void:
	if not stall_texture: return
	if "jump_velocity" not in player: return
	
	var stall_height = stall_texture.get_height() * stall_scale
	var buffer = 40.0 
	var target_jump_height = stall_height + buffer
	
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	var required_velocity = -sqrt(2.0 * gravity * target_jump_height)
	
	player.jump_velocity = required_velocity

func _try_spawn_decor(x_pos: int, y_base: int, forced_stall_count: int = -1) -> void:
	var is_puppy_tile = false
	if not puppy_spawned and x_pos >= puppy_spawn_x:
		_spawn_puppy(x_pos, y_base)
		puppy_spawned = true
		is_puppy_tile = true
	
	if not is_puppy_tile:
		# Exclusive spawning logic: Rock OR Rat OR Stall
		var spawned_something = false
		
		# 1. Try Rock
		if randf() < rock_spawn_chance:
			_spawn_rock(x_pos, y_base)
			spawned_something = true
			
		# 2. Try Rat (if no rock)
		if not spawned_something and randf() < rat_spawn_chance:
			_spawn_rat(x_pos, y_base)
			spawned_something = true
			
		# 3. Try Stall (if nothing else, or forced)
		# Note: Stalls have their own internal probability logic, but we run it
		# if nothing else blocked the tile, or if we are forcing it.
		if not spawned_something or forced_stall_count != -1:
			_determine_and_spawn_stall(x_pos, y_base, forced_stall_count)

func _spawn_rat(x_pos: int, y_base: int) -> void:
	# Calculate Position
	var floor_h = 64
	if textures.has(1): floor_h = textures[1].get_height()
	
	# Instantiate Visual Scene
	var rat_visual = RAT_SCENE.instantiate()
	
	# Create Physics Wrapper (Area2D)
	var rat_area = Area2D.new()
	rat_area.name = "Rat_Area_%d" % x_pos
	
	# Adjust Y: Base + Offset - Floor Height - (Half Rat Height roughly)
	# Visual sprite is approx 16px high * scale. 
	var visual_h = 16.0 * rat_scale
	rat_area.position = Vector2(x_pos, y_base + floor_offset - floor_h - (visual_h * 2.0) - 20)
	add_child(rat_area)
	rat_area.z_index = 6 # In front of stalls
	
	# Add Visuals
	rat_visual.scale = Vector2(rat_scale, rat_scale)
	rat_area.add_child(rat_visual)
	
	# Add Collision
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Hitbox size slightly smaller than visual
	shape.size = Vector2(24 * rat_scale, 12 * rat_scale) 
	col.shape = shape
	rat_area.add_child(col)
	
	# Get AnimatedSprite reference
	var sprite = rat_visual.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("walk")
	
	# Data Packet
	var rat_data = {
		"area": rat_area,
		"dir": -1, # Start moving LEFT
		"sprite": sprite
	}
	
	active_rats.append(rat_data)
	
	# Connect Signals using a bind to pass the specific rat_data
	rat_area.body_entered.connect(_on_rat_body_entered.bind(rat_data))

func _on_rat_body_entered(body: Node2D, rat_data: Dictionary) -> void:
	# 1. Collision with Player -> Game Over
	if "walking_cat" in body.name:
		call_deferred("_restart_scene")
		
	# 2. Collision with Stall -> Turn Around
	if body.is_in_group("stall"):
		rat_data["dir"] *= -1

func _restart_scene():
	get_tree().reload_current_scene()

func _spawn_puppy(x_pos: int, y_base: int) -> void:
	var puppy_inst = PUPPY_SCENE.instantiate()
	var floor_h = 64
	if textures.has(1): floor_h = textures[1].get_height()
	
	puppy_inst.position = Vector2(x_pos, y_base + floor_offset - floor_h - 100)
	add_child(puppy_inst)
	puppy_node = puppy_inst
	
	var area = puppy_inst.get_node_or_null("Area2D")
	if area:
		var anim_sprite = area.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.play("sad")
			area.body_entered.connect(_on_puppy_body_entered.bind(anim_sprite))

func _on_puppy_body_entered(body: Node2D, anim_sprite: AnimatedSprite2D) -> void:
	if "walking_cat" in body.name:
		anim_sprite.play("happy")

func _add_tile(x_pos: int) -> void:
	var ground_id = _get_next_ground_id(right_ground_id)
	right_ground_id = ground_id
	
	var body = StaticBody2D.new()
	body.position = Vector2(x_pos, right_floor_y + floor_offset)
	add_child(body)

	var s = Sprite2D.new()
	s.texture = textures.get(ground_id, _get_fallback_texture(tile_width, 64, Color.DARK_GRAY))
	s.centered = false
	var tex_w = s.texture.get_width()
	var tex_h = s.texture.get_height()
	s.position = Vector2(-tex_w / 2.0, -tex_h)
	body.add_child(s)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(tex_w, tex_h)
	collision.shape = shape
	collision.position = Vector2(0, -tex_h / 2.0 + _get_collision_offset(ground_id))
	body.add_child(collision)

	tiles.append(body)
	right_floor_y += _get_floor_y_adjustment(ground_id)

func _spawn_rock(x_pos: int, y_base: int) -> void:
	if abs(x_pos - last_rock_x) < min_rock_spacing: return
	var rock_id = ROCK_TYPES.pick_random()
	var rock_tex = rock_textures.get(rock_id)
	if not rock_tex: return
	var floor_h = 64
	if textures.has(1): floor_h = textures[1].get_height()
	var body = StaticBody2D.new()
	var tex_h = rock_tex.get_height() * rock_scale
	var tex_w = rock_tex.get_width() * rock_scale
	body.position = Vector2(x_pos, y_base + floor_offset - floor_h)
	add_child(body)
	body.z_index = 2
	var sprite = Sprite2D.new()
	sprite.texture = rock_tex
	sprite.scale = Vector2(rock_scale, rock_scale)
	sprite.centered = false
	sprite.position = Vector2(-tex_w / 2.0, -tex_h / 2.0)
	body.add_child(sprite)
	rocks.append(body)
	last_rock_x = x_pos

func _determine_and_spawn_stall(x_pos: int, y_base: int, forced_count: int = -1) -> void:
	if not stall_texture: return
	var current_count = 0
	
	if forced_count != -1:
		current_count = forced_count
	else:
		var roll = randf()
		if last_stall_count == 0:
			if roll < 0.15: current_count = 1
		else:
			if roll < 0.20: current_count = last_stall_count + 1
			elif roll < 0.45: current_count = last_stall_count
			else: current_count = 0
			
	if current_count > 0:
		_spawn_stall(x_pos, y_base, current_count)
	last_stall_count = current_count

func _spawn_stall(x_pos: int, y_base: int, count: int) -> void:
	var tex_w = stall_texture.get_width() * stall_scale
	var tex_h = stall_texture.get_height() * stall_scale
	var floor_h = 64
	if textures.has(1): floor_h = textures[1].get_height()
	var ground_line = y_base + floor_offset - floor_h
	for i in range(count):
		var body = StaticBody2D.new()
		# Add stall to group so rats can detect it
		body.add_to_group("stall")
		
		var vertical_position = ground_line - (tex_h * i)
		body.position = Vector2(x_pos, vertical_position)
		add_child(body)
		body.z_index = 5
		var sprite = Sprite2D.new()
		sprite.texture = stall_texture
		sprite.scale = Vector2(stall_scale, stall_scale)
		sprite.centered = false
		sprite.position = Vector2(-tex_w / 2.0, -tex_h)
		body.add_child(sprite)
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(tex_w, tex_h)
		collision.shape = shape
		collision.position = Vector2(0, -tex_h / 2.0)
		body.add_child(collision)
		stalls.append(body)

func _get_floor_y_adjustment(id: int) -> int: 
	return -elevation_change if id == 1 else 0

func _get_collision_offset(id: int) -> float: 
	return -5.0 if id == 1 else 0.0

func _get_next_ground_id(curr: Variant) -> int:
	var id: int = 1
	if curr != null: id = int(curr)
	match id:
		1: return [1, 10].pick_random()
		10: return 11
		11: return [11, 12].pick_random()
		12: return 11
		_: return 1

func _load_resources():
	for id in ALLOWED_GROUNDS:
		var path = "res://assets/village/Ground_%02d.png" % id
		if ResourceLoader.exists(path): textures[id] = load(path)
	for id in ROCK_TYPES:
		var path = "res://assets/village/Rock_%02d.png" % id
		if ResourceLoader.exists(path): rock_textures[id] = load(path)
	var stall_path = "res://assets/village/Stall_01.png"
	if ResourceLoader.exists(stall_path): stall_texture = load(stall_path)

func _auto_detect_tile_width():
	for id in ALLOWED_GROUNDS:
		if id in textures:
			tile_width = int(textures[id].get_width())
			break
	if tile_width <= 0: tile_width = 128

func _init_infinite_background() -> void:
	parallax_bg = ParallaxBackground.new()
	parallax_bg.layer = -1
	add_child(parallax_bg)
	for i in [1, 2]:
		var path = "res://assets/village/Background_%02d.png" % i
		if ResourceLoader.exists(path):
			var tex = load(path)
			var layer = ParallaxLayer.new()
			layer.motion_scale = Vector2(background_parallax * i, 0.05)
			layer.motion_mirroring = Vector2(tex.get_width(), 0)
			var sprite = Sprite2D.new()
			sprite.texture = tex
			sprite.centered = false
			layer.add_child(sprite)
			parallax_bg.add_child(layer)

func _get_fallback_texture(w, h, color):
	if _fallback_texture: return _fallback_texture
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	_fallback_texture = ImageTexture.create_from_image(img)
	return _fallback_texture
