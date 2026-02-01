extends Node2D

const ALLOWED_GROUNDS = [1, 10, 11, 12]
const ROCK_TYPES = [1, 2] 

@export_group("Generation Settings")
@export var tile_width: int = 0
@export var rock_spawn_chance: float = 0.05 
@export var rock_scale: float = 1.0
@export var floor_offset: int = 0 
@export var min_rock_spacing: int = 300 
@export var buffer_tiles: int = 15 
@export var start_x: int = 0

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

var left_floor_y: int = 300
var right_floor_y: int = 300
var left_ground_id: int = 1
var right_ground_id: int = 1

func _ready():
	randomize()
	_load_resources()
	_update_floor_y()
	
	# Force initialization to prevent Nil errors
	left_floor_y = current_floor_y
	right_floor_y = current_floor_y
	left_ground_id = 1
	right_ground_id = 1
	last_stall_count = 0
	
	if tile_width <= 0:
		_auto_detect_tile_width()

	_add_tile(start_x, true) 

	if use_background:
		_init_infinite_background()

func _physics_process(_delta: float) -> void:
	var player = get_node_or_null("../walking_cat_character_body_2D")
	if not player: return
	var player_x = player.global_position.x

	var rightmost_x = tiles[-1].global_position.x if tiles.size() > 0 else start_x
	while rightmost_x < player_x + (buffer_tiles * tile_width):
		rightmost_x += tile_width
		_add_tile(rightmost_x, true)
		_try_spawn_decor(rightmost_x, right_floor_y)

	var leftmost_x = tiles[0].global_position.x if tiles.size() > 0 else start_x
	while leftmost_x > player_x - (buffer_tiles * tile_width):
		leftmost_x -= tile_width
		_add_tile(leftmost_x, false) 
		_try_spawn_decor(leftmost_x, left_floor_y)

	_cleanup_distant_tiles(player_x)

func _add_tile(x_pos: int, at_end: bool) -> void:
	var ground_id: int = 1
	if at_end:
		ground_id = _get_next_ground_id(right_ground_id)
		right_ground_id = ground_id
	else:
		ground_id = _get_next_ground_id(left_ground_id)
		left_ground_id = ground_id
	
	var y_base_val = right_floor_y if at_end else left_floor_y
	if y_base_val == null: y_base_val = current_floor_y
	
	var body = StaticBody2D.new()
	body.position = Vector2(x_pos, y_base_val + floor_offset)
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

	if at_end:
		tiles.append(body)
		if right_floor_y == null: right_floor_y = current_floor_y
		right_floor_y += _get_floor_y_adjustment(ground_id)
	else:
		tiles.push_front(body)
		if left_floor_y == null: left_floor_y = current_floor_y
		left_floor_y -= _get_floor_y_adjustment(ground_id)

func _try_spawn_decor(x_pos: int, y_base: int) -> void:
	if y_base == null: y_base = current_floor_y
	if randf() < rock_spawn_chance:
		_spawn_rock(x_pos, y_base)
	_determine_and_spawn_stall(x_pos, y_base)

func _spawn_rock(x_pos: int, y_base: int) -> void:
	if abs(x_pos - last_rock_x) < min_rock_spacing: return
	var rock_id = ROCK_TYPES.pick_random()
	var rock_tex = rock_textures.get(rock_id)
	if not rock_tex: return
	
	# Fix: Adjust rock to sit on top of the floor
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
	sprite.position = Vector2(-tex_w / 2.0, -tex_h / 2)
	body.add_child(sprite)
	rocks.append(body)
	last_rock_x = x_pos

func _determine_and_spawn_stall(x_pos: int, y_base: int) -> void:
	if not stall_texture:
		last_stall_count = 0
		return
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
	
	# Fix: Get floor height and subtract it so stall sits on the surface
	var floor_h = 64
	if textures.has(1):
		floor_h = textures[1].get_height()
	
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

func _cleanup_distant_tiles(player_x: float) -> void:
	var limit = buffer_tiles * tile_width * 2.5
	var filter_node = func(node):
		if is_instance_valid(node) and abs(node.global_position.x - player_x) > limit:
			node.queue_free()
			return false
		return true
	tiles = tiles.filter(filter_node)
	rocks = rocks.filter(filter_node)
	stalls = stalls.filter(filter_node)

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
