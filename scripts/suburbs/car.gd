extends Node2D

@export var speed: float = 600.0
var direction: int = 1 

@onready var despawn_timer = $DespawnTimer
@onready var sprite = $Area2D/AnimatedSprite2D

func _ready():
	sprite.play("drive")
	sprite.flip_h = (direction == -1)

	var notifier = $VisibleOnScreenNotifier2D
	notifier.screen_exited.connect(_on_screen_exited)
	notifier.screen_entered.connect(_on_screen_entered)

func _process(delta):
	position.x += speed * direction * delta

func _on_screen_exited():
	despawn_timer.start()

func _on_screen_entered():
	despawn_timer.stop()

func _on_despawn_timer_timeout():
	queue_free()

func _on_area_2d_body_entered(body):
	if body.name.contains("cat"):
		print("Heroic collision!")
		queue_free()
