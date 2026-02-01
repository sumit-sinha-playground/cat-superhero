extends Node2D

# Only use these ground assets
const ALLOWED_GROUNDS = [1, 10, 11, 12]

@export var tile_width: int = 0
@export var floor_y: int = 300
@export var buffer_tiles: int = 8
@export var start_x: int = -512

var textures = {}  # dict: ground_id -> Texture2D
var tiles = []
var last_ground_id = 1  # Start with Ground_01
@export var elevation_change: int = 128  # pixels to move up/down per incline/decline

var current_floor_y: int = 300  # Track dynamic floor height

func _ready():
	randomize()
	
	# Load only allowed ground textures
	for id in ALLOWED_GROUNDS:
		var path = "res://assets/village/Ground_%02d.png" % id
		if ResourceLoader.exists(path):
			textures[id] = load(path)
	
	# if tile_width not set, try to infer from first available texture
	if tile_width <= 0:
		for id in ALLOWED_GROUNDS:
			if id in textures and textures[id]:
				tile_width = int(textures[id].get_width())
				break

	# create initial strip of tiles
	var x = start_x
	for i in range(buffer_tiles * 2):
		_add_tile(x)
		x += tile_width
	
	# create left boundary wall
	_create_left_boundary()

func _get_floor_y_adjustment(ground_id: int) -> int:
	"""Return floor_y adjustment after placing a ground tile."""
	match ground_id:
		1:  # Ground_01 (inclination) - move up
			return -elevation_change
		_:
			return 0
func _create_left_boundary() -> void:
	"""Create a vertical collision wall on the left side to prevent falling off."""
	var wall = StaticBody2D.new()
	wall.position = Vector2(start_x - 100, floor_y)
	add_child(wall)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 2000)  # Tall vertical wall
	collision.shape = shape
	collision.position = Vector2(0, 0)
	wall.add_child(collision)


func _get_next_ground_id(current_id: int) -> int:
	"""Return the next ground ID based on progression rules."""
	match current_id:
		1:  # Ground_01 (inclination)
			return [1, 10].pick_random()
		10: # Ground_10 (forced sequence start)
			return 11
		11: # Ground_11
			return [11, 12].pick_random()
		12: # Ground_12
			return 11
		_:
			return 1  # Default to Ground_01

func _get_collision_offset(ground_id: int) -> float:
	"""Return vertical collision offset based on ground type."""
	match ground_id:
		1:  # Inclination - move collision up
			return -10.0
		_:
			return 0.0

func _add_tile(x_pos: int) -> Node2D:
	var ground_id = _get_next_ground_id(last_ground_id)
	last_ground_id = ground_id
	
	var body = StaticBody2D.new()
	body.position = Vector2(x_pos, floor_y)
	body.position.y = current_floor_y
	add_child(body)

	var s = Sprite2D.new()
	var tex: Texture2D = null
	
	if ground_id in textures and textures[ground_id]:
		tex = textures[ground_id]
	
	if tex:
		s.texture = tex
	else:
		# fallback: use a colored rectangle
		var ci = ColorRect.new()
		ci.color = Color(0.25, 0.12, 0.05)
		ci.rect_size = Vector2(tile_width, tile_width)
		ci.position = Vector2(0, -tile_width/2)
		body.add_child(ci)
		tiles.append(body)
		# Update floor_y after placing tile
		current_floor_y += _get_floor_y_adjustment(ground_id)
		return body

	var tex_w = tex.get_width() if tex else tile_width
	var tex_h = tex.get_height() if tex else tile_width
	s.position = Vector2(0, -tex_h/2)
	body.add_child(s)

	# add collision shape with offset for inclination/declination
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(tex_w, tex_h)
	collision.shape = shape
	var collision_offset = _get_collision_offset(ground_id)
	collision.position = Vector2(0, -tex_h/2 + collision_offset)
	body.add_child(collision)

	tiles.append(body)
	# Update floor_y after placing tile
	current_floor_y += _get_floor_y_adjustment(ground_id)
	return body

func _physics_process(delta: float) -> void:
	var player = get_node_or_null("../walking_cat_character_body_2D")
	if not player:
		return

	var player_x = player.global_position.x

	# spawn ahead
	var rightmost = -INF
	for t in tiles:
		rightmost = max(rightmost, t.global_position.x)

	while rightmost < player_x + buffer_tiles * tile_width:
		rightmost += tile_width
		_add_tile(rightmost)

	# remove behind
	var new_tiles = []
	for t in tiles:
		if t.global_position.x < player_x - buffer_tiles * tile_width:
			t.queue_free()
		else:
			new_tiles.append(t)
	tiles = new_tiles
