extends Area2D
signal game_over

export(Vector2) var speed_range = Vector2() # x = min; y = max
export(int) var speed = 0

func _ready():
	var rng = RandomNumberGenerator.new()
	speed = rng.randi_range(speed_range.x, speed_range.y)

func _physics_process(delta):
	if get_rotation_degrees() == 360:
		 set_rotation_degrees(0)
	match get_rotation_degrees():
		0.0:
			position.x += speed * delta
		180.0:
			position.x -= speed * delta
			

func _on_Obstacle_area_entered(area):
	if area.is_in_group("obstacle"):
		area.queue_free()

func _on_Obstacle_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("game_over")
