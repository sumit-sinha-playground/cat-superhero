extends Node2D

# Only use these ground assets
const ALLOWED_GROUNDS = [1, 10, 11, 12]
const ROCK_TYPES = [1, 2] 

@export var tile_width: int = 0
@export var rock_spawn_chance: float = 0.01 
@export var rock_scale: float = 1.0
@export var floor_y: int = 300
@export var floor_offset: int = 128 
@export var min_rock_spacing: int = 256 
@export var buffer_tiles: int = 8
@export var start_x: int = -512

var textures = {} 
var rock_textures = {} 
var tiles = []
var rocks = [] 
var stalls = [] 
var last_rock_x: float = -INF
var last_ground_id = 1 

# --- STALL LOGIC VARIABLES ---
var last_stall_count: int = 0 
@export var stall_scale: float = 1.0
var stall_texture: Texture2D = null

@export var elevation_change: int = 128 

var current_floor_y: int = 300 
@export var use_background: bool = true
@export var background_parallax: float = 0.5
var background_textures = []
var parallax_bg: ParallaxBackground = null
var left_boundary: StaticBody2D = null
var _fallback_texture: Texture2D = null
@export var bottom_margin: int = 0

func _ready():
	randomize()
	
	for id in ALLOWED_GROUNDS:
		var path = "res://assets/village/Ground_%02d.png" % id
		if ResourceLoader.exists(path):
			textures[id] = load(path)
	
	for id in ROCK_TYPES:
		var path = "res://assets/village/Rock_%02d.png" % id
		if ResourceLoader.exists(path):
			rock_textures[id] = load(path)

	var stall_path = "res://assets/village/Stall_01.png"
	if ResourceLoader.exists(stall_path):
		stall_texture = load(stall_path)
	
	if tile_width <= 0:
		for id in ALLOWED_GROUNDS:
			if id in textures and textures[id]:
				tile_width = int(textures[id].get_width())
				break

	_update_floor_y()

	var x = start_x
	for i in range(buffer_tiles * 2):
		_add_tile(x)
		if randf() < rock_spawn_chance:
			_spawn_rock(x)
		_determine_and_spawn_stall(x)
		x += tile_width

	_create_left_boundary()

	if use_background:
		_init_infinite_background()

func _init_infinite_background() -> void:
	"""Creates a ParallaxBackground that handles infinite looping automatically."""
	parallax_bg = ParallaxBackground.new()
	add_child(parallax_bg)

	for i in [1, 2]:
		var path = "res://assets/village/Background_%02d.png" % i
		if ResourceLoader.exists(path):
			var tex = load(path)
			var layer = ParallaxLayer.new()
			
			# Set the motion scale (0.5 = moves half as fast as player)
			layer.motion_scale = Vector2(background_parallax * i, 0)
			
			# The MAGIC: Mirroring set to the texture width makes it infinite
			layer.motion_mirroring = Vector2(tex.get_width(), 0)
			
			var sprite = Sprite2D.new()
			sprite.texture = tex
			sprite.centered = false # Easier for tiling alignment
			
			layer.add_child(sprite)
			parallax_bg.add_child(layer)

func _determine_and_spawn_stall(x_pos: int) -> void:
	if not stall_texture:
		last_stall_count = 0
		return

	var current_count = 0
	var roll = randf()

	if last_stall_count == 0:
		if roll < 0.15:
			current_count = 1
	else:
		if roll < 0.20:
			current_count = last_stall_count + 1
		elif roll < 0.45:
			current_count = last_stall_count
		else:
			current_count = 0

	if current_count > 0:
		_spawn_stall(x_pos, current_count)
	
	last_stall_count = current_count

func _spawn_stall(x_pos: int, count: int) -> void:
	var tex_w = stall_texture.get_width() * stall_scale
	var tex_h = stall_texture.get_height() * stall_scale
	var base_y = current_floor_y + floor_offset - int(tex_h)

	for i in range(count):
		var body = StaticBody2D.new()
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

func _add_tile(x_pos: int) -> Node2D:
	var ground_id = _get_next_ground_id(last_ground_id)
	last_ground_id = ground_id
	var body = StaticBody2D.new()
	body.position = Vector2(x_pos, current_floor_y + floor_offset)
	add_child(body)

	var s = Sprite2D.new()
	s.texture = textures.get(ground_id, _get_fallback_texture(tile_width, 64, Color.BROWN))
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
	rocks.append(body)
	last_rock_x = x_pos

func _get_floor_y_adjustment(id: int) -> int: return -elevation_change if id == 1 else 0
func _get_collision_offset(id: int) -> float: return -10.0 if id == 1 else 0.0
func _get_next_ground_id(curr: int) -> int:
	match curr:
		1: return [1, 10].pick_random()
		10: return 11
		11: return [11, 12].pick_random()
		12: return 11
		_: return 1

func _create_left_boundary() -> void:
	var wall = StaticBody2D.new()
	wall.position = Vector2(start_x - 100, current_floor_y)
	add_child(wall)
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 4000)
	col.shape = shape
	wall.add_child(col)
	left_boundary = wall

func _physics_process(_delta: float) -> void:
	var player = get_node_or_null("../walking_cat_character_body_2D")
	if not player: return
	var player_x = player.global_position.x

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
	var filter_node = func(node):
		if node.global_position.x < limit:
			node.queue_free()
			return false
		return true
	tiles = tiles.filter(filter_node)
	rocks = rocks.filter(filter_node)
	stalls = stalls.filter(filter_node)

func _update_floor_y() -> void:
	var vp = get_viewport_rect()
	current_floor_y = int(vp.size.y - bottom_margin)

func _get_fallback_texture(w, h, color):
	if _fallback_texture: return _fallback_texture
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	_fallback_texture = ImageTexture.create_from_image(img)
	return _fallback_texture
