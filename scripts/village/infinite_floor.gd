extends Node2D

const ALLOWED_GROUNDS = [1, 10, 11, 12]
const ROCK_TYPES = [1, 2] 

const PUPPY_SCENE = preload("res://scenes/village/puppy.tscn")
@export var puppy_spawn_x: int = 10000 

@export_group("Generation Settings")
@export var tile_width: int = 0
@export var rock_spawn_chance: float = 0.05 
@export var rock_scale: float = 1.0
@export var floor_offset: int = 0 
@export var min_rock_spacing: int = 300 
@export var start_x: int = -500
@export var end_x: int = 10500

@export_group("Boundaries")
@export var left_limit: int = -300
@export var right_limit: int = 10200

@export_group("Stall Settings")
@export var stall_scale: float = 1.0
@export var elevation_change: int = 64 

@export_group("Visuals")
@export var use_background: bool = true
@export var background_parallax: float = 0.3
@export var bottom_margin: int = 150

var textures = {} 
var rock_textures = {} 
var tiles = []
var rocks = [] 
var stalls = [] 
var last_rock_x: float = -INF
var last_stall_count: int = 0 
var stall_texture: Texture2D = null
var current_floor_y: int = 300 
var parallax_bg: ParallaxBackground = null
var _fallback_texture: Texture2D = null

var right_floor_y: int = 300
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
	
	if tile_width <= 0:
		_auto_detect_tile_width()

	if use_background:
		_init_infinite_background()
	
	# 1. Generate the fixed range immediately
	_force_generate_range(start_x, end_x)
	
	# 2. Setup boundary walls
	_add_boundary_wall(left_limit, Vector2.RIGHT) # Blocks left movement
	_add_boundary_wall(right_limit, Vector2.LEFT) # Blocks right movement
	
	# 3. Small delay to ensure engine stability
	await get_tree().create_timer(0.5).timeout
	
	# 4. Cinematic Intro
	_run_intro_camera_sequence()

func _physics_process(_delta: float) -> void:
	# Infinite generation removed as per request
	pass

func _force_generate_range(min_x: int, max_x: int) -> void:
	var current_x = min_x
	while current_x <= max_x:
		_add_tile(current_x)
		_try_spawn_decor(current_x, right_floor_y)
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
	var camera = player.get_node_or_null("walking_car_camera_2D")
	
	if not camera: return
	player.set_physics_process(false)
	
	if not puppy_node: 
		player.set_physics_process(true)
		return

	var original_position = camera.position
	camera.top_level = true 
	camera.global_position = player.global_position

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", puppy_node.global_position, 3.5)
	tween.tween_interval(1.5) 
	tween.tween_property(camera, "global_position", player.global_position, 2.0)
	
	tween.tween_callback(func():
		camera.top_level = false
		camera.position = original_position
		player.set_physics_process(true)
	)

func _get_player() -> Node2D:
	var p = get_node_or_null("../walking_cat_character_body_2D")
	while not p:
		await get_tree().process_frame
		p = get_node_or_null("../walking_cat_character_body_2D")
	return p

func _try_spawn_decor(x_pos: int, y_base: int) -> void:
	var is_puppy_tile = false
	if not puppy_spawned and x_pos >= puppy_spawn_x:
		_spawn_puppy(x_pos, y_base)
		puppy_spawned = true
		is_puppy_tile = true
	
	if not is_puppy_tile:
		if randf() < rock_spawn_chance:
			_spawn_rock(x_pos, y_base)
		_determine_and_spawn_stall(x_pos, y_base)

func _spawn_puppy(x_pos: int, y_base: int) -> void:
	var puppy_inst = PUPPY_SCENE.instantiate()
	var floor_h = 64
	if textures.has(1): floor_h = textures[1].get_height()
	
	puppy_inst.position = Vector2(x_pos, y_base + floor_offset - floor_h - 100)
	add_child(puppy_inst)
	puppy_node = puppy_inst
	
	var area = puppy_inst.get_node("Area2D")
	var anim_sprite = area.get_node("AnimatedSprite2D")
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

func _determine_and_spawn_stall(x_pos: int, y_base: int) -> void:
	if not stall_texture: return
	var current_count = 0
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

func _update_floor_y() -> void:
	current_floor_y = int(get_viewport_rect().size.y - bottom_margin)

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
