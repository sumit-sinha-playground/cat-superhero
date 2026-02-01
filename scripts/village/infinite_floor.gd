extends Node2D

# Only use these ground assets
const ALLOWED_GROUNDS = [1, 10, 11, 12]
const ROCK_TYPES = [1, 2]  # Rock_01 or Rock_02

@export var tile_width: int = 0
@export var rock_spawn_chance: float = 0.01  # 1% chance per tile to spawn a rock
@export var rock_scale: float = 1.0
@export var floor_y: int = 300
@export var floor_offset: int = 128  # vertical offset to move floor down
@export var min_rock_spacing: int = 256  # minimum horizontal distance between rocks
@export var buffer_tiles: int = 8
@export var start_x: int = -512

var textures = {}  # dict: ground_id -> Texture2D
var rock_textures = {}  # dict: rock_id -> Texture2D
var tiles = []
var rocks = []  # List to track rock bodies for cleanup
var stalls = []  # List to track stall bodies for cleanup
var last_rock_x: float = -INF
var last_ground_id = 1  # Start with Ground_01

# --- STALL LOGIC VARIABLES ---
var last_stall_count: int = 0  # 0 = none, 1 = single, 2 = stacked
@export var stall_scale: float = 1.0
var stall_texture: Texture2D = null

@export var elevation_change: int = 128  # pixels to move up/down per incline/decline

var current_floor_y: int = 300  # Track dynamic floor height
@export var use_background: bool = true
@export var background_parallax: float = 0.5
var background_textures = []
var background_layer: Node2D = null
var left_boundary: StaticBody2D = null
var _fallback_texture: Texture2D = null
@export var bottom_margin: int = 0

func _ready():
	randomize()
	
	# Load only allowed ground textures
	for id in ALLOWED_GROUNDS:
		var path = "res://assets/village/Ground_%02d.png" % id
		if ResourceLoader.exists(path):
			textures[id] = load(path)
	
	# Load rock textures
	for id in ROCK_TYPES:
		var path = "res://assets/village/Rock_%02d.png" % id
		if ResourceLoader.exists(path):
			rock_textures[id] = load(path)

	# Load stall texture
	var stall_path = "res://assets/village/Stall_01.png"
	if ResourceLoader.exists(stall_path):
		stall_texture = load(stall_path)
	
	if tile_width <= 0:
		for id in ALLOWED_GROUNDS:
			if id in textures and textures[id]:
				tile_width = int(textures[id].get_width())
				break

	_update_floor_y()

	# Create initial strip of tiles
	var x = start_x
	for i in range(buffer_tiles * 2):
		_add_tile(x)
		
		if randf() < rock_spawn_chance:
			_spawn_rock(x)

		_determine_and_spawn_stall(x)
		x += tile_width

	_create_left_boundary()

	if use_background:
		_init_backgrounds()

## --- STALL SPAWNING SYSTEM ---

func _determine_and_spawn_stall(x_pos: int) -> void:
	"""
	Implements specific probability chain:
	1. 15% base chance to start a stall.
	2. 12% chance to increase stack count from previous tile.
	3. 30% chance to keep the same stack count as previous tile.
	"""
	if not stall_texture:
		last_stall_count = 0
		return

	var current_count = 0
	var roll = randf()

	if last_stall_count == 0:
		# Rule 1: 5% chance to start a stall if none existed previously
		if roll < 0.15:
			current_count = 1
	else:
		# Rule 2: 12% chance to add one more stall to the stack
		if roll < 0.12:
			current_count = last_stall_count + 1
		# Rule 3: 30% chance to have the same number of stalls
		# Using cumulative probability (0.12 + 0.30 = 0.42)
		elif roll < 0.42:
			current_count = last_stall_count
		else:
			# Otherwise, the chain ends
			current_count = 0

	if current_count > 0:
		_spawn_stall(x_pos, current_count)
	
	last_stall_count = current_count

func _spawn_stall(x_pos: int, count: int) -> void:
	"""Spawn `count` stalls stacked vertically at x_pos."""
	var tex_w = stall_texture.get_width() * stall_scale
	var tex_h = stall_texture.get_height() * stall_scale
	var base_y = current_floor_y + floor_offset - int(tex_h)

	for i in range(count):
		var body = StaticBody2D.new()
		body.name = "Stall_S%d_L%d" % [x_pos, i]
		# Stack up: level 0 is floor, level 1 is on top, etc.
		var y = base_y - (int(tex_h) * i)
		body.position = Vector2(x_pos, y)
		add_child(body)
		body.z_index = 12

		var sprite = Sprite2D.new()
		sprite.texture = stall_texture
		sprite.scale = Vector2(stall_scale, stall_scale)
		body.add_child(sprite)
		sprite.z_index = 13

		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(tex_w, tex_h)
		collision.shape = shape
		body.add_child(collision)

		stalls.append(body)

## --- GROUND & ENVIRONMENT SYSTEM ---

func _add_tile(x_pos: int) -> Node2D:
	var ground_id = _get_next_ground_id(last_ground_id)
	last_ground_id = ground_id
	
	var body = StaticBody2D.new()
	body.position = Vector2(x_pos, current_floor_y + floor_offset)
	add_child(body)

	var s = Sprite2D.new()
	var tex: Texture2D = textures.get(ground_id)
	
	if not tex:
		var ft = _get_fallback_texture(tile_width, tile_width, Color(0.25, 0.12, 0.05))
		s.texture = ft
	else:
		s.texture = tex

	var tex_h = s.texture.get_height()
	s.position = Vector2(0, -tex_h/2)
	body.add_child(s)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(s.texture.get_width(), tex_h)
	collision.shape = shape
	collision.position = Vector2(0, -tex_h/2 + _get_collision_offset(ground_id))
	body.add_child(collision)

	tiles.append(body)
	current_floor_y += _get_floor_y_adjustment(ground_id)
	return body

func _spawn_rock(x_pos: int) -> void:
	if abs(x_pos - last_rock_x) < min_rock_spacing: return
	var rock_id = ROCK_TYPES.pick_random()
	var rock_texture = rock_textures.get(rock_id)
	if not rock_texture: return

	var body = StaticBody2D.new()
	var tex_h = rock_texture.get_height() * rock_scale
	body.position = Vector2(x_pos, current_floor_y + floor_offset - int(tex_h))
	add_child(body)
	body.z_index = 10

	var sprite = Sprite2D.new()
	sprite.texture = rock_texture
	sprite.scale = Vector2(rock_scale, rock_scale)
	body.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = (rock_texture.get_width() * rock_scale) * 0.4
	shape.height = tex_h
	collision.shape = shape
	body.add_child(collision)

	rocks.append(body)
	last_rock_x = x_pos

func _get_floor_y_adjustment(ground_id: int) -> int:
	return -elevation_change if ground_id == 1 else 0

func _get_collision_offset(ground_id: int) -> float:
	return -10.0 if ground_id == 1 else 0.0

func _get_next_ground_id(current_id: int) -> int:
	match current_id:
		1: return [1, 10].pick_random()
		10: return 11
		11: return [11, 12].pick_random()
		12: return 11
		_: return 1

func _create_left_boundary() -> void:
	var wall = StaticBody2D.new()
	wall.position = Vector2(start_x - 100, current_floor_y + floor_offset)
	add_child(wall)
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 4000)
	collision.shape = shape
	wall.add_child(collision)
	left_boundary = wall

func _init_backgrounds() -> void:
	for i in [1, 2]:
		var path = "res://assets/village/Background_%02d.png" % i
		if ResourceLoader.exists(path):
			background_textures.append(load(path))
	background_layer = Node2D.new()
	add_child(background_layer)
	background_layer.z_index = -20
	for tex in background_textures:
		for i in range(-2, 10):
			var s = Sprite2D.new()
			s.texture = tex
			s.position = Vector2(i * tex.get_width(), 0)
			background_layer.add_child(s)

func _get_fallback_texture(w: int, h: int, color: Color) -> Texture2D:
	if _fallback_texture: return _fallback_texture
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	_fallback_texture = ImageTexture.create_from_image(img)
	return _fallback_texture

func _physics_process(_delta: float) -> void:
	var player = get_node_or_null("../walking_cat_character_body_2D")
	if not player: return
	var player_x = player.global_position.x

	if use_background and background_layer:
		background_layer.position.x = -player_x * (1.0 - background_parallax)

	var rightmost = -INF
	for t in tiles: rightmost = max(rightmost, t.global_position.x)

	while rightmost < player_x + buffer_tiles * tile_width:
		rightmost += tile_width
		_add_tile(rightmost)
		if randf() < rock_spawn_chance: _spawn_rock(rightmost)
		_determine_and_spawn_stall(rightmost)

	_cleanup_offscreen(player_x)

func _cleanup_offscreen(player_x: float) -> void:
	var limit = player_x - buffer_tiles * tile_width
	var filter_func = func(node):
		if node.global_position.x < limit:
			node.queue_free()
			return false
		return true
	tiles = tiles.filter(filter_func)
	rocks = rocks.filter(filter_func)
	stalls = stalls.filter(filter_func)

func _update_floor_y() -> void:
	var cam = get_viewport().get_camera_2d()
	var vp = get_viewport_rect()
	var new_y = (cam.global_position.y + vp.size.y * 0.5 - bottom_margin) if cam else (vp.size.y - bottom_margin)
	current_floor_y = int(new_y)
